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

class CalculadoraMallaScreen extends StatefulWidget {
  const CalculadoraMallaScreen({super.key});

  @override
  State<CalculadoraMallaScreen> createState() => _CalculadoraMallaScreenState();
}

class _CalculadoraMallaScreenState extends State<CalculadoraMallaScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores e Inputs Generales
  final _resistividadCtrl = TextEditingController(text: '100');
  
  // Estados de configuración de electrodo
  int _selectedConfigIndex = 0; // 0 = Barra Única, 1 = Configuración en Delta, 2 = Malla Cuadrada Básica

  // Inputs para Barra Única y Delta
  final _largoBarraCtrl = TextEditingController(text: '2.4');
  String _diametroBarra = '5/8"'; // 1/2", 5/8", 3/4"
  final Map<String, double> _barraDiametrosMm = {
    '1/2"': 12.70,
    '5/8"': 15.88,
    '3/4"': 19.05,
  };

  // Inputs para Malla Cuadrada Básica
  final _largoMallaCtrl = TextEditingController(text: '3.0');
  final _anchoMallaCtrl = TextEditingController(text: '3.0');
  final _nxCtrl = TextEditingController(text: '3');
  final _nyCtrl = TextEditingController(text: '3');
  final _profundidadCtrl = TextEditingController(text: '0.6');

  // Resultados
  double? _resistencia;
  double? _longitudTotal;
  double? _areaMalla;

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;

    final double rho = double.tryParse(_resistividadCtrl.text.replaceAll(',', '.')) ?? 0.0;
    if (rho <= 0) return;

    double rCalculada = 0.0;
    double lTotal = 0.0;
    double area = 0.0;

    if (_selectedConfigIndex == 0 || _selectedConfigIndex == 1) {
      // Barra Única o Delta
      final double lBarra = double.tryParse(_largoBarraCtrl.text.replaceAll(',', '.')) ?? 2.4;
      final double dBarraMm = _barraDiametrosMm[_diametroBarra]!;
      final double rBarraM = (dBarraMm / 1000) / 2; // Radio en metros

      // Fórmula de Dwight para Barra Única
      final double rBarraUnica = (rho / (2 * pi * lBarra)) * (log(4 * lBarra / rBarraM) - 1);

      if (_selectedConfigIndex == 0) {
        rCalculada = rBarraUnica;
        lTotal = lBarra;
      } else {
        // Delta (3 barras interconectadas)
        rCalculada = (rBarraUnica / 3) * 1.15;
        lTotal = lBarra * 3;
      }
    } else {
      // Malla Cuadrada/Rectangular Básica
      final double largo = double.tryParse(_largoMallaCtrl.text.replaceAll(',', '.')) ?? 3.0;
      final double ancho = double.tryParse(_anchoMallaCtrl.text.replaceAll(',', '.')) ?? 3.0;
      final int nx = int.tryParse(_nxCtrl.text) ?? 3;
      final int ny = int.tryParse(_nyCtrl.text) ?? 3;

      area = largo * ancho;
      lTotal = (nx * largo) + (ny * ancho);

      // Radio equivalente (r_equiv)
      final double rEquiv = sqrt(area / pi);

      // Aproximación de Laurent
      rCalculada = (rho / (4 * rEquiv)) + (rho / lTotal);
    }

    setState(() {
      _resistencia = rCalculada;
      _longitudTotal = lTotal;
      _areaMalla = area;
    });

    // Intersticial para no premium
    AdService.instance.showInterstitial(context);
  }

  Future<void> _exportarPDF() async {
    if (_resistencia == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      final configName = _selectedConfigIndex == 0 
          ? 'Barra Única' 
          : (_selectedConfigIndex == 1 ? 'Delta (3 Barras)' : 'Malla Cuadrada Básica');
      
      final List<List<String>> datos = [
        ['Parámetro', 'Valor'],
        ['Configuración', configName],
        ['Resistividad Terreno (ρ)', '${_resistividadCtrl.text} Ohm-m'],
      ];

      if (_selectedConfigIndex == 0 || _selectedConfigIndex == 1) {
        datos.add(['Largo de Barra (L)', '${_largoBarraCtrl.text} m']);
        datos.add(['Diámetro de Barra (d)', _diametroBarra]);
      } else {
        datos.add(['Largo Malla', '${_largoMallaCtrl.text} m']);
        datos.add(['Ancho Malla', '${_anchoMallaCtrl.text} m']);
        datos.add(['Conductores X (nx)', _nxCtrl.text]);
        datos.add(['Conductores Y (ny)', _nyCtrl.text]);
        datos.add(['Profundidad (h)', '${_profundidadCtrl.text} m']);
      }

      await PdfGenerator.generateGenericReport(
        titulo: 'Cálculo de Puesta a Tierra',
        datosEntrada: datos,
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Resistencia Equivalente (R_p)', '${_resistencia!.toStringAsFixed(2)} Ohm'],
          ['Longitud de Conductor', '${_longitudTotal!.toStringAsFixed(1)} m'],
          if (_selectedConfigIndex == 2) ['Área de Malla', '${_areaMalla!.toStringAsFixed(1)} m²'],
        ],
        formula: _selectedConfigIndex == 0 
            ? 'Dwight: Rp = (ρ / 2πL) · [ln(4L/r) - 1]' 
            : (_selectedConfigIndex == 1 ? 'Delta: R_delta = (R_barra / 3) · 1.15' : 'Laurent: Rp = ρ / (4R_equiv) + ρ / L_total'),
      );
    });
  }

  void _limpiar() {
    setState(() {
      _resistencia = null;
      _longitudTotal = null;
      _areaMalla = null;
      _selectedConfigIndex = 0;
      _resistividadCtrl.text = '100';
      _largoBarraCtrl.text = '2.4';
      _diametroBarra = '5/8"';
      _largoMallaCtrl.text = '3.0';
      _anchoMallaCtrl.text = '3.0';
      _nxCtrl.text = '3';
      _nyCtrl.text = '3';
      _profundidadCtrl.text = '0.6';
    });
  }

  void _compartir() {
    if (_resistencia == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final configName = _selectedConfigIndex == 0 
        ? 'Barra Única' 
        : (_selectedConfigIndex == 1 ? 'Delta (3 Barras)' : 'Malla Cuadrada Básica');
    
    final reporte = '''
⚡ *NOM ELÉCTRICA MX*
🛠️ *Cálculo:* Puesta a Tierra (R_p)
📅 *Fecha:* $fecha

📥 *DATOS INGRESADOS:*
   • Configuración: $configName
   • Resistividad (ρ): ${_resistividadCtrl.text} Ω·m
   ${_selectedConfigIndex == 2 
       ? '• Largo: ${_largoMallaCtrl.text}m x Ancho: ${_anchoMallaCtrl.text}m\n   • Conductores: ${_nxCtrl.text} en X / ${_nyCtrl.text} en Y'
       : '• Largo Barra: ${_largoBarraCtrl.text}m / Diámetro: $_diametroBarra'}

📊 *RESULTADOS:*
   ➤ *Resistencia Equivalente: ${_resistencia!.toStringAsFixed(2)} Ω*
   ➤ Longitud total: ${_longitudTotal!.toStringAsFixed(1)} m

⚠️ *ALERTA NOM 250:* Este valor es una estimación matemática teórica. Toda puesta a tierra debe ser validada en terreno con telurómetro certificado antes de la verificación ante la UVIE (Art. 250-56: electrodo único ≤ 25 Ω).
——————————————————————————————
📚 *Referencia:* NOM-001-SEDE — Art. 250 (Puesta a Tierra)
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
        title: Text("Puesta a Tierra (NOM 250)", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17)),
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
                      _headerInfo(b),
                      const SizedBox(height: 24),
                      
                      // Config selector
                      _buildConfigSelector(b),
                      const SizedBox(height: 24),

                      _buildInputCard(b),
                      const SizedBox(height: 32),
                      _buildCalculateButton(b),
                      if (_resistencia != null) ...[
                        const SizedBox(height: 32),
                        _buildResultsCard(b),
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

  Widget _headerInfo(Brightness b) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF10B981).withAlpha(20), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF10B981).withAlpha(50))),
    child: Row(children: [
      const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 24),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          "Cálculo interactivo de resistencia teórica de puesta a tierra (R_p) según metodologías de Dwight y Laurent bajo las normas RIC.",
          style: TextStyle(fontSize: 11, color: DesignTokens.getTextPrimary(b).withAlpha(200)),
        ),
      ),
    ]),
  );

  Widget _buildConfigSelector(Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        "CONFIGURACIÓN DE ELECTRODO",
        style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _configOption('1 Barra', 0, b),
          const SizedBox(width: 8),
          _configOption('Delta (3B)', 1, b),
          const SizedBox(width: 8),
          _configOption('Malla Cuad.', 2, b),
        ],
      )
    ],
  );

  Widget _configOption(String label, int index, Brightness b) => Expanded(
    child: GestureDetector(
      onTap: () {
        setState(() {
          _selectedConfigIndex = index;
          _resistencia = null; // Reset results
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _selectedConfigIndex == index 
              ? const Color(0xFF10B981).withAlpha(30)
              : DesignTokens.getCardBackground(b),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedConfigIndex == index ? const Color(0xFF10B981) : DesignTokens.getBorderColor(b),
            width: _selectedConfigIndex == index ? 2 : 1,
          )
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: _selectedConfigIndex == index ? const Color(0xFF10B981) : DesignTokens.getTextPrimary(b),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );

  Widget _buildInputCard(Brightness b) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(20), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("PARÁMETROS DEL TERRENO"),
        const SizedBox(height: 16),
        _textField(_resistividadCtrl, "Resistividad Suelo (ρ)", "Ej: 100", "Ω·m", Icons.landscape_rounded, b,
            help: 'Resistencia específica del suelo al paso de la corriente en Ohm-metro.'),
        const SizedBox(height: 24),

        _sectionTitle("DIMENSIONES Y GEOMETRÍA"),
        const SizedBox(height: 16),

        if (_selectedConfigIndex == 0 || _selectedConfigIndex == 1) ...[
          // Controles de barra única o Delta
          Row(
            children: [
              Expanded(
                child: _textField(_largoBarraCtrl, "Largo de Barra (L)", "Ej: 2.4", "m", Icons.straighten_rounded, b,
                    help: 'Largo comercial de la barra enterrada verticalmente en metros.'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _dropdown("Diámetro Barra", _diametroBarra, _barraDiametrosMm.keys.toList(), (v) {
                  setState(() {
                    _diametroBarra = v!;
                    _resistencia = null;
                  });
                }, b),
              )
            ],
          )
        ] else ...[
          // Malla cuadrada básica
          Row(
            children: [
              Expanded(
                child: _textField(_largoMallaCtrl, "Largo Malla", "Ej: 3.0", "m", Icons.straighten_rounded, b,
                    help: 'Longitud del lado X de la cuadrícula.'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(_anchoMallaCtrl, "Ancho Malla", "Ej: 3.0", "m", Icons.straighten_rounded, b,
                    help: 'Longitud del lado Y de la cuadrícula.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _textField(_nxCtrl, "N° Conductores X", "Ej: 3", "", Icons.grid_3x3_rounded, b,
                    help: 'Cantidad de conductores paralelos a lo largo de X.'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _textField(_nyCtrl, "N° Conductores Y", "Ej: 3", "", Icons.grid_3x3_rounded, b,
                    help: 'Cantidad de conductores paralelos a lo largo de Y.'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _textField(_profundidadCtrl, "Profundidad (h)", "Ej: 0.6", "m", Icons.south_rounded, b,
              help: 'Profundidad de enterramiento del reticulado (estándar 0.6 m).'),
        ],
      ],
    ),
  );

  Widget _sectionTitle(String title) => Row(children: [
    Container(width: 4, height: 14, decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: Color(0xFF10B981))),
  ]);

  Widget _textField(TextEditingController ctrl, String label, String hint, String unit, IconData icon, Brightness b, {String? help}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
        if (help != null) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _showHelpDialog(context, label, help),
            child: Icon(Icons.info_outline_rounded, color: const Color(0xFF10B981).withAlpha(150), size: 12),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: const Color(0xFF10B981)),
          suffixText: unit,
          suffixStyle: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
          hintText: hint,
          filled: true,
          fillColor: DesignTokens.getBackground(b),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return "Requerido";
          final n = double.tryParse(v.replaceAll(',', '.'));
          if (n == null || n <= 0) return "Debe ser > 0";
          return null;
        },
      ),
    ],
  );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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

  void _showHelpDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: DesignTokens.getSurface(Theme.of(context).brightness),
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF10B981)),
          const SizedBox(width: 10),
          Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildCalculateButton(Brightness b) => CalculatorButtonsPanel(
        onCalculate: _calcular,
        onReset: _limpiar,
        onShare: _resistencia != null ? _compartir : null,
        onExportPdf: _resistencia != null ? _exportarPDF : null,
        showResults: _resistencia != null,
        mainColor: const Color(0xFF10B981),
        calculateLabel: 'PROYECTAR RESISTENCIA',
      );

  Widget _buildResultsCard(Brightness b) {
    final bool esBaja = _resistencia! < 25.0; // NOM 250-56: electrodo unico debe ser <= 25 Ohm (si excede, agregar electrodo)
    final Color resColor = esBaja ? const Color(0xFF00FF88) : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withAlpha(100), width: 1.5),
      ),
      child: Column(
        children: [
          const Text("RESISTENCIA DE TIERRA ESTIMADA (R_p)", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(_resistencia!.toStringAsFixed(2), style: TextStyle(color: resColor, fontSize: 48, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text("Ω", style: TextStyle(color: resColor, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 24),
          _detailRow("Longitud total electrodo", "${_longitudTotal!.toStringAsFixed(1)} m", b),
          if (_selectedConfigIndex == 2) ...[
            const SizedBox(height: 8),
            _detailRow("Área de la malla", "${_areaMalla!.toStringAsFixed(1)} m²", b),
          ],
          const SizedBox(height: 24),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _normativeTip(b),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val, Brightness b) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13)),
      Text(val, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 14)),
    ],
  );

  Widget _normativeTip(Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: const [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 16),
          SizedBox(width: 8),
          Text("ALERTA NORMATIVA NOM ART. 250", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        "Este valor es una estimación matemática teórica. Toda puesta a tierra debe ser validada obligatoriamente en terreno mediante un telurómetro certificado antes de tramitar el TE1 frente a la SEC.",
        style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, height: 1.4),
      ),
    ],
  );

  Widget _buildFormulaCard(Brightness b) {
    const kFormula = Color(0xFF818CF8);
    String fLabel = 'DWIGHT';
    String fEquation = 'R = (ρ / 2πL) · [ln(4L/r) - 1]';
    if (_selectedConfigIndex == 1) {
      fLabel = 'CONFIGURACIÓN EN DELTA';
      fEquation = 'Rp = (R_barra / 3) · 1.15';
    } else if (_selectedConfigIndex == 2) {
      fLabel = 'FÓRMULA DE LAURENT';
      fEquation = 'Rp = ρ / (4R_equiv) + ρ / L_total';
    }

    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          Text(fLabel, style: const TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('NOM Art. 250', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text(fEquation, style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('Rp', 'Resistencia teórica equivalente', 'Ω', kFormula, b),
        _legendRow('ρ (rho)', 'Resistividad del suelo', 'Ω·m', kFormula, b),
        _legendRow('L', 'Longitud del conductor/barra', 'm', kFormula, b),
        if (_selectedConfigIndex == 0 || _selectedConfigIndex == 1) _legendRow('r', 'Radio físico de la barra', 'm', kFormula, b),
        if (_selectedConfigIndex == 2) ...[
          _legendRow('R_equiv', 'Radio equivalente del área', 'm', kFormula, b),
          _legendRow('L_total', 'Longitud total de cables', 'm', kFormula, b),
        ]
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

