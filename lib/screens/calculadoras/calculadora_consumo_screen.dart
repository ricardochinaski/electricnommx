import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

const _kAccent = Color(0xFF10B981); // Verde para energía/costo

class CalculadoraConsumoScreen extends StatefulWidget {
  const CalculadoraConsumoScreen({super.key});

  @override
  State<CalculadoraConsumoScreen> createState() => _CalculadoraConsumoScreenState();
}

class _CalculadoraConsumoScreenState extends State<CalculadoraConsumoScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores
  final _potenciaCtrl = TextEditingController(text: '1000');
  final _horasCtrl = TextEditingController(text: '4');
  final _diasCtrl = TextEditingController(text: '30');
  final _precioKwhCtrl = TextEditingController(text: '1.5'); // Referencia CFE tarifa domestica excedente (MXN)
  final _consumoEtiquetaCtrl = TextEditingController();

  // Estados
  String _potenciaUnit = 'W';
  bool _modoEtiqueta = false; // false = por potencia y uso, true = etiqueta de eficiencia energética
  String _unidadEtiqueta = 'kWh/mes';
  String _claseEnergetica = 'A';

  // Clases de eficiencia (referencia UE); la etiqueta amarilla CONUEE de Mexico
  // declara consumo kWh/anio y % de ahorro - la clase es opcional aqui
  static const List<String> _clasesEnergeticas = ['A+++', 'A++', 'A+', 'A', 'B', 'C', 'D', 'E', 'F', 'G'];

  // Colores oficiales de las franjas de la etiqueta (verde → rojo)
  static const Map<String, Color> _colorClase = {
    'A+++': Color(0xFF00A651),
    'A++': Color(0xFF22B14C),
    'A+': Color(0xFF4CBB3C),
    'A': Color(0xFF8CC63F),
    'B': Color(0xFFB5D334),
    'C': Color(0xFFFFF200),
    'D': Color(0xFFFDB913),
    'E': Color(0xFFF7941D),
    'F': Color(0xFFF15A29),
    'G': Color(0xFFED1C24),
  };

  double? _kwhMensual;
  double? _costoMensual;
  double? _costoDiario;
  double? _costoAnual;

  static const String _kTarifaPrefKey = 'tarifa_kwh_mxn';

  // Aparatos electrodomesticos tipicos en Mexico: potencia (W) y horas de uso diario
  static const List<Map<String, dynamic>> _artefactos = [
    {'nombre': 'Refrigerador', 'w': 150, 'h': 8.0, 'icon': Icons.kitchen_rounded},
    {'nombre': 'Calentador de Agua Eléctrico', 'w': 1500, 'h': 3.0, 'icon': Icons.water_drop_rounded},
    {'nombre': 'Aire Acond. 9000BTU', 'w': 900, 'h': 6.0, 'icon': Icons.ac_unit_rounded},
    {'nombre': 'Calefactor Eléctrico', 'w': 2000, 'h': 5.0, 'icon': Icons.fireplace_rounded},
    {'nombre': 'Horno de Microondas', 'w': 1200, 'h': 0.5, 'icon': Icons.microwave_rounded},
    {'nombre': 'Lavadora', 'w': 500, 'h': 1.0, 'icon': Icons.local_laundry_service_rounded},
    {'nombre': 'TV LED', 'w': 100, 'h': 5.0, 'icon': Icons.tv_rounded},
    {'nombre': 'Foco LED', 'w': 9, 'h': 6.0, 'icon': Icons.lightbulb_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _cargarTarifaGuardada();
  }

  /// Restaura la última tarifa usada (persistida entre sesiones).
  Future<void> _cargarTarifaGuardada() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kTarifaPrefKey);
      if (saved != null && saved.isNotEmpty && mounted) {
        setState(() => _precioKwhCtrl.text = saved);
      }
    } catch (e) {
      debugPrint('[Consumo] Error cargando tarifa guardada: $e');
    }
  }

  Future<void> _guardarTarifa() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTarifaPrefKey, _precioKwhCtrl.text.trim());
    } catch (e) {
      debugPrint('[Consumo] Error guardando tarifa: $e');
    }
  }

  final _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  @override
  void dispose() {
    _potenciaCtrl.dispose();
    _horasCtrl.dispose();
    _diasCtrl.dispose();
    _precioKwhCtrl.dispose();
    _consumoEtiquetaCtrl.dispose();
    super.dispose();
  }

  String? _numericValidator(String? v) {
    if (v == null || v.isEmpty) return 'Requerido';
    final n = double.tryParse(v.replaceAll(',', '.'));
    if (n == null) return 'Número inválido';
    if (n <= 0) return 'Debe ser > 0';
    return null;
  }

  void _calcular() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    try {
      final double precio = double.parse(_precioKwhCtrl.text.replaceAll(',', '.'));

      final double kwhMes;
      final double costoDia;
      if (_modoEtiqueta) {
        // Consumo declarado en la etiqueta de eficiencia energética del artefacto
        final double consumo = double.parse(_consumoEtiquetaCtrl.text.replaceAll(',', '.'));
        kwhMes = _unidadEtiqueta == 'kWh/año' ? consumo / 12.0 : consumo;
        costoDia = (kwhMes * precio) / 30.0;
      } else {
        double P = double.parse(_potenciaCtrl.text.replaceAll(',', '.'));
        if (_potenciaUnit == 'W') P /= 1000; // Convertir a kW
        if (_potenciaUnit == 'HP') P *= 0.7457; // Convertir a kW

        final double horas = double.parse(_horasCtrl.text.replaceAll(',', '.'));
        final double dias = double.parse(_diasCtrl.text.replaceAll(',', '.'));
        kwhMes = P * horas * dias;
        costoDia = P * horas * precio;
      }

      setState(() {
        _kwhMensual = kwhMes;
        _costoMensual = kwhMes * precio;
        _costoDiario = costoDia;
        _costoAnual = kwhMes * precio * 12.0;
      });

      // Recordar la tarifa del usuario para próximas sesiones
      _guardarTarifa();

      // Mostrar intersticial al calcular (solo usuarios gratuitos)
      AdService.instance.showInterstitial(context);
    } catch (e) {
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
    setState(() {
      _potenciaCtrl.text = '1000';
      _horasCtrl.text = '4';
      _diasCtrl.text = '30';
      _precioKwhCtrl.text = '1.5';
      _consumoEtiquetaCtrl.clear();
      _potenciaUnit = 'W';
      _unidadEtiqueta = 'kWh/mes';
      _claseEnergetica = 'A';
      _kwhMensual = null;
      _costoMensual = null;
      _costoDiario = null;
      _costoAnual = null;
    });
  }

  void _compartir() {
    if (_costoMensual == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final String datos = _modoEtiqueta
        ? '''   • Consumo etiqueta: ${_consumoEtiquetaCtrl.text} $_unidadEtiqueta
   • Clase de eficiencia: $_claseEnergetica
   • Tarifa: \$${_precioKwhCtrl.text} /kWh'''
        : '''   • Potencia: ${_potenciaCtrl.text} $_potenciaUnit
   • Uso: ${_horasCtrl.text} h/día (${_diasCtrl.text} días/mes)
   • Tarifa: \$${_precioKwhCtrl.text} /kWh''';
    final reporte = '''
📌 *REPORTE DE CONSUMO — NOM Eléctrica MX*
——————————————————————————————
🛠️ *${_modoEtiqueta ? 'Estimación según Etiqueta de Eficiencia Energética' : 'Estimación Energética'}*
📅 *Fecha:* $fecha

📥 *DATOS:*
$datos

📊 *RESULTADOS ESTIMADOS:*
   ➤ Consumo Mensual: ${_kwhMensual!.toStringAsFixed(1)} kWh
   ➤ *Costo Mensual: ${_currencyFormat.format(_costoMensual)}*
   ➤ Costo Diario: ${_currencyFormat.format(_costoDiario)}
   ➤ Costo Anual: ${_currencyFormat.format(_costoAnual)}

——————————————————————————————
_Calculado con App NOM ELÉCTRICA MX_
''';
    SharePlus.instance.share(ShareParams(text: reporte));
  }

  Future<void> _exportarPDF() async {
    if (_costoMensual == null) return;
    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      await PdfGenerator.generateGenericReport(
        titulo: _modoEtiqueta
            ? 'Consumo según Etiqueta de Eficiencia Energética'
            : 'Estimación de Consumo Eléctrico',
        datosEntrada: _modoEtiqueta
            ? [
                ['Parámetro', 'Valor'],
                ['Consumo declarado (etiqueta)', '${_consumoEtiquetaCtrl.text} $_unidadEtiqueta'],
                ['Clase de eficiencia', _claseEnergetica],
                ['Tarifa eléctrica', '\$${_precioKwhCtrl.text} por kWh'],
              ]
            : [
                ['Parámetro', 'Valor'],
                ['Potencia Equipo', '${_potenciaCtrl.text} $_potenciaUnit'],
                ['Tiempo Uso', '${_horasCtrl.text} horas/día'],
                ['Días al mes', '${_diasCtrl.text} días'],
                ['Tarifa eléctrica', '\$${_precioKwhCtrl.text} por kWh'],
              ],
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Energía Mensual', '${_kwhMensual!.toStringAsFixed(1)} kWh'],
          ['Costo Diario Estimado', _currencyFormat.format(_costoDiario)],
          ['Costo Mensual Estimado', _currencyFormat.format(_costoMensual)],
          ['Costo Anual Estimado', _currencyFormat.format(_costoAnual)],
        ],
        formula: _modoEtiqueta
            ? 'Costo = Consumo_mensual[kWh] * Precio_kWh'
            : 'Costo = (Potencia[kW] * Horas * Dias) * Precio_kWh',
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
          const Icon(Icons.monetization_on_rounded, color: _kAccent, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CONSUMO Y COSTO', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Estimación de gasto mensual', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
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
              _sectionLabel(b, Icons.tune_rounded, 'MÉTODO DE CÁLCULO'),
              const SizedBox(height: 12),
              Row(children: [
                _modeButton('POR POTENCIA Y USO', !_modoEtiqueta, () => setState(() { _modoEtiqueta = false; _costoMensual = null; }), b),
                const SizedBox(width: 12),
                _modeButton('ETIQUETA ENERGÉTICA', _modoEtiqueta, () => setState(() { _modoEtiqueta = true; _costoMensual = null; }), b),
              ]),
              const SizedBox(height: 24),
              if (_modoEtiqueta) ...[
                _sectionLabel(b, Icons.energy_savings_leaf_rounded, 'DATOS DE LA ETIQUETA (CONUEE)'),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _consumoEtiquetaField(b)),
                  const SizedBox(width: 12),
                  Expanded(child: _inputField(_precioKwhCtrl, 'Tarifa (\$)', 'Ej: 1.5', 'kWh', Icons.price_change_rounded, b, help: 'Costo de un kilowatt-hora en pesos (MXN) segun tu recibo CFE (tarifa 1, 1A-1F, DAC o PDBT).')),
                ]),
                const SizedBox(height: 16),
                _claseSelector(b),
              ] else ...[
                _sectionLabel(b, Icons.flash_on_rounded, 'DATOS DEL EQUIPO'),
                const SizedBox(height: 12),
                // Presets rápidos de artefactos típicos
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _artefactos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final a = _artefactos[i];
                      return GestureDetector(
                        onTap: () => setState(() {
                          _potenciaCtrl.text = '${a['w']}';
                          _horasCtrl.text = (a['h'] as double) == (a['h'] as double).truncateToDouble()
                              ? '${(a['h'] as double).toInt()}'
                              : '${a['h']}';
                          _diasCtrl.text = '30';
                          _potenciaUnit = 'W';
                          _costoMensual = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: _kAccent.withAlpha(18),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _kAccent.withAlpha(70)),
                          ),
                          child: Row(children: [
                            Icon(a['icon'] as IconData, color: _kAccent, size: 14),
                            const SizedBox(width: 6),
                            Text(a['nombre'] as String, style: const TextStyle(color: _kAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _powerInputField(_potenciaCtrl, 'Potencia', 'Ej: 1500', b, help: 'Potencia nominal del equipo eléctrico.')),
                  const SizedBox(width: 12),
                  Expanded(child: _inputField(_precioKwhCtrl, 'Tarifa (\$)', 'Ej: 1.5', 'kWh', Icons.price_change_rounded, b, help: 'Costo de un kilowatt-hora en pesos (MXN) segun tu recibo CFE (tarifa 1, 1A-1F, DAC o PDBT).')),
                ]),
                const SizedBox(height: 24),
                _sectionLabel(b, Icons.schedule_rounded, 'HÁBITOS DE USO'),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(child: _inputField(_horasCtrl, 'Horas/Día', 'Ej: 4', 'hrs', Icons.timer_rounded, b, help: 'Promedio de horas diarias que el equipo permanece encendido.')),
                  const SizedBox(width: 12),
                  Expanded(child: _inputField(_diasCtrl, 'Días/Mes', 'Ej: 30', 'días', Icons.calendar_month_rounded, b, help: 'Cantidad de días al mes que se utiliza el equipo.')),
                ]),
              ],
              const SizedBox(height: 24),
              CalculatorButtonsPanel(
                onCalculate: _calcular,
                onReset: _limpiar,
                onShare: _costoMensual != null ? _compartir : null,
                onExportPdf: _costoMensual != null ? _exportarPDF : null,
                showResults: _costoMensual != null,
                mainColor: _kAccent,
                calculateLabel: 'CALCULAR COSTO',
              ),
              const SizedBox(height: 20),
              if (_costoMensual != null) ...[
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
        child: Center(child: Text(txt, style: TextStyle(color: sel ? Colors.black : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 11))),
      ),
    ),
  );

  /// Campo de consumo declarado en la etiqueta, con selector kWh/mes ↔ kWh/año
  /// (la etiqueta amarilla CONUEE declara el consumo en kWh/año).
  Widget _consumoEtiquetaField(Brightness b) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.energy_savings_leaf_rounded, color: _kAccent, size: 14),
        const SizedBox(width: 6),
        Text('Consumo Etiqueta', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
        const Spacer(),
        GestureDetector(
          onTap: () => _showHelpDialog(context, 'Consumo Etiqueta',
              'Es el consumo de energía declarado en la etiqueta de eficiencia energética del artefacto. En México, la etiqueta amarilla CONUEE lo declara en kWh/año — selecciona la unidad que indique la etiqueta de tu aparato.'),
          child: Icon(Icons.info_outline_rounded, color: _kAccent.withAlpha(150), size: 14),
        ),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: TextFormField(
          controller: _consumoEtiquetaCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16),
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: 'Ej: 21.5', hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(100), fontSize: 14), border: InputBorder.none),
          validator: _numericValidator,
        )),
        Container(padding: const EdgeInsets.symmetric(horizontal: 8), decoration: BoxDecoration(color: _kAccent.withAlpha(25), borderRadius: BorderRadius.circular(8)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _unidadEtiqueta, isDense: true,
              dropdownColor: DesignTokens.getSurface(b),
              items: ['kWh/mes', 'kWh/año'].map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold, fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _unidadEtiqueta = v!),
            ),
          ),
        ),
      ]),
    ]),
  );

  /// Selector visual de clase de eficiencia con los colores de la etiqueta chilena.
  Widget _claseSelector(Brightness b) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(14), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Icon(Icons.speed_rounded, color: _kAccent, size: 14),
        const SizedBox(width: 6),
        Text('Clase de Eficiencia (según etiqueta)', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 10),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _clasesEnergeticas.map((c) {
          final sel = c == _claseEnergetica;
          final color = _colorClase[c]!;
          return GestureDetector(
            onTap: () => setState(() => _claseEnergetica = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? color : color.withAlpha(35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color, width: sel ? 2 : 1),
              ),
              child: Text(c, style: TextStyle(color: sel ? Colors.black : DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          );
        }).toList(),
      ),
    ]),
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
        validator: _numericValidator,
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
        Expanded(child: TextFormField(controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 16), decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 4), hintText: hint, border: InputBorder.none), validator: _numericValidator)),
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
      Text('COSTO MENSUAL ESTIMADO', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text(_currencyFormat.format(_costoMensual), style: GoogleFonts.outfit(fontSize: 52, fontWeight: FontWeight.w900, color: _kAccent)),
      const SizedBox(height: 24),
      _resultRow('Energía Mensual', '${_kwhMensual!.toStringAsFixed(1)} kWh', b),
      _resultRow('Costo Diario', _currencyFormat.format(_costoDiario), b),
      _resultRow('Costo Anual', _currencyFormat.format(_costoAnual), b),
      if (_modoEtiqueta) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: (_colorClase[_claseEnergetica] ?? _kAccent).withAlpha(30),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _colorClase[_claseEnergetica] ?? _kAccent),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.energy_savings_leaf_rounded, size: 16, color: _kAccent),
            const SizedBox(width: 8),
            Text('Clase de eficiencia: $_claseEnergetica', style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ),
      ],
      const SizedBox(height: 20),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: _kAccent.withAlpha(15), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [const Icon(Icons.info_outline_rounded, color: _kAccent, size: 14), const SizedBox(width: 8), Expanded(child: Text('Este es un valor referencial. La cuenta de la luz incluye cargos fijos y variaciones por tramos.', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)))])),
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
          const Text('CÁLCULO DE COSTO', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('ESTIMACIÓN', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text(_modoEtiqueta ? 'Costo = Consumo_mes · Tarifa' : 'Costo = (P_kW · h · d) · Tarifa', style: GoogleFonts.firaCode(fontSize: 18, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        if (_modoEtiqueta) ...[
          _legendRow('Consumo', 'Declarado en la etiqueta (si es kWh/año, se divide por 12)', 'kWh', kFormula, b),
          _legendRow('Tarifa', 'Precio por kWh', 'MXN', kFormula, b),
        ] else ...[
          _legendRow('P_kW', 'Potencia en Kilowatts', 'kW', kFormula, b),
          _legendRow('h', 'Horas de uso diario', 'hrs', kFormula, b),
          _legendRow('d', 'Días de uso al mes', 'días', kFormula, b),
          _legendRow('Tarifa', 'Precio por kWh', 'MXN', kFormula, b),
        ],
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

