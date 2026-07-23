import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';
const _kElectric = Color(0xFF00E5FF);

class CalculadoraMotoresScreen extends StatefulWidget {
  const CalculadoraMotoresScreen({super.key});

  @override
  State<CalculadoraMotoresScreen> createState() => _CalculadoraMotoresScreenState();
}

class _CalculadoraMotoresScreenState extends State<CalculadoraMotoresScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _potenciaCtrl = TextEditingController(text: '5');
  final _voltajeCtrl = TextEditingController(text: '220');
  final _rendimientoCtrl = TextEditingController(text: '0.85');
  final _cosPhiCtrl = TextEditingController(text: '0.82');

  // Estados
  String _potenciaUnit = 'HP';
  bool _esTrifasico = true;
  
  double? _in; // Corriente Nominal
  double? _ip; // Corriente Partida (est)
  double? _breaker; // Disyuntor sug.
  double? _termico; // Relé térmico sug.

  @override
  void dispose() {
    _potenciaCtrl.dispose();
    _voltajeCtrl.dispose();
    _rendimientoCtrl.dispose();
    _cosPhiCtrl.dispose();
    super.dispose();
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    double P = double.parse(_potenciaCtrl.text.replaceAll(',', '.'));
    if (_potenciaUnit == 'HP') P *= 745.7;
    if (_potenciaUnit == 'kW') P *= 1000;

    final double V = double.parse(_voltajeCtrl.text.replaceAll(',', '.'));
    final double eta = double.parse(_rendimientoCtrl.text.replaceAll(',', '.'));
    final double cosPhi = double.parse(_cosPhiCtrl.text.replaceAll(',', '.'));

    double current;
    if (_esTrifasico) {
      // I = P / (V * sqrt(3) * cosPhi * eta)
      current = P / (V * sqrt(3) * cosPhi * eta);
    } else {
      // I = P / (V * cosPhi * eta)
      current = P / (V * cosPhi * eta);
    }

    setState(() {
      _in = current;
      _ip = current * 6.5; // Estimación estándar 6-7 veces In
      _breaker = current * 2.0; // Recomendación general disyuntor curva D
      _termico = current * 1.15; // Factor de servicio estándar para térmico
    });

    // Mostrar intersticial al calcular (solo usuarios gratuitos)
    AdService.instance.showInterstitial(context);
  }

  void _limpiar() {
    setState(() {
      _potenciaCtrl.text = '5';
      _voltajeCtrl.text = '220';
      _rendimientoCtrl.text = '0.85';
      _cosPhiCtrl.text = '0.82';
      _esTrifasico = true;
      _potenciaUnit = 'HP';
      _in = null;
      _ip = null;
      _breaker = null;
      _termico = null;
    });
  }

  void _compartir() {
    if (_in == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
📌 *REPORTE DE MOTOR — NOM Eléctrica MX*
——————————————————————————————
🛠️ *Tipo:* ${_esTrifasico ? 'Trifásico (3Φ)' : 'Monofásico (1Φ)'}
📅 *Fecha:* $fecha

📥 *DATOS:*
   • Potencia: ${_potenciaCtrl.text} $_potenciaUnit
   • Voltaje: ${_voltajeCtrl.text} V
   • Rendimiento (η): ${_rendimientoCtrl.text}
   • Factor Potencia (cos φ): ${_cosPhiCtrl.text}

📊 *RESULTADOS:*
   ➤ *Corriente Nominal (In): ${_in!.toStringAsFixed(2)} A*
   ➤ Partida Estimada (Ip): ${_ip!.toStringAsFixed(1)} A
   ➤ Disyuntor Sugerido: ${_breaker!.toStringAsFixed(1)} A
   ➤ Relé Térmico Sugerido: ${_termico!.toStringAsFixed(1)} A

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE — Art. 430 (Motores)
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_in == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Dimensionamiento de Motor',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Potencia', '${_potenciaCtrl.text} $_potenciaUnit'],
          ['Fases', _esTrifasico ? '3 (Trifásico)' : '1 (Monofásico)'],
          ['Voltaje', '${_voltajeCtrl.text} V'],
          ['Rendimiento (eta)', _rendimientoCtrl.text],
          ['Factor Potencia (cos phi)', _cosPhiCtrl.text],
        ],
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Corriente Nominal (In)', '${_in!.toStringAsFixed(2)} A'],
          ['Corriente Partida (Ip)', '${_ip!.toStringAsFixed(1)} A'],
          ['Disyuntor Sugerido', '${_breaker!.toStringAsFixed(1)} A'],
          ['Ajuste Térmico', '${_termico!.toStringAsFixed(1)} A'],
        ],
        formula: _esTrifasico ? 'In = P / (V * sqrt(3) * cos phi * eta)' : 'In = P / (V * cos phi * eta)',
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
        backgroundColor: DesignTokens.getSurface(b), elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(children: [
          const Icon(Icons.settings_input_component_rounded, color: _kElectric, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CÁLCULO DE MOTORES', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Dimensionamiento NOM (Art. 430)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
                    _sectionLabel(b, Icons.electric_bolt_rounded, 'TIPO DE CONEXIÓN'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _modeButton('TRIFÁSICO (3Φ)', _esTrifasico, () => setState(() => _esTrifasico = true), b),
                      const SizedBox(width: 12),
                      _modeButton('MONOFÁSICO (1Φ)', !_esTrifasico, () => setState(() => _esTrifasico = false), b),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel(b, Icons.input_rounded, 'DATOS DE PLACA'),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _powerInputField(_potenciaCtrl, 'Potencia (P)', 'Ej: 5', b, help: 'Potencia mecánica entregada por el motor. Habitualmente en HP o kW.')),
                      const SizedBox(width: 12),
                      Expanded(child: _inputField(_voltajeCtrl, 'Voltaje (V)', 'Ej: 380', 'V', Icons.bolt_rounded, b, help: 'Tensión nominal de alimentación del motor.')),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _inputField(_rendimientoCtrl, 'Rendimiento (η)', 'Ej: 0.85', '0-1', Icons.sync_rounded, b, help: 'Eficiencia del motor (Relación entre potencia útil y absorbida).')),
                      const SizedBox(width: 12),
                      Expanded(child: _inputField(_cosPhiCtrl, 'Factor Potencia', 'Ej: 0.82', 'cos φ', Icons.multiline_chart_rounded, b, help: 'Relación entre potencia activa y aparente.')),
                    ]),
                    const SizedBox(height: 24),
                    CalculatorButtonsPanel(
                      onCalculate: _calcular,
                      onReset: _limpiar,
                      onShare: _in != null ? _compartir : null,
                      onExportPdf: _in != null ? _exportarPDF : null,
                      showResults: _in != null,
                      mainColor: _kElectric,
                      calculateLabel: 'CALCULAR MOTOR',
                    ),
                    const SizedBox(height: 20),
                    if (_in != null) ...[
                      _buildResults(b),
                      const SizedBox(height: 28),
                      _buildFormulaCard(b),
                    ],
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(Brightness b, IconData icon, String txt) => Row(children: [
    Icon(icon, color: _kElectric, size: 16), const SizedBox(width: 8),
    Text(txt, style: const TextStyle(color: _kElectric, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  ]);

  Widget _modeButton(String txt, bool sel, VoidCallback tap, Brightness b) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: sel ? _kElectric : DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _kElectric : DesignTokens.getBorderColor(b))),
        child: Center(child: Text(txt, style: TextStyle(color: sel ? Colors.black : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 11))),
      ),
    ),
  );

  Widget _inputField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? help}) => Container(
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
        validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
      ),
    ]),
  );

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

  Widget _powerInputField(TextEditingController ctrl, String label, String hint, Brightness b, {String? help}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.power_rounded, color: _kElectric, size: 14), 
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
      Row(children: [
        Expanded(child: TextFormField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, border: InputBorder.none))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: _kElectric.withAlpha(25), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _potenciaUnit, isDense: true,
              dropdownColor: DesignTokens.getSurface(b),
              items: ['HP', 'kW', 'W'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: _kElectric, fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _potenciaUnit = v!),
            ),
          ),
        ),
      ]),
    ]),
  );

  Widget _buildResults(Brightness b) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _kElectric.withAlpha(12), borderRadius: BorderRadius.circular(24), border: Border.all(color: _kElectric.withAlpha(80))),
    child: Column(children: [
      Text('CORRIENTE NOMINAL (In)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text('${_in!.toStringAsFixed(2)} A', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: _kElectric)),
      const SizedBox(height: 24),
      _resultRow('Corriente Partida (Ip)', '${_ip!.toStringAsFixed(1)} A', b),
      _resultRow('Disyuntor Sugerido', '${_breaker!.toStringAsFixed(1)} A', b),
      _resultRow('Relé Térmico (Ajuste)', '${_termico!.toStringAsFixed(1)} A', b),
      const SizedBox(height: 16),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kElectric.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.info_outline_rounded, color: _kElectric, size: 14), const SizedBox(width: 8), Expanded(child: Text('Basado en NOM-001-SEDE Art. 430. Ip estimada x 6.5 In. Verificar contra Tablas 430-248/250 (corriente a plena carga).', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)))])),
    ]),
  );

  Widget _resultRow(String label, String val, Brightness b) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13)),
      Text(val, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 14)),
    ]),
  );

  Widget _buildFormulaCard(Brightness b) {
    const kFormula = Color(0xFF818CF8);
    final formula = _esTrifasico 
      ? 'In = P / (V · √3 · cos φ · η)' 
      : 'In = P / (V · cos φ · η)';
    
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          const Text('FÓRMULA TÉCNICA', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM Art. 430', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text(formula, style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('In', 'Corriente nominal', 'A', kFormula, b),
        _legendRow('P', 'Potencia activa', 'W', kFormula, b),
        _legendRow('V', 'Tensión nominal', 'V', kFormula, b),
        _legendRow('cos φ', 'Factor de potencia', 'f.p', kFormula, b),
        _legendRow('η (eta)', 'Rendimiento motor', '0-1', kFormula, b),
        if (_esTrifasico) _legendRow('√3', 'Factor trifásico ≈ 1.732', '—', kFormula, b),
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

