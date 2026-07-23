import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/data/nom310_ampacidad_data.dart';
import 'package:nom_electrica_mx/utils/circuit_sizer.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kAccent = Color(0xFF7C3AED); // Violeta — identidad del dimensionador
const _kOk = Color(0xFF00FF88);
const _kError = Color(0xFFFF5252);
const _kFormula = Color(0xFF818CF8);

/// Dimensionador inverso de circuitos según NOM-001-SEDE-2012: dado el uso
/// real (corriente, largo, condiciones de instalación), entrega el calibre
/// mínimo de cobre (AWG/kcmil) que cumple SIMULTÁNEAMENTE la ampacidad
/// corregida de la Tabla 310-15(b)(16) y el límite de caída de tensión
/// (3% circuito derivado / 5% total — notas Arts. 210-19 y 215-2).
class DimensionadorCircuitoScreen extends StatefulWidget {
  const DimensionadorCircuitoScreen({super.key});

  @override
  State<DimensionadorCircuitoScreen> createState() => _DimensionadorCircuitoScreenState();
}

class _DimensionadorCircuitoScreenState extends State<DimensionadorCircuitoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Entradas
  final _corrienteCtrl = TextEditingController();
  final _largoCtrl = TextEditingController();
  final _cosPhiCtrl = TextEditingController(text: '0.9');
  final _agrupamientoCtrl = TextEditingController(text: '3');
  bool _esTrifasico = false;
  String _aislamiento = '75';
  bool _esCircuitoDerivado = true; // true = 3%, false = alimentador/total 5%
  double _tempAmbiente = 30.0;

  // Resultados
  String? _calibreRecomendado;
  double? _areaMm2;
  String? _minPorAmpacidad;
  String? _minPorCaida;
  double? _iAdmisibleFinal;
  double? _caidaPct;
  String? _criterioDominante;
  bool _sinSolucion = false;

  double get _limiteCaida => _esCircuitoDerivado ? 3.0 : 5.0;

  String? _numericValidator(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Número inválido';
    if (n <= 0) return 'Debe ser > 0';
    return null;
  }

  @override
  void dispose() {
    _corrienteCtrl.dispose();
    _largoCtrl.dispose();
    _cosPhiCtrl.dispose();
    _agrupamientoCtrl.dispose();
    super.dispose();
  }

  void _resetResultado() {
    _calibreRecomendado = null;
    _sinSolucion = false;
  }

  void _calcular() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    try {
      final double corriente = double.parse(_corrienteCtrl.text.replaceAll(',', '.'));
      final double largo = double.parse(_largoCtrl.text.replaceAll(',', '.'));
      final double cosPhi = _esTrifasico ? double.parse(_cosPhiCtrl.text.replaceAll(',', '.')) : 1.0;
      final int agrupados = int.tryParse(_agrupamientoCtrl.text) ?? 3;

      final CircuitSizerResult resultado = CircuitSizer.calcular(
        corriente: corriente,
        largo: largo,
        cosPhi: cosPhi,
        esTrifasico: _esTrifasico,
        aislamiento: _aislamiento,
        temperaturaAmbiente: _tempAmbiente,
        conductoresAgrupados: agrupados,
        limiteCaidaPct: _limiteCaida,
      );

      setState(() {
        _calibreRecomendado = resultado.calibreRecomendado;
        _areaMm2 = resultado.areaMm2;
        _minPorAmpacidad = resultado.minPorAmpacidad;
        _minPorCaida = resultado.minPorCaida;
        _iAdmisibleFinal = resultado.iAdmisibleFinal;
        _caidaPct = resultado.caidaPct;
        _criterioDominante = resultado.criterioDominante;
        _sinSolucion = resultado.sinSolucion;
      });

      AdService.instance.showInterstitial(context);
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message.toString()),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Entrada inválida: revisa los valores ingresados. ($e)'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _limpiar() {
    setState(() {
      _corrienteCtrl.clear();
      _largoCtrl.clear();
      _cosPhiCtrl.text = '0.9';
      _agrupamientoCtrl.text = '3';
      _esTrifasico = false;
      _aislamiento = '75';
      _esCircuitoDerivado = true;
      _tempAmbiente = 30.0;
      _calibreRecomendado = null;
      _areaMm2 = null;
      _minPorAmpacidad = null;
      _minPorCaida = null;
      _iAdmisibleFinal = null;
      _caidaPct = null;
      _criterioDominante = null;
      _sinSolucion = false;
    });
  }

  bool get _hayResultado => _calibreRecomendado != null || _sinSolucion;

  String get _sistemaTxt => _esTrifasico
      ? 'Trifásico 220V (cos φ ${_cosPhiCtrl.text})'
      : 'Monofásico 127V';

  String get _tipoCircuitoTxt => _esCircuitoDerivado
      ? 'Circuito derivado (límite 3%)'
      : 'Alimentador / total (límite 5%)';

  void _compartir() {
    if (!_hayResultado) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final String resultado = _sinSolucion
        ? '➤ ❌ Ningún calibre ≤ 500 kcmil cumple ambos criterios.\n   Subdividir el circuito o replantear el alimentador.'
        : '''➤ *Calibre recomendado: $_calibreRecomendado (Cu, ${_areaMm2!.toStringAsFixed(1)} mm²)*
   ➤ Ampacidad corregida: ${_iAdmisibleFinal!.toStringAsFixed(1)} A
   ➤ Caída de tensión: ${_caidaPct!.toStringAsFixed(2)} % (límite ${_limiteCaida.toStringAsFixed(0)}%)
   ➤ Criterio dominante: $_criterioDominante''';
    final reporte = '''
📌 *DIMENSIONADO DE CIRCUITO — NOM Eléctrica MX*
——————————————————————————————
📅 *Fecha:* $fecha

📥 *DATOS:*
   • Corriente de diseño: ${_corrienteCtrl.text} A
   • Largo del tramo: ${_largoCtrl.text} m
   • Sistema: $_sistemaTxt
   • Tipo: $_tipoCircuitoTxt
   • Aislamiento: ${Nom310AmpacidadData.aislamientosDesc[_aislamiento]}
   • Tª ambiente: ${_tempAmbiente.toInt()}°C · Portadores agrupados: ${_agrupamientoCtrl.text}

📊 *RESULTADO:*
   $resultado

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE-2012, Tabla 310-15(b)(16) + Arts. 210-19 / 215-2
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (!_hayResultado) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Dimensionado de Circuito NOM-001-SEDE (Ampacidad + Caída de Tensión)',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Corriente de diseño', '${_corrienteCtrl.text} A'],
          ['Largo del tramo', '${_largoCtrl.text} m'],
          ['Sistema', _sistemaTxt],
          ['Tipo de circuito', _tipoCircuitoTxt],
          ['Aislamiento', Nom310AmpacidadData.aislamientosDesc[_aislamiento] ?? _aislamiento],
          ['Temperatura ambiente', '${_tempAmbiente.toInt()}°C'],
          ['Conductores portadores agrupados', _agrupamientoCtrl.text],
        ],
        resultados: _sinSolucion
            ? [
                ['Indicador', 'Valor Obtenido'],
                ['Calibre recomendado', 'Sin solución ≤ 500 kcmil'],
                ['Acción sugerida', 'Subdividir circuito o replantear alimentador'],
              ]
            : [
                ['Indicador', 'Valor Obtenido'],
                ['Calibre recomendado (Cu)', '$_calibreRecomendado (${_areaMm2!.toStringAsFixed(1)} mm²)'],
                ['Ampacidad corregida', '${_iAdmisibleFinal!.toStringAsFixed(1)} A'],
                ['Caída de tensión', '${_caidaPct!.toStringAsFixed(2)} % (límite ${_limiteCaida.toStringAsFixed(0)}%)'],
                ['Mínimo por ampacidad', _minPorAmpacidad ?? '—'],
                ['Mínimo por caída de tensión', _minPorCaida ?? '—'],
                ['Criterio dominante', _criterioDominante ?? '—'],
              ],
        formula: 'Calibre = max(min_ampacidad, min_caida) — Tabla 310-15(b)(16)',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(children: [
          const Icon(Icons.design_services_rounded, color: _kAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('DIMENSIONADOR DE CIRCUITO', style: DesignTokens.getDisplay(b, fontSize: 14), overflow: TextOverflow.ellipsis),
              Text('Calibre mínimo: Tabla 310-15(b)(16) + caída', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11), overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isPremium) ...[
              AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 80),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoBox(b),
                      const SizedBox(height: 20),
                      _sectionLabel('CARGA Y TRAMO'),
                      const SizedBox(height: 12),
                      Row(children: [
                        _modeButton('MONOFÁSICO 127V', !_esTrifasico, () => setState(() { _esTrifasico = false; _resetResultado(); }), b),
                        const SizedBox(width: 12),
                        _modeButton('TRIFÁSICO 220V', _esTrifasico, () => setState(() { _esTrifasico = true; _resetResultado(); }), b),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _textField(_corrienteCtrl, 'Corriente de diseño', 'Ej: 20', 'A', Icons.electric_bolt_rounded, b)),
                        const SizedBox(width: 12),
                        Expanded(child: _textField(_largoCtrl, 'Largo del tramo', 'Ej: 35', 'm', Icons.straighten_rounded, b)),
                      ]),
                      if (_esTrifasico) ...[
                        const SizedBox(height: 12),
                        _textField(_cosPhiCtrl, 'Factor de potencia (cos φ)', 'Ej: 0.9', 'f.p', Icons.timeline_rounded, b,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              final n = double.tryParse(v.replaceAll(',', '.'));
                              if (n == null) return 'Número inválido';
                              if (n <= 0 || n > 1) return 'Rango: 0 < cos φ ≤ 1';
                              return null;
                            }),
                      ],
                      const SizedBox(height: 20),
                      _sectionLabel('CONDICIONES DE INSTALACIÓN'),
                      const SizedBox(height: 12),
                      Row(children: [
                        _modeButton('DERIVADO (3%)', _esCircuitoDerivado, () => setState(() { _esCircuitoDerivado = true; _resetResultado(); }), b),
                        const SizedBox(width: 12),
                        _modeButton('ALIMENTADOR (5%)', !_esCircuitoDerivado, () => setState(() { _esCircuitoDerivado = false; _resetResultado(); }), b),
                      ]),
                      const SizedBox(height: 12),
                      _dropdown('Aislamiento del Conductor', _aislamiento,
                          Nom310AmpacidadData.aislamientosDesc.keys.toList(),
                          (v) => setState(() { _aislamiento = v!; _resetResultado(); }), b,
                          customItemLabels: Nom310AmpacidadData.aislamientosDesc),
                      const SizedBox(height: 12),
                      Text('Temperatura Ambiente: ${_tempAmbiente.toInt()}°C', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
                      Slider(
                        value: _tempAmbiente,
                        min: 30,
                        max: 60,
                        divisions: 6,
                        activeColor: _kAccent,
                        inactiveColor: DesignTokens.getBackground(b),
                        onChanged: (v) => setState(() { _tempAmbiente = v; _resetResultado(); }),
                      ),
                      const SizedBox(height: 4),
                      _textField(_agrupamientoCtrl, 'Conductores portadores en la tubería', 'Ej: 3', 'un', Icons.group_work_rounded, b,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Requerido';
                            final n = int.tryParse(v);
                            if (n == null || n <= 0) return 'Debe ser > 0';
                            return null;
                          }),
                      const SizedBox(height: 24),
                      CalculatorButtonsPanel(
                        onCalculate: _calcular,
                        onReset: _limpiar,
                        onShare: _hayResultado ? _compartir : null,
                        onExportPdf: _hayResultado ? _exportarPDF : null,
                        showResults: _hayResultado,
                        mainColor: _kAccent,
                        calculateLabel: 'DIMENSIONAR CALIBRE',
                      ),
                      const SizedBox(height: 24),
                      if (_hayResultado) _buildResultado(b),
                      if (_calibreRecomendado != null) ...[
                        const SizedBox(height: 24),
                        _buildFormulaCard(b),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoBox(Brightness b) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kAccent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kAccent.withAlpha(50))),
        child: Row(children: [
          const Icon(Icons.auto_fix_high_rounded, color: _kAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ingresa la carga y las condiciones reales: la app recorre los calibres comerciales de cobre (AWG/kcmil) y recomienda el mínimo que cumple la ampacidad de la Tabla 310-15(b)(16) corregida y la caída de tensión a la vez.',
              style: TextStyle(fontSize: 11, color: DesignTokens.getTextPrimary(b).withAlpha(200), height: 1.4),
            ),
          ),
        ]),
      );

  Widget _sectionLabel(String label) => Row(children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: _kAccent)),
      ]);

  Widget _modeButton(String txt, bool sel, VoidCallback tap, Brightness b) => Expanded(
        child: GestureDetector(
          onTap: tap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: sel ? _kAccent : DesignTokens.getCardBackground(b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? _kAccent : DesignTokens.getBorderColor(b)),
            ),
            child: Center(child: Text(txt, style: TextStyle(color: sel ? Colors.white : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 11))),
          ),
        ),
      );

  Widget _textField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? Function(String?)? validator}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: _kAccent, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hint,
              hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14),
              suffixText: unit,
              suffixStyle: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 13),
              border: InputBorder.none,
            ),
            validator: validator ?? _numericValidator,
          ),
        ]),
      );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Brightness b, {Map<String, String>? customItemLabels}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(12), border: Border.all(color: DesignTokens.getBorderColor(b))),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: DesignTokens.getSurface(b),
                items: items.map((e) {
                  final displayText = customItemLabels != null ? customItemLabels[e]! : e;
                  return DropdownMenuItem(
                    value: e,
                    child: Text(displayText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: DesignTokens.getTextPrimary(b)), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      );

  Widget _buildResultado(Brightness b) {
    if (_sinSolucion) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _kError.withAlpha(15), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kError.withAlpha(100), width: 1.5)),
        child: Column(children: [
          const Icon(Icons.warning_rounded, color: _kError, size: 40),
          const SizedBox(height: 12),
          const Text('SIN SOLUCIÓN ≤ 500 kcmil', style: TextStyle(color: _kError, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(
            'Ningún calibre comercial hasta 500 kcmil cumple ambos criterios con estas condiciones. Considera subdividir el circuito, reducir el largo del tramo, usar conductores en paralelo o replantear el alimentador.',
            textAlign: TextAlign.center,
            style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12, height: 1.4),
          ),
        ]),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: _kOk.withAlpha(12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kOk.withAlpha(120), width: 1.5)),
      child: Column(children: [
        Text('CALIBRE MÍNIMO RECOMENDADO (Cu)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        FittedBox(child: Text(_calibreRecomendado!, style: GoogleFonts.outfit(fontSize: 44, fontWeight: FontWeight.w900, color: _kAccent, height: 1))),
        const SizedBox(height: 6),
        Text('(${_areaMm2!.toStringAsFixed(1)} mm²)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: _kAccent.withAlpha(25), borderRadius: BorderRadius.circular(20)),
          child: Text('Criterio dominante: $_criterioDominante', style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 20),
        _resultRow('Ampacidad corregida', '${_iAdmisibleFinal!.toStringAsFixed(1)} A ≥ ${_corrienteCtrl.text} A', b),
        _resultRow('Caída de tensión', '${_caidaPct!.toStringAsFixed(2)} % ≤ ${_limiteCaida.toStringAsFixed(0)}%', b),
        _resultRow('Mínimo solo por ampacidad', _minPorAmpacidad ?? '—', b),
        _resultRow('Mínimo solo por caída', _minPorCaida ?? '—', b),
      ]),
    );
  }

  Widget _resultRow(String label, String val, Brightness b) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13)),
          Text(val, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 13)),
        ]),
      );

  Widget _buildFormulaCard(Brightness b) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: _kFormula.withAlpha(60))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.functions_rounded, color: _kFormula, size: 18),
            const SizedBox(width: 8),
            const Text('CRITERIO DE DIMENSIONADO', style: TextStyle(color: _kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: _kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: const Text('NOM-001-SEDE', style: TextStyle(color: _kFormula, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 16),
          Center(child: FittedBox(child: Text('Calibre = max(min_ampacidad, min_caída)', style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: _kFormula)))),
          const SizedBox(height: 16),
          Divider(color: DesignTokens.getBorderColor(b)),
          const SizedBox(height: 10),
          _legendRow('min_ampacidad', 'Menor AWG con I_tabla·f_t·f_agrup ≥ I diseño (Tabla 310-15(b)(16))', b),
          _legendRow('min_caída', 'Menor AWG con VP% ≤ límite (3% derivado / 5% total, Arts. 210-19 y 215-2)', b),
        ]),
      );

  Widget _legendRow(String s, String d, Brightness b) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 105, child: Text(s, style: GoogleFonts.firaCode(fontSize: 11, color: _kFormula, fontWeight: FontWeight.bold))),
          Expanded(child: Text(d, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11))),
        ]),
      );
}
