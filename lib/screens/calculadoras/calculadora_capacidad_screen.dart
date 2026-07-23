import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/data/nom310_ampacidad_data.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kElectricBlue = Color(0xFF00D1FF);

class CalculadoraCapacidadScreen extends StatefulWidget {
  const CalculadoraCapacidadScreen({super.key});

  @override
  State<CalculadoraCapacidadScreen> createState() => _CalculadoraCapacidadScreenState();
}

class _CalculadoraCapacidadScreenState extends State<CalculadoraCapacidadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores e inputs
  String _selectedAislamiento = '75'; // '60' (TW), '75' (THW), '90' (THHN)
  String _selectedCalibre = '12 AWG';
  double _temperaturaAmbiente = 30.0;
  final _agrupamientoCtrl = TextEditingController(text: '3');

  // Resultados
  double? _iBase;
  double? _fTemp;
  double? _fAgrup;
  double? _iFinal;

  // Fuente única de datos normativos: lib/data/nom310_ampacidad_data.dart
  // (Tabla 310-15(b)(16), compartida con el Dimensionador de Circuito)
  final List<String> _calibres =
      Nom310AmpacidadData.calibres.map((c) => c['awg'] as String).toList();

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    final int count = int.tryParse(_agrupamientoCtrl.text) ?? 1;

    // Obtener corriente base de la Tabla 310-15(b)(16)
    final double base =
        Nom310AmpacidadData.iBase[_selectedAislamiento]![_selectedCalibre]!;

    // Factores
    final double fTemp =
        Nom310AmpacidadData.factorTemperatura(_selectedAislamiento, _temperaturaAmbiente);
    final double fAgrup = Nom310AmpacidadData.factorAgrupamiento(count);

    // Corriente final corregida
    final double finalCurrent = base * fTemp * fAgrup;

    setState(() {
      _iBase = base;
      _fTemp = fTemp;
      _fAgrup = fAgrup;
      _iFinal = finalCurrent;
    });

    // Intersticial para no premium
    AdService.instance.showInterstitial(context);
  }

  Future<void> _exportarPDF() async {
    if (_iFinal == null) return;

    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Ampacidad Corregida — NOM-001-SEDE Tabla 310-15(b)(16)',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Aislamiento', Nom310AmpacidadData.aislamientosDesc[_selectedAislamiento] ?? _selectedAislamiento],
          ['Calibre de Conductor', _selectedCalibre],
          ['Temperatura Ambiente', '${_temperaturaAmbiente.toInt()}°C'],
          ['Conductores portadores agrupados', _agrupamientoCtrl.text],
        ],
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Corriente Base sin Corregir', '${_iBase!.toStringAsFixed(1)} A'],
          ['Factor de Temperatura (f_t)', _fTemp!.toStringAsFixed(2)],
          ['Factor de Agrupamiento (f_g)', _fAgrup!.toStringAsFixed(2)],
          ['Corriente Final Corregida', '${_iFinal!.toStringAsFixed(1)} A'],
        ],
        formula: 'I_final = I_base · f_t · f_g',
      );
    });
  }

  void _limpiar() {
    setState(() {
      _iBase = null;
      _fTemp = null;
      _fAgrup = null;
      _iFinal = null;
      _selectedAislamiento = '75';
      _selectedCalibre = '12 AWG';
      _temperaturaAmbiente = 30.0;
      _agrupamientoCtrl.text = '3';
    });
  }

  void _compartir() {
    if (_iFinal == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
⚡ *NOM ELÉCTRICA MX*
🛠️ *Cálculo:* Ampacidad Corregida (Tabla 310-15(b)(16))
📅 *Fecha:* $fecha

📥 *DATOS INGRESADOS:*
   • Aislamiento: ${Nom310AmpacidadData.aislamientosDesc[_selectedAislamiento]}
   • Calibre: $_selectedCalibre
   • Temperatura Ambiente: ${_temperaturaAmbiente.toInt()}°C
   • Conductores portadores agrupados: ${_agrupamientoCtrl.text}

📊 *RESULTADOS:*
   ➤ Corriente Base: ${_iBase!.toStringAsFixed(1)} A
   ➤ Factor Temp (f_t): ${_fTemp!.toStringAsFixed(2)}
   ➤ Factor Agrup (f_agrup): ${_fAgrup!.toStringAsFixed(2)}
   ➤ *Corriente Final Admisible: ${_iFinal!.toStringAsFixed(1)} A*

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE-2012, Art. 310 y Tablas 310-15(b)
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final surface = DesignTokens.getSurface(b);
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: surface,
        foregroundColor: DesignTokens.getTextPrimary(b),
        elevation: 0,
        title: Text("Ampacidad NOM (Tabla 310-15)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isPremium) ...[  
              SafeArea(
                top: true,
                bottom: false,
                child: AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
              ),
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
                      const SizedBox(height: 24),
                      _buildInputCard(b),
                      const SizedBox(height: 32),
                      _buildActionButtons(b),
                      const SizedBox(height: 32),
                      if (_iFinal != null) ...[
                        _buildResults(b),
                        const SizedBox(height: 28),
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
    decoration: BoxDecoration(color: _kElectricBlue.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: _kElectricBlue.withAlpha(50))),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: _kElectricBlue, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text("La ampacidad de los conductores disminuye si la temperatura ambiente supera los 30°C o si hay varios conductores agrupados en el mismo ducto.", style: TextStyle(fontSize: 11, color: DesignTokens.getTextPrimary(b).withAlpha(200)))),
    ]),
  );

  Widget _buildInputCard(Brightness b) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(20), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _rowLabel("PARÁMETROS DE LA INSTALACIÓN"),
        const SizedBox(height: 16),
        
        // Selector de Temperatura/Aislamiento
        _dropdown("Aislamiento del Conductor", _selectedAislamiento,
            Nom310AmpacidadData.aislamientosDesc.keys.toList(), (v) {
          setState(() {
            _selectedAislamiento = v!;
            _iFinal = null;
          });
        }, b, customItemLabels: Nom310AmpacidadData.aislamientosDesc),
        const SizedBox(height: 16),

        // Selector de Calibre
        _dropdown("Calibre del Conductor (AWG / kcmil)", _selectedCalibre, _calibres, (v) {
          setState(() {
            _selectedCalibre = v!;
            _iFinal = null;
          });
        }, b),
        const SizedBox(height: 16),

        // Slider temperatura ambiente
        Text("Temperatura Ambiente: ${_temperaturaAmbiente.toInt()}°C", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
        Slider(
          value: _temperaturaAmbiente,
          min: 15.0,
          max: 80.0,
          divisions: 13,
          activeColor: _kElectricBlue,
          inactiveColor: DesignTokens.getBackground(b),
          onChanged: (val) {
            setState(() {
              _temperaturaAmbiente = val;
              _iFinal = null;
            });
          },
        ),
        const SizedBox(height: 16),

        // Input agrupamiento
        _textField(_agrupamientoCtrl, "Conductores Portadores Agrupados", "Ej: 3", Icons.group_work_rounded, b,
          help: 'Número de conductores portadores de corriente en la misma tubería conduit o canalización. Con más de 3 aplica el factor de ajuste de la Tabla 310-15(b)(3)(a) de la NOM-001-SEDE.'),
      ],
    ),
  );

  Widget _rowLabel(String label) => Row(children: [
    Container(width: 4, height: 14, decoration: BoxDecoration(color: _kElectricBlue, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: _kElectricBlue)),
  ]);

  Widget _textField(TextEditingController ctrl, String label, String hint, IconData icon, Brightness b, {String? help}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
        if (help != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showHelpDialog(context, label, help),
            child: Icon(Icons.info_outline_rounded, color: _kElectricBlue.withAlpha(150), size: 12),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: _kElectricBlue),
          hintText: hint,
          filled: true,
          fillColor: DesignTokens.getBackground(b),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Requerido";
          final n = int.tryParse(v);
          if (n == null || n <= 0) return "Debe ser > 0";
          return null;
        },
      ),
    ],
  );

  void _showHelpDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: DesignTokens.getSurface(Theme.of(context).brightness),
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _kElectricBlue),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: _kElectricBlue, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Brightness b, {Map<String, String>? customItemLabels}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: DesignTokens.getBackground(b), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value, isExpanded: true,
            dropdownColor: DesignTokens.getSurface(b),
            items: items.map((e) {
              final displayText = customItemLabels != null ? customItemLabels[e]! : e;
              return DropdownMenuItem(
                value: e, 
                child: Text(
                  displayText, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                )
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _buildActionButtons(Brightness b) => CalculatorButtonsPanel(
        onCalculate: _calcular,
        onReset: _limpiar,
        onShare: _iFinal != null ? _compartir : null,
        onExportPdf: _iFinal != null ? _exportarPDF : null,
        showResults: _iFinal != null,
        mainColor: _kElectricBlue,
        calculateLabel: 'CALCULAR AMPACIDAD FINAL',
      );

  Widget _buildResults(Brightness b) {
    final color = _iFinal! > 0 ? const Color(0xFF00FF88) : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Column(children: [
        Icon(_iFinal! > 0 ? Icons.offline_bolt_rounded : Icons.warning_rounded, color: color, size: 40),
        const SizedBox(height: 12),
        Text("CORRIENTE ADMISIBLE FINAL", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        const SizedBox(height: 16),
        Text(
          "${_iFinal!.toStringAsFixed(1)} A",
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "Ampacidad máxima permitida",
          style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11),
        ),
        if (_fTemp == 0.0) ...[
          const SizedBox(height: 10),
          const Text(
            "⚠ Fuera de rango normativo: la temperatura ambiente supera el límite del aislamiento seleccionado. Usa un conductor de mayor clase térmica.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFF5252), fontSize: 11, fontWeight: FontWeight.bold, height: 1.3),
          ),
        ],
        const SizedBox(height: 24),
        _resultRow("Corriente Base sin corregir", "${_iBase!.toStringAsFixed(1)} A", DesignTokens.getTextPrimary(b), b),
        const SizedBox(height: 8),
        _resultRow("Factor Temperatura (f_t)", _fTemp!.toStringAsFixed(2), _fTemp! < 1.0 ? Colors.orange : DesignTokens.getTextPrimary(b), b),
        const SizedBox(height: 8),
        _resultRow("Factor Agrupamiento (f_g)", _fAgrup!.toStringAsFixed(2), _fAgrup! < 1.0 ? Colors.orange : DesignTokens.getTextPrimary(b), b),
      ]),
    );
  }

  Widget _resultRow(String label, String value, Color valColor, Brightness b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13)),
      Text(value, style: TextStyle(color: valColor, fontSize: 15, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildFormulaCard(Brightness b) {
    const kFormula = Color(0xFF818CF8);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          const Text('CÁLCULO DE AMPACIDAD CORREGIDA', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM 310-15', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text('I_final = I_base · f_t · f_g', style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('I_final', 'Ampacidad corregida máxima', 'Amp', kFormula, b),
        _legendRow('I_base', 'Corriente base admisible', 'Amp', kFormula, b),
        _legendRow('f_t', 'Factor corrección por Temp', '-', kFormula, b),
        _legendRow('f_g', 'Factor corrección Agrup', '-', kFormula, b),
      ]),
    );
  }

  Widget _legendRow(String s, String d, String u, Color color, Brightness b) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 65, child: Text(s, style: GoogleFonts.firaCode(fontSize: 12, color: color, fontWeight: FontWeight.bold))),
      Expanded(child: Text(d, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12))),
      Text(u, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

