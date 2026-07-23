import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:intl/intl.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';
const _kElectric = Color(0xFF00E5FF);
const _kFormula = Color(0xFF818CF8);

enum VoltajeModo { leyOhm, potenciaCorriente, potenciaResistencia, trifasica }

class CalculadoraVoltajePage extends StatefulWidget {
  const CalculadoraVoltajePage({super.key});
  @override
  State<CalculadoraVoltajePage> createState() => _CalculadoraVoltajePageState();
}

class _CalculadoraVoltajePageState extends State<CalculadoraVoltajePage> {
  final _formKey = GlobalKey<FormState>();
  VoltajeModo _modo = VoltajeModo.leyOhm;
  final _corrienteCtrl = TextEditingController();
  final _resistenciaCtrl = TextEditingController();
  final _potenciaCtrl = TextEditingController();
  final _cosPhiCtrl = TextEditingController(text: '0.93');
  String _potenciaUnit = 'W';
  double? _resultado;

  @override
  void dispose() {
    for (var c in [_corrienteCtrl, _resistenciaCtrl, _potenciaCtrl, _cosPhiCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcular() {
    if (_formKey.currentState!.validate()) {
      final I = double.tryParse(_corrienteCtrl.text.replaceAll(',', '.')) ?? 0;
      final R = double.tryParse(_resistenciaCtrl.text.replaceAll(',', '.')) ?? 0;
      double P = double.tryParse(_potenciaCtrl.text.replaceAll(',', '.')) ?? 0;
      if (_potenciaUnit == 'kW') P *= 1000;
      if (_potenciaUnit == 'HP') P *= 745.7;
      final cosPhi = double.tryParse(_cosPhiCtrl.text.replaceAll(',', '.')) ?? 1.0;
      double res = 0;
      switch (_modo) {
        case VoltajeModo.leyOhm: res = I * R; break;
        case VoltajeModo.potenciaCorriente: res = I != 0 ? P / I : 0; break;
        case VoltajeModo.potenciaResistencia: res = math.sqrt(P * R); break;
        case VoltajeModo.trifasica:
          final div = 1.732 * cosPhi * I;
          res = div != 0 ? P / div : 0;
          break;
      }
      setState(() => _resultado = res);

      // Mostrar intersticial al calcular (solo usuarios gratuitos)
      AdService.instance.showInterstitial(context);
    }
  }

  String _formatValue(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  void _limpiar() {
    _corrienteCtrl.clear(); _resistenciaCtrl.clear();
    _potenciaCtrl.clear(); _cosPhiCtrl.text = '0.93';
    setState(() => _resultado = null);
  }

  void _compartir() {
    if (_resultado == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final modosNombre = {
      VoltajeModo.leyOhm: 'Ley de Ohm (V = I × R)',
      VoltajeModo.potenciaCorriente: 'Potencia/Corriente (V = P / I)',
      VoltajeModo.potenciaResistencia: 'Potencia/Resistencia (V = √(P×R))',
      VoltajeModo.trifasica: 'Trifásica (V = P / (√3 × cos φ × I))',
    };
    SharePlus.instance.share(ShareParams(text: '📌 *REPORTE ELÉCTRICO — NOM Eléctrica MX*\n'
        '🛠️ Cálculo de Tensión — ${modosNombre[_modo]}\n📅 $fecha\n\n'
        '➔ *V = ${_formatValue(_resultado!)} V*\n\n'
        'Referencia: Ley de Ohm / NOM-001-SEDE\n_NOM Eléctrica MX_'));
  }

  Future<void> _exportarPDF() async {
    if (_resultado == null) return;
    
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      final modosNombre = {
        VoltajeModo.leyOhm: 'Ley de Ohm (V = I × R)',
        VoltajeModo.potenciaCorriente: 'Potencia/Corriente (V = P / I)',
        VoltajeModo.potenciaResistencia: 'Potencia/Resistencia (V = √(P×R))',
        VoltajeModo.trifasica: 'Trifásica (V = P / (√3 × cos φ × I))',
      };

      List<List<String>> datos = [['Parámetro', 'Valor']];
      if (_corrienteCtrl.text.isNotEmpty) datos.add(['Corriente (I)', '${_corrienteCtrl.text} A']);
      if (_resistenciaCtrl.text.isNotEmpty) datos.add(['Resistencia (R)', '${_resistenciaCtrl.text} Ohm']);
      if (_potenciaCtrl.text.isNotEmpty) datos.add(['Potencia (P)', '${_potenciaCtrl.text} W']);
      if (_cosPhiCtrl.text.isNotEmpty && _modo == VoltajeModo.trifasica) datos.add(['Factor Potencia', _cosPhiCtrl.text]);
      datos.add(['Modo de Cálculo', modosNombre[_modo]!]);

      await PdfGenerator.generateGenericReport(
        titulo: 'Cálculo de Tensión (V)',
        datosEntrada: datos,
        resultados: [['Indicador', 'Valor Obtenido'], ['Tensión Resultante', '${_formatValue(_resultado!)} V']],
        formula: _formulaActual,
      );
    });
  }

  String get _formulaActual {
    switch (_modo) {
      case VoltajeModo.leyOhm: return 'V = I · R';
      case VoltajeModo.potenciaCorriente: return 'V = P / I';
      case VoltajeModo.potenciaResistencia: return 'V = √(P · R)';
      case VoltajeModo.trifasica: return 'V = P / (√3 · cos φ · I)';
    }
  }

  String get _descripcionActual {
    switch (_modo) {
      case VoltajeModo.leyOhm: return 'Ley de Ohm clásica';
      case VoltajeModo.potenciaCorriente: return 'Voltaje por Potencia y Corriente';
      case VoltajeModo.potenciaResistencia: return 'Voltaje por Potencia y Resistencia';
      case VoltajeModo.trifasica: return 'Voltaje de Línea Trifásico';
    }
  }

  Widget _sectionLabel(Brightness b, IconData icon, String txt) => Row(children: [
        Icon(icon, color: _kElectric, size: 16), const SizedBox(width: 8),
        Text(txt, style: const TextStyle(color: _kElectric, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ]);

  Widget _inputField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? help}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _kElectric, size: 14), 
          const SizedBox(width: 6), 
          Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
          if (help != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => _showHelpDialog(context, label, help),
              child: Icon(Icons.info_outline_rounded, color: _kElectric.withAlpha(150), size: 14),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14), suffixText: unit, suffixStyle: const TextStyle(color: _kElectric, fontWeight: FontWeight.bold, fontSize: 13), border: InputBorder.none),
          validator: (v) { if (v == null || v.isEmpty) return 'Requerido'; if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido'; return null; },
        ),
      ]),
    );
  }

  void _showHelpDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: DesignTokens.getSurface(Theme.of(context).brightness),
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _kElectric),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: _kElectric, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _powerInputField(TextEditingController ctrl, String label, String hint, IconData icon, Brightness b, {String? help}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: _kElectric, size: 14), 
          const SizedBox(width: 6), 
          Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
          if (help != null) ...[
            const Spacer(),
            GestureDetector(
              onTap: () => _showHelpDialog(context, label, help),
              child: Icon(Icons.info_outline_rounded, color: _kElectric.withAlpha(150), size: 14),
            ),
          ],
        ]),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: ctrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
                decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14), border: InputBorder.none),
                validator: (v) { if (v == null || v.isEmpty) return 'Requerido'; if (double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido'; return null; },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: _kElectric.withAlpha(25), borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _potenciaUnit,
                  isDense: true,
                  dropdownColor: DesignTokens.getSurface(b),
                  icon: const Icon(Icons.arrow_drop_down, color: _kElectric, size: 20),
                  items: ['W', 'kW', 'HP'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: _kElectric, fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
                  onChanged: (v) { if (v != null) setState(() { _potenciaUnit = v; _resultado = null; }); },
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  List<Widget> _buildInputs(Brightness b) {
    final inputs = <Widget>[];
    if (_modo == VoltajeModo.leyOhm || _modo == VoltajeModo.potenciaCorriente || _modo == VoltajeModo.trifasica) {
      inputs.add(_inputField(_corrienteCtrl, 'Corriente (I)', 'Ej: 15', 'A', Icons.electric_bolt_rounded, b, 
        help: 'Cantidad de electrones que fluyen por segundo. Se mide en Amperes.'));
    }
    if (_modo == VoltajeModo.leyOhm || _modo == VoltajeModo.potenciaResistencia) {
      inputs.add(_inputField(_resistenciaCtrl, 'Resistencia (R)', 'Ej: 10', 'Ω', Icons.straighten_rounded, b, 
        help: 'Oposición que presenta un material al paso de la corriente eléctrica.'));
    }
    if (_modo != VoltajeModo.leyOhm) {
      inputs.add(_powerInputField(_potenciaCtrl, 'Potencia (P)', 'Ej: 1000', Icons.bolt_rounded, b, 
        help: 'Trabajo eléctrico realizado por unidad de tiempo. Se mide en Watts (W).'));
    }
    if (_modo == VoltajeModo.trifasica) {
      inputs.add(_inputField(_cosPhiCtrl, 'Factor de Potencia (cos φ)', 'Ej: 0.93', 'f.p', Icons.multiline_chart_rounded, b, 
        help: 'Eficiencia de la carga. Un valor de 1.0 es ideal, motores suelen tener 0.8 a 0.9.'));
    }
    return inputs;
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final inputs = _buildInputs(b);
    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b), elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(children: [
          const Icon(Icons.bolt_rounded, color: _kElectric, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CÁLCULO DE TENSIÓN', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Voltaje (V) según fórmula seleccionada', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          if (!isPremium) ...[  
            SafeArea(
              top: true,
              bottom: false,
              child: AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
            ),
          ],
          Expanded(
            child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DesignTokens.getSurface(b), DesignTokens.getBackground(b)])),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Selector de modo
              _sectionLabel(b, Icons.tune_rounded, 'MODO DE CÁLCULO'),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: VoltajeModo.values.map((m) {
                  final labels = {VoltajeModo.leyOhm: 'I × R', VoltajeModo.potenciaCorriente: 'P / I', VoltajeModo.potenciaResistencia: '√(P×R)', VoltajeModo.trifasica: 'Trifásica'};
                  final sel = _modo == m;
                  return GestureDetector(
                    onTap: () => setState(() { _modo = m; _resultado = null; }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: sel ? _kElectric : DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? _kElectric : DesignTokens.getBorderColor(b))),
                      child: Text(labels[m]!, style: TextStyle(color: sel ? Colors.black : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  );
                }).toList()),
              ),
              const SizedBox(height: 20),
              // Inputs
              _sectionLabel(b, Icons.input_rounded, 'DATOS DE ENTRADA'),
              const SizedBox(height: 12),
              for (int i = 0; i < inputs.length; i += 2) ...[
                Row(children: [
                  Expanded(child: inputs[i]),
                  if (i + 1 < inputs.length) ...[const SizedBox(width: 12), Expanded(child: inputs[i + 1])]
                  else const Expanded(child: SizedBox()),
                ]),
                if (i + 2 < inputs.length) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              // Botones
              CalculatorButtonsPanel(
                onCalculate: _calcular,
                onReset: _limpiar,
                onShare: _resultado != null ? _compartir : null,
                onExportPdf: _resultado != null ? _exportarPDF : null,
                showResults: _resultado != null,
                mainColor: _kElectric,
                calculateLabel: 'CALCULADORA',
              ),
              const SizedBox(height: 20),
              // Resultado
              if (_resultado == null)
                Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24), decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: DesignTokens.getBorderColor(b))),
                  child: Column(children: [Icon(Icons.bolt_rounded, color: DesignTokens.getTextSecondary(b).withAlpha(80), size: 32), const SizedBox(height: 8), Text('Ingresa los datos y presiona CALCULADORA', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13, fontStyle: FontStyle.italic))]))
              else
                Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: _kElectric.withAlpha(12), borderRadius: BorderRadius.circular(20), border: Border.all(color: _kElectric.withAlpha(120), width: 1.5), boxShadow: [BoxShadow(color: _kElectric.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.bolt_rounded, color: _kElectric, size: 16), const SizedBox(width: 6), Text('TENSIÓN RESULTANTE (V)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))]),
                    const SizedBox(height: 16),
                    Text('${_formatValue(_resultado!)} V', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: _kElectric, height: 1)),
                    const SizedBox(height: 12),
                  ]),
                ),
              const SizedBox(height: 28),
              // Fórmula (integrada en la misma pantalla)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: _kFormula.withAlpha(60))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.functions_rounded, color: _kFormula, size: 18), const SizedBox(width: 8),
                    const Text('FÓRMULA ACTIVA', style: TextStyle(color: _kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const Spacer(),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM-001-SEDE', style: TextStyle(color: _kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 8),
                  Text(_descripcionActual, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12)),
                  const SizedBox(height: 12),
                  Center(child: Text(_formulaActual, style: GoogleFonts.firaCode(fontSize: 22, fontWeight: FontWeight.bold, color: _kFormula))),
                ]),
              ),
              const SizedBox(height: 32),
              ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


