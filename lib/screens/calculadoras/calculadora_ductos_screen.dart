import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/utils/pdf_generator.dart';
import 'package:nom_electrica_mx/utils/premium_utils.dart';
import 'package:nom_electrica_mx/widgets/calculator_actions.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

class CalculadoraDuctosScreen extends StatefulWidget {
  const CalculadoraDuctosScreen({super.key});

  @override
  State<CalculadoraDuctosScreen> createState() => _CalculadoraDuctosScreenState();
}

class _CalculadoraDuctosScreenState extends State<CalculadoraDuctosScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores
  final _cantidadCtrl = TextEditingController(text: '3');
  
  // Estados
  String _tipoConductor = 'THHN'; // NYA, EVA, THHN
  String _calibreConductor = '2.5 mm² (14 AWG)';
  
  double? _seccionTotalCables;
  double? _ocupacionReal;
  double? _limiteOcupacion;
  String? _ductoSugerido;
  String? _ductoSugeridoPulgadas;
  bool? _cumple;

  // Calibres comerciales y sus equivalencias aproximadas AWG
  final List<String> _calibres = [
    '1.5 mm² (16 AWG)',
    '2.5 mm² (14 AWG)',
    '4.0 mm² (12 AWG)',
    '6.0 mm² (10 AWG)',
    '10.0 mm² (8 AWG)',
    '16.0 mm² (6 AWG)',
    '25.0 mm² (4 AWG)',
    '35.0 mm² (2 AWG)',
    '50.0 mm² (1/0 AWG)',
  ];

  // Diámetros exteriores promedio según el tipo de conductor (incluyendo aislación)
  final Map<String, Map<String, double>> _diametrosExteriores = {
    'NYA': {
      '1.5 mm² (16 AWG)': 3.0,
      '2.5 mm² (14 AWG)': 3.6,
      '4.0 mm² (12 AWG)': 4.3,
      '6.0 mm² (10 AWG)': 4.9,
      '10.0 mm² (8 AWG)': 6.2,
      '16.0 mm² (6 AWG)': 7.4,
      '25.0 mm² (4 AWG)': 9.2,
      '35.0 mm² (2 AWG)': 10.5,
      '50.0 mm² (1/0 AWG)': 12.2,
    },
    'EVA': {
      '1.5 mm² (16 AWG)': 3.1,
      '2.5 mm² (14 AWG)': 3.7,
      '4.0 mm² (12 AWG)': 4.3,
      '6.0 mm² (10 AWG)': 4.9,
      '10.0 mm² (8 AWG)': 6.2,
      '16.0 mm² (6 AWG)': 7.3,
      '25.0 mm² (4 AWG)': 8.9,
      '35.0 mm² (2 AWG)': 10.1,
      '50.0 mm² (1/0 AWG)': 11.8,
    },
    'THHN': {
      '1.5 mm² (16 AWG)': 2.8,
      '2.5 mm² (14 AWG)': 3.3,
      '4.0 mm² (12 AWG)': 3.9,
      '6.0 mm² (10 AWG)': 4.4,
      '10.0 mm² (8 AWG)': 5.7,
      '16.0 mm² (6 AWG)': 6.8,
      '25.0 mm² (4 AWG)': 8.4,
      '35.0 mm² (2 AWG)': 9.5,
      '50.0 mm² (1/0 AWG)': 11.2,
    }
  };

  // Base de datos de tuberias conduit comerciales en Mexico (Pulgadas / Diametro Interior en mm)
  final List<Map<String, dynamic>> _ductosComerciales = [
    {'nominal': '16mm', 'pulgadas': '1/2"', 'di': 13.0, 'area': 132.73},
    {'nominal': '20mm', 'pulgadas': '3/4"', 'di': 16.2, 'area': 206.12},
    {'nominal': '25mm', 'pulgadas': '1"', 'di': 20.4, 'area': 326.85},
    {'nominal': '32mm', 'pulgadas': '1 1/4"', 'di': 26.2, 'area': 539.13},
    {'nominal': '40mm', 'pulgadas': '1 1/2"', 'di': 33.2, 'area': 865.70},
    {'nominal': '50mm', 'pulgadas': '2"', 'di': 42.6, 'area': 1425.31},
    {'nominal': '63mm', 'pulgadas': '2 1/2"', 'di': 54.8, 'area': 2358.85},
    {'nominal': '75mm', 'pulgadas': '3"', 'di': 67.8, 'area': 3610.28},
  ];

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    
    final int cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;
    if (cantidad <= 0) return;

    // Obtener diámetro exterior del cable
    final double diametroCable = _diametrosExteriores[_tipoConductor]![_calibreConductor]!;
    final double radioCable = diametroCable / 2;
    final double areaUnCable = pi * pow(radioCable, 2);
    final double seccionTotal = cantidad * areaUnCable;

    // Límite de ocupación según cantidad (NOM Cap. 10)
    final double limite = cantidad == 1 
        ? 53.0 
        : (cantidad == 2 ? 31.0 : 40.0);

    // Buscar el menor ducto comercial que cumpla con la ocupación máxima permitida
    String ductoSugerido = 'Ninguno';
    String ductoSugeridoPulgadas = 'excede 3"';
    bool cumpleResult = false;

    // Si ningún ducto cumple, se reporta la ocupación REAL calculada en el
    // mayor ducto comercial (75mm) — nunca un "100%" ficticio inventado.
    final Map<String, dynamic> mayorDucto = _ductosComerciales.last;
    double ocupacionRealResult = (seccionTotal / (mayorDucto['area'] as double)) * 100;

    for (var ducto in _ductosComerciales) {
      final double areaUtil = ducto['area'] as double;
      final double ocupacion = (seccionTotal / areaUtil) * 100;
      if (ocupacion <= limite) {
        ductoSugerido = ducto['nominal'] as String;
        ductoSugeridoPulgadas = ducto['pulgadas'] as String;
        ocupacionRealResult = ocupacion;
        cumpleResult = true;
        break;
      }
    }

    setState(() {
      _seccionTotalCables = seccionTotal;
      _limiteOcupacion = limite;
      _ductoSugerido = ductoSugerido;
      _ductoSugeridoPulgadas = ductoSugeridoPulgadas;
      _ocupacionReal = ocupacionRealResult;
      _cumple = cumpleResult;
    });

    // Mostrar anuncio intersticial para no premium
    AdService.instance.showInterstitial(context);
  }

  Future<void> _exportarPDF() async {
    if (_seccionTotalCables == null) return;
    
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateDuctosReport(
        cantidad: int.parse(_cantidadCtrl.text),
        diametroCable: _diametrosExteriores[_tipoConductor]![_calibreConductor]!,
        ductoNominal: _ductoSugerido ?? 'N/A',
        ocupacion: _ocupacionReal!,
        limite: _limiteOcupacion!,
        cumple: _cumple!,
      );
    });
  }

  void _limpiar() {
    setState(() {
      _seccionTotalCables = null;
      _ocupacionReal = null;
      _limiteOcupacion = null;
      _ductoSugerido = null;
      _ductoSugeridoPulgadas = null;
      _cumple = null;
      _tipoConductor = 'THHN';
      _calibreConductor = '2.5 mm² (14 AWG)';
      _cantidadCtrl.text = '3';
    });
  }

  void _compartir() {
    if (_seccionTotalCables == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final reporte = '''
⚡ *NOM ELÉCTRICA MX*
🛠️ *Cálculo:* Sección de Ductos (Conduit)
📅 *Fecha:* $fecha

📥 *DATOS INGRESADOS:*
   • Tipo de Cable: $_tipoConductor
   • Calibre: $_calibreConductor
   • Cantidad: ${_cantidadCtrl.text} cables

📊 *RESULTADOS:*
   ➤ Sección Total Cables: ${_seccionTotalCables!.toStringAsFixed(1)} mm²
   ➤ Límite de Ocupación: ${_limiteOcupacion!.toStringAsFixed(0)}% (NOM Cap. 10)
   ➤ Ducto Sugerido: $_ductoSugerido / $_ductoSugeridoPulgadas
   ➤ Ocupación Real: ${_ocupacionReal!.toStringAsFixed(1)}%
   ➤ Estado: ${_cumple! ? '✅ CUMPLE' : '❌ EXCEDE CAPACIDAD'}

——————————————————————————————
📚 *Referencia:* NOM-001-SEDE — Capítulo 10, Tabla 1 (Canalizaciones)
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
        title: Text("Tubería Conduit (NOM Cap. 10)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
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
                      if (_seccionTotalCables != null) ...[
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
    decoration: BoxDecoration(color: DesignTokens.accent.withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: DesignTokens.accent.withAlpha(50))),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: DesignTokens.accent, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text("Según la NOM-001-SEDE (Capítulo 10, Tabla 1), la ocupación interna máxima admisible de la tubería conduit es: 53% para 1 conductor, 31% para 2 conductores y 40% para 3 o más conductores.", style: TextStyle(fontSize: 11, color: DesignTokens.getTextPrimary(b).withAlpha(200)))),
    ]),
  );

  Widget _buildInputCard(Brightness b) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(20), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(children: [
      _rowLabel("CONDUCTORES Y CANTIDAD"),
      const SizedBox(height: 16),
      
      // Dropdown de Tipo de Conductor
      _dropdown("Tipo de Conductor", _tipoConductor, ['NYA', 'EVA', 'THHN'], (v) {
        setState(() {
          _tipoConductor = v!;
          _seccionTotalCables = null; // reset calculations
        });
      }, b),
      const SizedBox(height: 16),

      // Dropdown de Calibres
      _dropdown("Calibre del Conductor", _calibreConductor, _calibres, (v) {
        setState(() {
          _calibreConductor = v!;
          _seccionTotalCables = null;
        });
      }, b),
      const SizedBox(height: 16),

      // Input cantidad
      _textField(_cantidadCtrl, "Cantidad de Conductores", "Ej: 3", Icons.numbers, b, 
        help: 'Número de cables portadores de corriente agrupados en la misma canalización.'),
    ]),
  );

  Widget _rowLabel(String label) => Row(children: [
    Container(width: 4, height: 14, decoration: BoxDecoration(color: DesignTokens.accent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: DesignTokens.accent)),
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
            child: Icon(Icons.info_outline_rounded, color: DesignTokens.accent.withAlpha(150), size: 12),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.number,
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: DesignTokens.accent),
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
          const Icon(Icons.info_outline_rounded, color: DesignTokens.accent),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: DesignTokens.accent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Brightness b) => Column(
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
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _buildActionButtons(Brightness b) => CalculatorButtonsPanel(
        onCalculate: _calcular,
        onReset: _limpiar,
        onShare: _seccionTotalCables != null ? _compartir : null,
        onExportPdf: _seccionTotalCables != null ? _exportarPDF : null,
        showResults: _seccionTotalCables != null,
        mainColor: DesignTokens.accent,
        calculateLabel: 'CALCULAR SECCIÓN Y DUCTO',
      );

  Widget _buildResults(Brightness b) {
    final color = _cumple! ? const Color(0xFF00FF88) : const Color(0xFFFF5252);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Column(children: [
        Icon(_cumple! ? Icons.check_circle_rounded : Icons.warning_rounded, color: color, size: 40),
        const SizedBox(height: 12),
        Text(_cumple! ? "DUCTO COMERCIAL SUGERIDO" : "EXCEDE LÍMITES COMERCIALES", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
        const SizedBox(height: 24),
        if (_cumple!) ...[
          Text(
            "$_ductoSugerido / $_ductoSugeridoPulgadas",
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Conduit Mínimo Recomendado",
            style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12),
          ),
          const SizedBox(height: 24),
        ],
        _resultRow("Sección Total Cables", "${_seccionTotalCables!.toStringAsFixed(1)} mm²", DesignTokens.getTextPrimary(b), b),
        const SizedBox(height: 8),
        _resultRow(_cumple! ? "Ocupación Real" : 'Ocupación en ducto mayor (75mm / 3")', "${_ocupacionReal!.toStringAsFixed(1)}%", color, b),
        const SizedBox(height: 8),
        _resultRow("Límite Permitido (NOM Cap. 10)", "${_limiteOcupacion!.toStringAsFixed(0)}%", DesignTokens.getTextPrimary(b), b),
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
          const Text('CÁLCULO DE SECCIÓN Y OCUPACIÓN', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM Cap. 10', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text('S_cable = n · π · (d/2)²', style: GoogleFonts.firaCode(fontSize: 16, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('S_cable', 'Sección transversal total', 'mm²', kFormula, b),
        _legendRow('n', 'Cantidad de conductores', 'un', kFormula, b),
        _legendRow('d', 'Diámetro exterior cable', 'mm', kFormula, b),
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

