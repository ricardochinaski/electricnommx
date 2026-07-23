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

const _kAccent = Color(0xFFFBBF24); // Ámbar para baterías/energía solar

class CalculadoraBateriasScreen extends StatefulWidget {
  const CalculadoraBateriasScreen({super.key});

  @override
  State<CalculadoraBateriasScreen> createState() => _CalculadoraBateriasScreenState();
}

class _CalculadoraBateriasScreenState extends State<CalculadoraBateriasScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _potenciaCtrl = TextEditingController(text: '500');
  final _horasCtrl = TextEditingController(text: '4');
  final _voltajeSistemaCtrl = TextEditingController(text: '12');
  final _dodCtrl = TextEditingController(text: '50'); // Depth of Discharge
  
  // Resultados
  double? _capacidadAh;
  double? _energiaTotalWh;

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final double P = double.parse(_potenciaCtrl.text.replaceAll(',', '.'));
    final double H = double.parse(_horasCtrl.text.replaceAll(',', '.'));
    final double V = double.parse(_voltajeSistemaCtrl.text.replaceAll(',', '.'));
    final double dod = double.parse(_dodCtrl.text.replaceAll(',', '.')) / 100.0;
    
    // Energía total requerida (Wh)
    final double energyWh = P * H;
    
    // Capacidad necesaria (Ah) = Wh / (V * DoD)
    final double ah = energyWh / (V * dod);

    setState(() {
      _energiaTotalWh = energyWh;
      _capacidadAh = ah;
    });

    // Mostrar intersticial al calcular (solo usuarios gratuitos)
    AdService.instance.showInterstitial(context);
  }

  void _limpiar() {
    setState(() {
      _potenciaCtrl.text = '500';
      _horasCtrl.text = '4';
      _voltajeSistemaCtrl.text = '12';
      _dodCtrl.text = '50';
      _energiaTotalWh = null;
      _capacidadAh = null;
    });
  }

  void _compartir() {
    if (_capacidadAh == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
📌 *REPORTE DE BATERÍAS — NOM Eléctrica MX*
——————————————————————————————
🛠️ *Dimensionamiento de Respaldo*
📅 *Fecha:* $fecha

📥 *DATOS:*
   • Carga: ${_potenciaCtrl.text} W
   • Autonomía: ${_horasCtrl.text} h
   • Voltaje Sistema: ${_voltajeSistemaCtrl.text} V
   • Descarga (DoD): ${_dodCtrl.text}%

📊 *RESULTADOS:*
   ➤ Energía Requerida: ${_energiaTotalWh!.toStringAsFixed(0)} Wh
   ➤ *Capacidad Necesaria: ${_capacidadAh!.toStringAsFixed(1)} Ah*

——————————————————————————————
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_capacidadAh == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Dimensionamiento de Baterías',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Potencia de Carga', '${_potenciaCtrl.text} W'],
          ['Autonomía deseada', '${_horasCtrl.text} horas'],
          ['Voltaje del Banco', '${_voltajeSistemaCtrl.text} V'],
          ['Profundidad Descarga', '${_dodCtrl.text}%'],
        ],
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Energía Total', '${_energiaTotalWh!.toStringAsFixed(0)} Wh'],
          ['Capacidad Necesaria', '${_capacidadAh!.toStringAsFixed(1)} Ah'],
        ],
        formula: 'Ah = (Potencia * Horas) / (Voltaje * DoD)',
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
          const Icon(Icons.battery_charging_full_rounded, color: _kAccent, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('DIMENSIONAR BATERÍAS', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Respaldo UPS y Sistemas Solares', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
              _sectionLabel(b, Icons.power_rounded, 'DATOS DE LA CARGA'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _inputField(_potenciaCtrl, 'Potencia (W)', 'Ej: 500', 'W', Icons.bolt_rounded, b, help: 'Potencia constante de la carga que se desea respaldar.')),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_horasCtrl, 'Autonomía', 'Ej: 4', 'hrs', Icons.timer_rounded, b, help: 'Tiempo total (en horas) que se requiere que las baterías suministren energía.')),
              ]),
              const SizedBox(height: 24),
              _sectionLabel(b, Icons.settings_input_component_rounded, 'DATOS DEL SISTEMA'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _inputField(_voltajeSistemaCtrl, 'Voltaje Banco', 'Ej: 12', 'V', Icons.electrical_services_rounded, b, help: 'Tensión nominal de conexión del banco de baterías (12V, 24V, 48V, etc).')),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_dodCtrl, 'Descarga (DoD)', 'Ej: 50', '%', Icons.battery_saver_rounded, b, help: 'Profundidad de descarga permitida (DoD). Plomo-Ácido: 50%, Litio: 80-90%.')),
              ]),
              const SizedBox(height: 24),
              CalculatorButtonsPanel(
                onCalculate: _calcular,
                onReset: _limpiar,
                onShare: _capacidadAh != null ? _compartir : null,
                onExportPdf: _capacidadAh != null ? _exportarPDF : null,
                showResults: _capacidadAh != null,
                mainColor: _kAccent,
                calculateLabel: 'CALCULAR BANCO',
              ),
              const SizedBox(height: 20),
              if (_capacidadAh != null) ...[
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

  Widget _buildResults(Brightness b) => Container(
    width: double.infinity, padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: _kAccent.withAlpha(12), borderRadius: BorderRadius.circular(24), border: Border.all(color: _kAccent.withAlpha(80))),
    child: Column(children: [
      Text('CAPACIDAD REQUERIDA (Ah)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text('${_capacidadAh!.toStringAsFixed(1)} Ah', style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: _kAccent)),
      const SizedBox(height: 24),
      _resultRow('Energía Total', '${_energiaTotalWh!.toStringAsFixed(0)} Wh', b),
      _resultRow('Voltaje del Banco', '${_voltajeSistemaCtrl.text} V', b),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kAccent.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.info_outline_rounded, color: _kAccent, size: 14), const SizedBox(width: 8), Expanded(child: Text('Recomendado: Plomo-Ácido (DoD 50%), Litio (DoD 80%). Considere un margen de seguridad extra.', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)))])),
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
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          const Text('CÁLCULO DE CAPACIDAD', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('DIMENSIONAMIENTO', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text('Ah = (P · t) / (V · DoD)', style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('Ah', 'Capacidad requerida', 'Ah', kFormula, b),
        _legendRow('P', 'Potencia de carga', 'W', kFormula, b),
        _legendRow('t', 'Tiempo autonomía', 'hrs', kFormula, b),
        _legendRow('V', 'Voltaje del sistema', 'V', kFormula, b),
        _legendRow('DoD', 'Prof. descarga', '0.1-1', kFormula, b),
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

