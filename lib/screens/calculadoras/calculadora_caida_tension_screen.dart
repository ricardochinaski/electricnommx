import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kAccentElectric = Color(0xFF00E5FF);
const _kAccentPositivo = Color(0xFF00FF88);
const _kAccentError = Color(0xFFFF5252);
const _kFormulaColor = Color(0xFF818CF8);

class CalculadoraCaidaTensionPage extends StatefulWidget {
  const CalculadoraCaidaTensionPage({super.key});

  @override
  State<CalculadoraCaidaTensionPage> createState() => _CalculadoraCaidaTensionPageState();
}

class _CalculadoraCaidaTensionPageState extends State<CalculadoraCaidaTensionPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _largoCtrl = TextEditingController();
  final _corrienteCtrl = TextEditingController();
  final _seccionCtrl = TextEditingController();
  final _cosPhiCtrl = TextEditingController(text: '0.93');

  // Estado
  bool _esTrifasico = false;
  String _tipoConductor = 'Cobre';
  double? _resultadoVP;
  double? _porcentajeVP;

  final Map<String, double> _resistividad = {'Cobre': 0.018, 'Aluminio': 0.028};

  @override
  void dispose() {
    _largoCtrl.dispose();
    _corrienteCtrl.dispose();
    _seccionCtrl.dispose();
    _cosPhiCtrl.dispose();
    super.dispose();
  }

  void _calcular() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      final double L = double.parse(_largoCtrl.text.replaceAll(',', '.'));
      final double I = double.parse(_corrienteCtrl.text.replaceAll(',', '.'));
      final double S = double.parse(_seccionCtrl.text.replaceAll(',', '.'));
      final double rho = _resistividad[_tipoConductor]!;

      double vp;
      double vNominal = _esTrifasico ? 220 : 127; // Tensiones nominales mexicanas

      if (_esTrifasico) {
        final double cosPhi = double.parse(_cosPhiCtrl.text.replaceAll(',', '.'));
        vp = (sqrt(3) * rho * L * I * cosPhi) / S;
      } else {
        vp = (2 * rho * L * I) / S;
      }

      if (!vp.isFinite) {
        throw const FormatException('resultado no finito (verifica que S > 0)');
      }

      setState(() {
        _resultadoVP = vp;
        _porcentajeVP = (vp / vNominal) * 100;
      });

      // Mostrar intersticial al calcular (solo usuarios gratuitos)
      AdService.instance.showInterstitial(context);
    } catch (e) {
      // Red de seguridad ante entradas que superen el validator (ej: "2..5")
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Entrada inválida: revisa los valores ingresados. ($e)'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _limpiar() {
    _largoCtrl.clear();
    _corrienteCtrl.clear();
    _seccionCtrl.clear();
    _cosPhiCtrl.text = '0.93';
    setState(() {
      _resultadoVP = null;
      _porcentajeVP = null;
    });
  }

  void _compartirReporte() {
    if (_resultadoVP == null) return;
    final String fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final String tipo = _esTrifasico ? 'Trifásica (3Φ)' : 'Monofásica (1Φ)';
    final double vNom = _esTrifasico ? 220 : 127;
    final double limite = 3.0; // Circuito derivado (nota Art. 210-19); el total con alimentador admite 5% (215-2)

    final String reporte = '''
📌 *REPORTE ELÉCTRICO — NOM Eléctrica MX*
——————————————————————————————
🛠️ *Cálculo:* Caída de Tensión $tipo
📅 *Fecha:* $fecha

📥 *DATOS:*
   • Largo: ${_largoCtrl.text} m
   • Corriente: ${_corrienteCtrl.text} A
   • Sección: ${_seccionCtrl.text} mm²
   • Material: $_tipoConductor
   ${_esTrifasico ? '• cos φ: ${_cosPhiCtrl.text}' : ''}

📊 *RESULTADO:*
   ➤ *VP = ${_formatValue(_resultadoVP!)} V*
   ➤ *${_porcentajeVP!.toStringAsFixed(2)}% de $vNom V*
   ➤ ${_porcentajeVP! > limite ? '❌ EXCEDE' : '✅ DENTRO'} del límite del $limite%

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE — Arts. 210-19 y 215-2
_App NOM Eléctrica MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_resultadoVP == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      if (_esTrifasico) {
        await PdfGenerator.generateTrifasicaReport(
          largo: double.parse(_largoCtrl.text.replaceAll(',', '.')),
          corriente: double.parse(_corrienteCtrl.text.replaceAll(',', '.')),
          seccion: double.parse(_seccionCtrl.text.replaceAll(',', '.')),
          rho: _resistividad[_tipoConductor]!,
          cosPhi: double.parse(_cosPhiCtrl.text.replaceAll(',', '.')),
          vp: _resultadoVP!,
          porcentaje: _porcentajeVP!,
        );
      } else {
        await PdfGenerator.generateMonofasicaReport(
          largo: double.parse(_largoCtrl.text.replaceAll(',', '.')),
          corriente: double.parse(_corrienteCtrl.text.replaceAll(',', '.')),
          seccion: double.parse(_seccionCtrl.text.replaceAll(',', '.')),
          material: _tipoConductor,
          rho: _resistividad[_tipoConductor]!,
          vp: _resultadoVP!,
          porcentaje: _porcentajeVP!,
        );
      }
    });
  }

  String _formatValue(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val.toStringAsFixed(3).replaceAll(RegExp(r'0*$'), '').replaceAll(RegExp(r'\.$'), '');
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
          const Icon(Icons.flash_on_rounded, color: _kAccentElectric, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CAÍDA DE TENSIÓN', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text(_esTrifasico ? 'Sistema Trifásico 220V' : 'Sistema Monofásico 127V', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
              _buildSectionLabel(b, Icons.electrical_services_rounded, 'TIPO DE SISTEMA'),
              const SizedBox(height: 12),
              Row(children: [
                _modeButton('MONOFÁSICO', !_esTrifasico, () => setState(() { _esTrifasico = false; _resultadoVP = null; }), b),
                const SizedBox(width: 12),
                _modeButton('TRIFÁSICO', _esTrifasico, () => setState(() { _esTrifasico = true; _resultadoVP = null; }), b),
              ]),
              const SizedBox(height: 24),
              _buildSectionLabel(b, Icons.input_rounded, 'DATOS DE ENTRADA'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInputField(_largoCtrl, 'Largo (L)', 'Ej: 25.5', 'm', Icons.straighten_rounded, b, 
                  help: 'Distancia lineal total del conductor desde el tablero hasta el punto de consumo.')),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(_corrienteCtrl, 'Corriente (I)', 'Ej: 15.0', 'A', Icons.electric_bolt_rounded, b, 
                  help: 'Intensidad de corriente máxima que circulará por el circuito.')),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _buildInputField(_seccionCtrl, 'Sección (S)', 'Ej: 2.5', 'mm²', Icons.grid_view_rounded, b, 
                  help: 'Área transversal del conductor. A mayor sección, menor caída de tensión.')),
                const SizedBox(width: 12),
                Expanded(child: _buildDropdown(b)),
              ]),
              if (_esTrifasico) ...[
                const SizedBox(height: 12),
                _buildInputField(_cosPhiCtrl, 'Factor de Potencia (cos φ)', 'Ej: 0.93', 'f.p', Icons.timeline_rounded, b,
                  help: 'Relación entre la potencia activa y la potencia aparente (Eficiencia).',
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Requerido';
                    final n = double.tryParse(v.replaceAll(',', '.'));
                    if (n == null) return 'Número inválido';
                    if (n <= 0 || n > 1) return 'Rango: 0 < cos φ ≤ 1';
                    return null;
                  }),
              ],
              const SizedBox(height: 24),
              CalculatorButtonsPanel(
                onCalculate: _calcular,
                onReset: _limpiar,
                onShare: _resultadoVP != null ? _compartirReporte : null,
                onExportPdf: _resultadoVP != null ? _exportarPDF : null,
                showResults: _resultadoVP != null,
                mainColor: _kAccentElectric,
                calculateLabel: 'CALCULAR',
              ),
              const SizedBox(height: 20),
              _buildResultCard(b),
              const SizedBox(height: 28),
              _buildFormulaCard(b),
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

  Widget _modeButton(String txt, bool sel, VoidCallback tap, Brightness b) => Expanded(
    child: GestureDetector(
      onTap: tap,
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: sel ? _kAccentElectric : DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? _kAccentElectric : DesignTokens.getBorderColor(b))),
        child: Center(child: Text(txt, style: TextStyle(color: sel ? Colors.black : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 11))),
      ),
    ),
  );

  Widget _buildSectionLabel(Brightness b, IconData icon, String label) => Row(children: [
    Icon(icon, color: _kAccentElectric, size: 16), const SizedBox(width: 8),
    Text(label, style: const TextStyle(color: _kAccentElectric, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
  ]);

  Widget _buildInputField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? help, String? Function(String?)? validator}) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, color: _kAccentElectric, size: 14), 
        const SizedBox(width: 6), 
        Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
        if (help != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: () => _showHelpDialog(context, label, help),
            child: Icon(Icons.info_outline_rounded, color: _kAccentElectric.withAlpha(150), size: 14),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
        decoration: InputDecoration(
          isDense: true, 
          contentPadding: const EdgeInsets.symmetric(vertical: 4), 
          hintText: hint,
          hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14),
          suffixText: unit, 
          suffixStyle: const TextStyle(color: _kAccentElectric, fontWeight: FontWeight.bold, fontSize: 13), 
          border: InputBorder.none
        ),
        validator: validator ??
            (v) {
              if (v == null || v.isEmpty) return 'Requerido';
              final n = double.tryParse(v.replaceAll(',', '.'));
              if (n == null) return 'Número inválido';
              if (n <= 0) return 'Debe ser > 0';
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
          const Icon(Icons.info_outline_rounded, color: _kAccentElectric),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: _kAccentElectric, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildDropdown(Brightness b) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [const Icon(Icons.cable_rounded, color: _kAccentElectric, size: 14), const SizedBox(width: 6), Text('Material', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600))]),
      const SizedBox(height: 4),
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _tipoConductor, isExpanded: true, dropdownColor: DesignTokens.getSurface(b),
          icon: const Icon(Icons.expand_more_rounded, color: _kAccentElectric, size: 20),
          style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 15),
          items: _resistividad.keys.map((k) => DropdownMenuItem(value: k, child: Text(k))).toList(),
          onChanged: (v) => setState(() => _tipoConductor = v!),
        ),
      ),
    ]),
  );

  Widget _buildResultCard(Brightness b) {
    if (_resultadoVP == null) return const SizedBox();
    final double limite = 3.0; // Circuito derivado (nota Art. 210-19); el total con alimentador admite 5% (215-2)
    final bool excede = _porcentajeVP! > limite;
    final Color color = excede ? _kAccentError : _kAccentPositivo;

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withAlpha(150), width: 1.5)),
      child: Column(children: [
        Text('CAÍDA DE TENSIÓN (VP)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Text('${_formatValue(_resultadoVP!)} V', style: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w900, color: _kAccentElectric, height: 1)),
        const SizedBox(height: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(30)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(excede ? Icons.warning_rounded : Icons.check_circle_rounded, color: color, size: 16), const SizedBox(width: 6),
            Text('${_porcentajeVP!.toStringAsFixed(2)}%  •  ${excede ? 'Excede el $limite%' : 'Dentro del $limite%'}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ])),
      ]),
    );
  }

  Widget _buildFormulaCard(Brightness b) => Container(
    width: double.infinity, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: _kFormulaColor.withAlpha(60))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.functions_rounded, color: _kFormulaColor, size: 18), const SizedBox(width: 8),
        const Text('FÓRMULA NOM-001-SEDE', style: TextStyle(color: _kFormulaColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ]),
      const SizedBox(height: 16),
      Center(child: Text(_esTrifasico ? 'VP = (√3 · ρ · L · I · cos φ) / S' : 'VP = (2 · ρ · L · I) / S', style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: _kFormulaColor))),
      const SizedBox(height: 16),
      Divider(color: DesignTokens.getBorderColor(b)),
      const SizedBox(height: 10),
      _buildLeyenda('ρ (rho)', 'Resistividad', 'Ω·mm²/m', b),
      _buildLeyenda('L', 'Longitud tramo', 'm', b),
      _buildLeyenda('I', 'Corriente', 'A', b),
      if (_esTrifasico) _buildLeyenda('cos φ', 'Factor potencia', 'f.p', b),
      _buildLeyenda('S', 'Sección', 'mm²', b),
    ]),
  );

  Widget _buildLeyenda(String s, String d, String u, Brightness b) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 60, child: Text(s, style: GoogleFonts.firaCode(fontSize: 12, color: _kFormulaColor, fontWeight: FontWeight.bold))),
      Expanded(child: Text(d, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12))),
      Text(u, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

