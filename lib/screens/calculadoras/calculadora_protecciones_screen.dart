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
const _kAccent = Color(0xFFF87171); // Rojo suave para protecciones

class CalculadoraProteccionesScreen extends StatefulWidget {
  const CalculadoraProteccionesScreen({super.key});

  @override
  State<CalculadoraProteccionesScreen> createState() => _CalculadoraProteccionesScreenState();
}

class _CalculadoraProteccionesScreenState extends State<CalculadoraProteccionesScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _potenciaCtrl = TextEditingController(text: '3000');
  final _voltajeCtrl = TextEditingController(text: '127');
  
  // Estados
  String _potenciaUnit = 'W';
  bool _esInductiva = false; // true = Inductiva (Motor), false = Resistiva
  bool _esTrifasico = false;

  double? _corrienteNominal;
  int? _disyuntorSugerido;
  int? _diferencialSugerido;

  // Valores nominales estándar de interruptores termomagnéticos según
  // NOM-001-SEDE, Art. 240-6 (pastillas comerciales en México)
  final List<int> _disyuntoresEstandar = [15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100, 110, 125, 150, 175, 200];
  // Interruptores GFCI/diferenciales comerciales típicos en México
  final List<int> _diferencialesEstandar = [15, 20, 30, 40, 50, 60, 100];

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    double P = double.parse(_potenciaCtrl.text.replaceAll(',', '.'));
    if (_potenciaUnit == 'kW') {
      P *= 1000;
    }
    if (_potenciaUnit == 'HP') {
      P *= 745.7;
    }

    final double V = double.parse(_voltajeCtrl.text.replaceAll(',', '.'));
    
    // I = P / (V * factor)
    double factor = _esTrifasico ? 1.732 : 1.0;
    // Si es inductiva/motor, asumimos un fp de 0.85 para el cálculo de protección
    double fp = _esInductiva ? 0.85 : 1.0;
    
    double inVal = P / (V * factor * fp);

    // Sugerencia de interruptor termomagnetico (NOM-001-SEDE, Arts. 210-20 y 240-6): 
    // Debe ser mayor a la corriente de carga y menor o igual a la capacidad del conductor.
    // Aquí sugerimos el comercial inmediatamente superior a inVal * 1.25 (margen de seguridad)
    double targetBreaker = inVal * 1.25;
    int disyuntor = _disyuntoresEstandar.firstWhere((d) => d >= targetBreaker, orElse: () => 200);

    // Sugerencia Diferencial:
    // Debe soportar una corriente nominal mayor o igual al disyuntor que lo protege.
    int diferencial = _diferencialesEstandar.firstWhere((d) => d >= disyuntor, orElse: () => 200);

    setState(() {
      _corrienteNominal = inVal;
      _disyuntorSugerido = disyuntor;
      _diferencialSugerido = diferencial;
    });

    // Mostrar intersticial al calcular (solo usuarios gratuitos)
    AdService.instance.showInterstitial(context);
  }

  void _limpiar() {
    setState(() {
      _potenciaCtrl.text = '3000';
      _voltajeCtrl.text = '127';
      _esInductiva = false;
      _esTrifasico = false;
      _potenciaUnit = 'W';
      _corrienteNominal = null;
      _disyuntorSugerido = null;
      _diferencialSugerido = null;
    });
  }

  void _compartir() {
    if (_corrienteNominal == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
📌 *REPORTE DE PROTECCIONES — NOM Eléctrica MX*
——————————————————————————————
🛠️ *Tipo de Carga:* ${_esInductiva ? 'Inductiva (Motor/Clima)' : 'Resistiva (Alumbrado/Calefacción)'}
📅 *Fecha:* $fecha

📥 *DATOS:*
   • Potencia: ${_potenciaCtrl.text} $_potenciaUnit
   • Voltaje: ${_voltajeCtrl.text} V (${_esTrifasico ? '3Φ' : '1Φ'})

📊 *RESULTADOS SUGERIDOS:*
   ➤ Corriente Nominal (In): ${_corrienteNominal!.toStringAsFixed(2)} A
   ➤ *Disyuntor Sugerido:* $_disyuntorSugerido A (Curva ${_esInductiva ? 'D' : 'C'})
   ➤ *Diferencial Sugerido:* $_diferencialSugerido A / 30mA

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE — Arts. 240 y 210-20
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_corrienteNominal == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Selección de Protecciones',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Potencia', '${_potenciaCtrl.text} $_potenciaUnit'],
          ['Tensión', '${_voltajeCtrl.text} V'],
          ['Fases', _esTrifasico ? 'Trifásico' : 'Monofásico'],
          ['Tipo de Carga', _esInductiva ? 'Inductiva' : 'Resistiva'],
        ],
        resultados: [
          ['Indicador', 'Valor Sugerido'],
          ['Corriente de Carga', '${_corrienteNominal!.toStringAsFixed(2)} A'],
          ['Capacidad Disyuntor', '$_disyuntorSugerido A'],
          ['Curva recomendada', _esInductiva ? 'D (Inductiva)' : 'C (Uso General)'],
          ['Capacidad Diferencial', '$_diferencialSugerido A / 30mA'],
        ],
        formula: 'In = P / (V * factor * fp)',
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
          const Icon(Icons.security_rounded, color: _kAccent, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SELECTOR DE PROTECCIONES', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Pastillas y GFCI segun NOM (Art. 240-6)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
                    _sectionLabel(b, Icons.settings_rounded, 'CONFIGURACIÓN DE RED'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _modeButton('MONOFÁSICO', !_esTrifasico, () => setState(() => _esTrifasico = false), b),
                      const SizedBox(width: 12),
                      _modeButton('TRIFÁSICO', _esTrifasico, () => setState(() => _esTrifasico = true), b),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel(b, Icons.category_rounded, 'TIPO DE CARGA'),
                    const SizedBox(height: 12),
                    Row(children: [
                      _modeButton('RESISTIVA', !_esInductiva, () => setState(() => _esInductiva = false), b),
                      const SizedBox(width: 12),
                      _modeButton('INDUCTIVA', _esInductiva, () => setState(() => _esInductiva = true), b),
                    ]),
                    const SizedBox(height: 24),
                    _sectionLabel(b, Icons.input_rounded, 'DATOS DE CARGA'),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: _powerInputField(_potenciaCtrl, 'Potencia (P)', 'Ej: 3000', b, help: 'Potencia total de los equipos a proteger.')),
                      const SizedBox(width: 12),
                      Expanded(child: _inputField(_voltajeCtrl, 'Voltaje (V)', 'Ej: 220', 'V', Icons.bolt_rounded, b, help: 'Tensión nominal del circuito.')),
                    ]),
                    const SizedBox(height: 24),
                    CalculatorButtonsPanel(
                      onCalculate: _calcular,
                      onReset: _limpiar,
                      onShare: _corrienteNominal != null ? _compartir : null,
                      onExportPdf: _corrienteNominal != null ? _exportarPDF : null,
                      showResults: _corrienteNominal != null,
                      mainColor: _kAccent,
                      calculateLabel: 'CALCULAR PROTECCIÓN',
                    ),
                    const SizedBox(height: 20),
                    if (_corrienteNominal != null) ...[
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
    Icon(icon, color: _kAccent, size: 16), const SizedBox(width: 8),
    Text(txt, style: const TextStyle(color: _kAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  ]);

  Widget _modeButton(String txt, bool sel, VoidCallback tap, Brightness b) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: sel ? _kAccent : DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _kAccent : DesignTokens.getBorderColor(b))),
        child: Center(child: Text(txt, style: TextStyle(color: sel ? Colors.white : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 11))),
      ),
    ),
  );

  Widget _inputField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? help}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _kAccent, size: 14), 
        const SizedBox(width: 6), 
        Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
        if (help != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => _showHelpDialog(context, label, help),
            child: Icon(Icons.info_outline_rounded, color: _kAccent.withAlpha(150), size: 14),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14), suffixText: unit, suffixStyle: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 13), border: InputBorder.none),
        validator: (v) {
          if (v == null || v.isEmpty) {
            return 'Requerido';
          }
          return null;
        },
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
          const Icon(Icons.info_outline_rounded, color: _kAccent),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _powerInputField(TextEditingController ctrl, String label, String hint, Brightness b, {String? help}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.bolt_rounded, color: _kAccent, size: 14), 
        const SizedBox(width: 6), 
        Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
        if (help != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => _showHelpDialog(context, label, help),
            child: Icon(Icons.info_outline_rounded, color: _kAccent.withAlpha(150), size: 14),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, border: InputBorder.none))),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: _kAccent.withAlpha(25), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _potenciaUnit, isDense: true,
              dropdownColor: DesignTokens.getSurface(b),
              items: ['W', 'kW', 'HP'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
              onChanged: (v) => setState(() => _potenciaUnit = v!),
            ),
          ),
        ),
      ]),
    ]),
  );

  Widget _buildResults(Brightness b) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _kAccent.withAlpha(12), borderRadius: BorderRadius.circular(24), border: Border.all(color: _kAccent.withAlpha(80))),
    child: Column(children: [
      Text('DISYUNTOR SUGERIDO', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text('$_disyuntorSugerido A', style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: _kAccent)),
      Text('Curva ${_esInductiva ? 'D' : 'C'}', style: TextStyle(color: _kAccent.withAlpha(180), fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      _resultRow('Corriente Nominal (In)', '${_corrienteNominal!.toStringAsFixed(2)} A', b),
      _resultRow('Diferencial (ID)', '$_diferencialSugerido A / 30mA', b),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kAccent.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.info_outline_rounded, color: _kAccent, size: 14), const SizedBox(width: 8), Expanded(child: Text('Verifique que la capacidad del conductor sea mayor al disyuntor seleccionado.', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)))])),
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
      ? 'In = P / (V · √3 · cos φ)' 
      : 'In = P / (V · cos φ)';
    
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          const Text('CÁLCULO DE PROTECCIÓN', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM 240-6', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text(formula, style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('In', 'Corriente de carga', 'A', kFormula, b),
        _legendRow('P', 'Potencia instalada', 'W', kFormula, b),
        _legendRow('V', 'Tensión nominal', 'V', kFormula, b),
        _legendRow('cos φ', 'Factor potencia (est)', 'f.p', kFormula, b),
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

