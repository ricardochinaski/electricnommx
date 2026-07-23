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

const _kAccent = Color(0xFFFACC15);

class CalculadoraAlumbradoScreen extends StatefulWidget {
  const CalculadoraAlumbradoScreen({super.key});

  @override
  State<CalculadoraAlumbradoScreen> createState() => _CalculadoraAlumbradoScreenState();
}

class _CalculadoraAlumbradoScreenState extends State<CalculadoraAlumbradoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _largoCtrl = TextEditingController(text: '10');
  final _anchoCtrl = TextEditingController(text: '6');
  final _luxRequeridoCtrl = TextEditingController(text: '300');
  final _lumenesLuminariaCtrl = TextEditingController(text: '3200');
  final _factorUtilizacionCtrl = TextEditingController(text: '0.6');
  final _factorMantenimientoCtrl = TextEditingController(text: '0.8');

  int? _cantidadLuminarias;

  @override
  void dispose() {
    _largoCtrl.dispose();
    _anchoCtrl.dispose();
    _luxRequeridoCtrl.dispose();
    _lumenesLuminariaCtrl.dispose();
    _factorUtilizacionCtrl.dispose();
    _factorMantenimientoCtrl.dispose();
    super.dispose();
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final double L = double.parse(_largoCtrl.text.replaceAll(',', '.'));
    final double A = double.parse(_anchoCtrl.text.replaceAll(',', '.'));
    final double E = double.parse(_luxRequeridoCtrl.text.replaceAll(',', '.'));
    final double phi = double.parse(_lumenesLuminariaCtrl.text.replaceAll(',', '.'));
    final double cu = double.parse(_factorUtilizacionCtrl.text.replaceAll(',', '.'));
    final double fm = double.parse(_factorMantenimientoCtrl.text.replaceAll(',', '.'));

    final double area = L * A;
    final double flujoTotal = (E * area) / (cu * fm);
    final double N = flujoTotal / phi;

    setState(() {
      _cantidadLuminarias = N.ceil();
    });

    // Mostrar intersticial al calcular (solo usuarios gratuitos)
    AdService.instance.showInterstitial(context);
  }

  void _limpiar() {
    setState(() {
      _largoCtrl.text = '10';
      _anchoCtrl.text = '6';
      _luxRequeridoCtrl.text = '300';
      _lumenesLuminariaCtrl.text = '3200';
      _factorUtilizacionCtrl.text = '0.6';
      _factorMantenimientoCtrl.text = '0.8';
      _cantidadLuminarias = null;
    });
  }

  void _compartir() {
    if (_cantidadLuminarias == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
📌 *DISEÑO DE ALUMBRADO — NOM Eléctrica MX*
——————————————————————————————
🛠️ *Método:* Lúmenes (NOM-007-ENER)
📅 *Fecha:* $fecha

📥 *DATOS DEL LOCAL:*
   • Área: ${_largoCtrl.text}m x ${_anchoCtrl.text}m (${double.parse(_largoCtrl.text) * double.parse(_anchoCtrl.text)} m²)
   • Lux Requerido: ${_luxRequeridoCtrl.text} lx
   • Flujo Luminaria: ${_lumenesLuminariaCtrl.text} lm

📊 *RESULTADO:*
   ➤ *Cantidad Necesaria: $_cantidadLuminarias Luminarias*

——————————————————————————————
📚 *Referencia:* NOM-007-ENER — Alumbrado
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_cantidadLuminarias == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: 'Cálculo de Iluminación',
        datosEntrada: [
          ['Parámetro', 'Valor'],
          ['Dimensiones', '${_largoCtrl.text}m x ${_anchoCtrl.text}m'],
          ['Iluminancia (E)', '${_luxRequeridoCtrl.text} Lux'],
          ['Lúmenes Luminaria (phi)', '${_lumenesLuminariaCtrl.text} lm'],
          ['Factor Utilización (Cu)', _factorUtilizacionCtrl.text],
          ['Factor Mantenimiento (Fm)', _factorMantenimientoCtrl.text],
        ],
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Área Total', '${(double.parse(_largoCtrl.text) * double.parse(_anchoCtrl.text)).toStringAsFixed(1)} m2'],
          ['Cantidad Luminarias', '$_cantidadLuminarias unidades'],
        ],
        formula: 'N = (E * Area) / (phi * Cu * Fm)',
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
          const Icon(Icons.lightbulb_outline_rounded, color: _kAccent, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CÁLCULO DE ALUMBRADO', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Método de Lúmenes (NOM-007-ENER)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
              _sectionLabel(b, Icons.square_foot_rounded, 'DIMENSIONES DEL RECINTO'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _inputField(_largoCtrl, 'Largo (m)', 'Ej: 10', 'm', Icons.straighten_rounded, b, help: 'Longitud total del recinto a iluminar.')),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_anchoCtrl, 'Ancho (m)', 'Ej: 6', 'm', Icons.straighten_rounded, b, help: 'Ancho total del recinto a iluminar.')),
              ]),
              const SizedBox(height: 24),
              _sectionLabel(b, Icons.wb_sunny_rounded, 'REQUERIMIENTOS LUMINÍNICOS'),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _inputField(_luxRequeridoCtrl, 'Iluminancia (E)', 'Ej: 300', 'lx', Icons.visibility_rounded, b, help: 'Nivel de iluminación deseado en la superficie de trabajo. Niveles recomendados por la NOM-007-ENER y la NOM-025-STPS según actividad.')),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_lumenesLuminariaCtrl, 'Lúmenes (Φ)', 'Ej: 3200', 'lm', Icons.light_mode_rounded, b, help: 'Cantidad de luz total emitida por una sola luminaria.')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _inputField(_factorUtilizacionCtrl, 'F. Utilización', 'Ej: 0.6', '0-1', Icons.tune_rounded, b, help: 'Porcentaje del flujo de las lámparas que llega al plano de trabajo (depende de reflectancias y geometría).')),
                const SizedBox(width: 12),
                Expanded(child: _inputField(_factorMantenimientoCtrl, 'F. Mantenimiento', 'Ej: 0.8', '0-1', Icons.cleaning_services_rounded, b, help: 'Factor que considera la pérdida de luz por suciedad y envejecimiento (habitualmente 0.8).')),
              ]),
              const SizedBox(height: 24),
              CalculatorButtonsPanel(
                onCalculate: _calcular,
                onReset: _limpiar,
                onShare: _cantidadLuminarias != null ? _compartir : null,
                onExportPdf: _cantidadLuminarias != null ? _exportarPDF : null,
                showResults: _cantidadLuminarias != null,
                mainColor: _kAccent,
                calculateLabel: 'CALCULAR PROYECTO',
              ),
              const SizedBox(height: 20),
              if (_cantidadLuminarias != null) ...[
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
      Text('LUMINARIAS REQUERIDAS', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text('$_cantidadLuminarias', style: GoogleFonts.outfit(fontSize: 56, fontWeight: FontWeight.w900, color: _kAccent)),
      const SizedBox(height: 4),
      Text('Unidades para el local', style: TextStyle(color: _kAccent.withAlpha(180), fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kAccent.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.info_outline_rounded, color: _kAccent, size: 14), const SizedBox(width: 8), Expanded(child: Text('Método de lúmenes universal. Verifique niveles de lux según NOM-007-ENER (edificios) y NOM-025-STPS (centros de trabajo).', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)))])),
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
          const Text('MÉTODO DE LÚMENES', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM-007-ENER', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text('N = (E · A) / (Φ · Cu · Fm)', style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('N', 'Cantidad luminarias', 'uds', kFormula, b),
        _legendRow('E', 'Iluminancia requerida', 'lx', kFormula, b),
        _legendRow('A', 'Área del recinto', 'm²', kFormula, b),
        _legendRow('Φ (phi)', 'Flujo de 1 luminaria', 'lm', kFormula, b),
        _legendRow('Cu', 'Coef. utilización', '0-1', kFormula, b),
        _legendRow('Fm', 'Coef. mantenimiento', '0-1', kFormula, b),
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

