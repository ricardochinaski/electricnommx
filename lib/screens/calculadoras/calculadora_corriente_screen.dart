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

enum TipoCorriente { continua, monofasica, bifasica, trifasica }

enum EntradaModo {
  tensionPotencia,
  tensionImpedancia,
  tensionResistencia,
  potenciaImpedancia,
  potenciaResistencia,
}

class CalculadoraCorrientePage extends StatefulWidget {
  const CalculadoraCorrientePage({super.key});
  @override
  State<CalculadoraCorrientePage> createState() =>
      _CalculadoraCorrientePageState();
}

class _CalculadoraCorrientePageState extends State<CalculadoraCorrientePage> {
  final _formKey = GlobalKey<FormState>();
  TipoCorriente _tipo = TipoCorriente.monofasica;
  EntradaModo _entrada = EntradaModo.tensionPotencia;
  final _tensionCtrl = TextEditingController();
  final _potenciaCtrl = TextEditingController();
  final _impedanciaCtrl = TextEditingController();
  final _resistenciaCtrl = TextEditingController();
  final _cosPhiCtrl = TextEditingController(text: '0.93');
  String _potenciaUnit = 'W';
  double? _resultado;

  @override
  void dispose() {
    for (var c in [
      _tensionCtrl,
      _potenciaCtrl,
      _impedanciaCtrl,
      _resistenciaCtrl,
      _cosPhiCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _calcular() {
    if (_formKey.currentState!.validate()) {
      final V = double.tryParse(_tensionCtrl.text.replaceAll(',', '.')) ?? 0;
      double P = double.tryParse(_potenciaCtrl.text.replaceAll(',', '.')) ?? 0;
      if (_potenciaUnit == 'kW') {
        P *= 1000;
      }
      if (_potenciaUnit == 'HP') {
        P *= 745.7;
      }
      final Z = double.tryParse(_impedanciaCtrl.text.replaceAll(',', '.')) ?? 0;
      final R =
          double.tryParse(_resistenciaCtrl.text.replaceAll(',', '.')) ?? 0;
      final cosPhi =
          double.tryParse(_cosPhiCtrl.text.replaceAll(',', '.')) ?? 1.0;
      double res = 0;
      switch (_entrada) {
        case EntradaModo.tensionPotencia:
          if (V == 0) {
            break;
          }
          if (_tipo == TipoCorriente.trifasica) {
            res = P / (V * 1.732 * cosPhi);
          } else if (_tipo != TipoCorriente.continua) {
            res = P / (V * cosPhi);
          } else {
            res = P / V;
          }
          break;
        case EntradaModo.tensionImpedancia:
          if (Z != 0) {
            res = V / Z;
          }
          break;
        case EntradaModo.tensionResistencia:
          if (R != 0) {
            res = V / R;
          }
          break;
        case EntradaModo.potenciaImpedancia:
          if (Z != 0) {
            res = math.sqrt(P / Z);
          }
          break;
        case EntradaModo.potenciaResistencia:
          if (R != 0) {
            res = math.sqrt(P / R);
          }
          break;
      }
      setState(() => _resultado = res);

      // Mostrar intersticial al calcular (solo usuarios gratuitos)
      AdService.instance.showInterstitial(context);
    }
  }

  String _formatValue(double val) {
    if (val == val.truncateToDouble()) return val.toInt().toString();
    return val
        .toStringAsFixed(3)
        .replaceAll(RegExp(r'0*$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _limpiar() {
    _tensionCtrl.clear();
    _potenciaCtrl.clear();
    _impedanciaCtrl.clear();
    _resistenciaCtrl.clear();
    _cosPhiCtrl.text = '0.93';
    setState(() => _resultado = null);
  }

  void _compartir() {
    if (_resultado == null) return;
    final fecha = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    SharePlus.instance.share(
      ShareParams(
        text:
            '📌 *REPORTE ELÉCTRICO — NOM Eléctrica MX*\n'
            '🛠️ Calculadora de Corriente (I)\n📅 $fecha\n\n'
            '• Tipo: ${_tipo.name}  • Modo: ${_entrada.name}\n\n'
            '➤ *I = ${_formatValue(_resultado!)} A*\n\n'
            'Referencia: Ley de Ohm / NOM-001-SEDE\n_NOM Eléctrica MX_',
      ),
    );
  }

  Future<void> _exportarPDF() async {
    if (_resultado == null) return;

    await checkPremiumAndExecute(context, 'Exportación PDF', () async {
      final tipoLabels = {
        TipoCorriente.continua: 'Continua (DC)',
        TipoCorriente.monofasica: 'Monofásica',
        TipoCorriente.bifasica: 'Bifásica',
        TipoCorriente.trifasica: 'Trifásica',
      };
      final entradaLabels = {
        EntradaModo.tensionPotencia: 'Tensión / Potencia',
        EntradaModo.tensionImpedancia: 'Tensión / Impedancia',
        EntradaModo.tensionResistencia: 'Tensión / Resistencia',
        EntradaModo.potenciaImpedancia: 'Potencia / Impedancia',
        EntradaModo.potenciaResistencia: 'Potencia / Resistencia',
      };

      List<List<String>> datos = [
        ['Parámetro', 'Valor'],
      ];
      if (_tensionCtrl.text.isNotEmpty) {
        datos.add(['Tensión (V)', '${_tensionCtrl.text} V']);
      }
      if (_potenciaCtrl.text.isNotEmpty) {
        datos.add(['Potencia (P)', '${_potenciaCtrl.text} W']);
      }
      if (_impedanciaCtrl.text.isNotEmpty) {
        datos.add(['Impedancia (Z)', '${_impedanciaCtrl.text} Ohm']);
      }
      if (_resistenciaCtrl.text.isNotEmpty) {
        datos.add(['Resistencia (R)', '${_resistenciaCtrl.text} Ohm']);
      }
      if (_cosPhiCtrl.text.isNotEmpty && _tipo != TipoCorriente.continua) {
        datos.add(['Factor Potencia', _cosPhiCtrl.text]);
      }
      datos.add(['Tipo de Corriente', tipoLabels[_tipo]!]);
      datos.add(['Modo de Entrada', entradaLabels[_entrada]!]);

      await PdfGenerator.generateGenericReport(
        titulo: 'Cálculo de Corriente (I)',
        datosEntrada: datos,
        resultados: [
          ['Indicador', 'Valor Obtenido'],
          ['Corriente Resultante', '${_formatValue(_resultado!)} A'],
        ],
        formula: _formulaActual,
      );
    });
  }

  String get _formulaActual {
    switch (_entrada) {
      case EntradaModo.tensionPotencia:
        if (_tipo == TipoCorriente.trifasica) {
          return 'I = P / (V · √3 · cos φ)';
        }
        if (_tipo != TipoCorriente.continua) {
          return 'I = P / (V · cos φ)';
        }
        return 'I = P / V';
      case EntradaModo.tensionImpedancia:
        return 'I = V / Z';
      case EntradaModo.tensionResistencia:
        return 'I = V / R';
      case EntradaModo.potenciaImpedancia:
        return 'I = √(P / Z)';
      case EntradaModo.potenciaResistencia:
        return 'I = √(P / R)';
    }
  }

  Widget _sectionLabel(Brightness b, IconData icon, String txt) => Row(
    children: [
      Icon(icon, color: _kElectric, size: 16),
      const SizedBox(width: 8),
      Text(
        txt,
        style: const TextStyle(
          color: _kElectric,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    ],
  );

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    String hint,
    String unit,
    IconData icon,
    Brightness b, {
    String? help,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.getBorderColor(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kElectric, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(b),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (help != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => _showHelpDialog(context, label, help),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _kElectric.withAlpha(150),
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
              color: DesignTokens.getTextPrimary(b),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              hintText: hint,
              hintStyle: TextStyle(
                color: DesignTokens.getTextSecondary(b).withAlpha(100),
                fontSize: 14,
              ),
              suffixText: unit,
              suffixStyle: const TextStyle(
                color: _kElectric,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              border: InputBorder.none,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Requerido';
              }
              if (double.tryParse(v.replaceAll(',', '.')) == null) {
                return 'Inválido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: DesignTokens.getSurface(Theme.of(context).brightness),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: _kElectric),
            const SizedBox(width: 10),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: DesignTokens.getTextPrimary(
              Theme.of(context).brightness,
            ).withAlpha(200),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(color: _kElectric, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerInputField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon,
    Brightness b, {
    String? help,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(b),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DesignTokens.getBorderColor(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _kElectric, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(b),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (help != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => _showHelpDialog(context, label, help),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: _kElectric.withAlpha(150),
                    size: 14,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(
                    color: DesignTokens.getTextPrimary(b),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: DesignTokens.getTextSecondary(b).withAlpha(100),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Requerido';
                    }
                    if (double.tryParse(v.replaceAll(',', '.')) == null) {
                      return 'Inválido';
                    }
                    return null;
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kElectric.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _potenciaUnit,
                    isDense: true,
                    dropdownColor: DesignTokens.getSurface(b),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      color: _kElectric,
                      size: 20,
                    ),
                    items: ['W', 'kW', 'HP']
                        .map(
                          (u) => DropdownMenuItem(
                            value: u,
                            child: Text(
                              u,
                              style: const TextStyle(
                                color: _kElectric,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _potenciaUnit = v;
                          _resultado = null;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInputWidgets(Brightness b) {
    final list = <Widget>[];
    final showTension = [
      EntradaModo.tensionPotencia,
      EntradaModo.tensionImpedancia,
      EntradaModo.tensionResistencia,
    ].contains(_entrada);
    final showPotencia = [
      EntradaModo.tensionPotencia,
      EntradaModo.potenciaImpedancia,
      EntradaModo.potenciaResistencia,
    ].contains(_entrada);
    final showImpedancia = [
      EntradaModo.tensionImpedancia,
      EntradaModo.potenciaImpedancia,
    ].contains(_entrada);
    final showResistencia = [
      EntradaModo.tensionResistencia,
      EntradaModo.potenciaResistencia,
    ].contains(_entrada);
    final showCosPhi =
        _tipo != TipoCorriente.continua &&
        _entrada == EntradaModo.tensionPotencia;
    if (showTension) {
      list.add(
        _inputField(
          _tensionCtrl,
          'Tensión (V)',
          'Ej: 127',
          'V',
          Icons.bolt_rounded,
          b,
          help:
              'Diferencia de potencial entre dos puntos del circuito. Se mide en Voltios.',
        ),
      );
    }
    if (showPotencia) {
      list.add(
        _powerInputField(
          _potenciaCtrl,
          'Potencia (P)',
          'Ej: 2200',
          Icons.power_rounded,
          b,
          help:
              'Tasa a la que se consume la energía eléctrica. Se mide en Watts (W).',
        ),
      );
    }
    if (showImpedancia) {
      list.add(
        _inputField(
          _impedanciaCtrl,
          'Impedancia (Z)',
          'Ej: 10',
          'Ω',
          Icons.waves_rounded,
          b,
          help:
              'Oposición total al flujo de corriente en circuitos de AC (Resistencia + Reactancia).',
        ),
      );
    }
    if (showResistencia) {
      list.add(
        _inputField(
          _resistenciaCtrl,
          'Resistencia (R)',
          'Ej: 10',
          'Ω',
          Icons.straighten_rounded,
          b,
          help:
              'Propiedad de un material de oponerse al paso de electrones. Se mide en Ohmios.',
        ),
      );
    }
    if (showCosPhi) {
      list.add(
        _inputField(
          _cosPhiCtrl,
          'Factor Potencia (cos φ)',
          'Ej: 0.93',
          'f.p',
          Icons.timeline_rounded,
          b,
          help:
              'Indica qué tan eficientemente se utiliza la energía eléctrica.',
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final inputs = _buildInputWidgets(b);
    final tipoLabels = {
      TipoCorriente.continua: 'Continua (DC)',
      TipoCorriente.monofasica: 'Monofásica',
      TipoCorriente.bifasica: 'Bifásica',
      TipoCorriente.trifasica: 'Trifásica',
    };
    final entradaLabels = {
      EntradaModo.tensionPotencia: 'Tensión / Potencia',
      EntradaModo.tensionImpedancia: 'Tensión / Impedancia',
      EntradaModo.tensionResistencia: 'Tensión / Resistencia',
      EntradaModo.potenciaImpedancia: 'Potencia / Impedancia',
      EntradaModo.potenciaResistencia: 'Potencia / Resistencia',
    };

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(
              Icons.electric_meter_rounded,
              color: _kElectric,
              size: 22,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CALCULADORA DE CORRIENTE',
                  style: DesignTokens.getDisplay(b, fontSize: 14),
                ),
                Text(
                  'Intensidad (I) en Amperes',
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(b),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
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
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [DesignTokens.getSurface(b), DesignTokens.getBackground(b)],
                ),
              ),
              child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo de corriente
                _sectionLabel(
                  b,
                  Icons.electrical_services_rounded,
                  'TIPO DE CORRIENTE',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TipoCorriente.values.map((t) {
                    final sel = _tipo == t;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _tipo = t;
                        _resultado = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? _kElectric
                              : DesignTokens.getCardBackground(b),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? _kElectric
                                : DesignTokens.getBorderColor(b),
                          ),
                        ),
                        child: Text(
                          tipoLabels[t]!,
                          style: TextStyle(
                            color: sel
                                ? Colors.black
                                : DesignTokens.getTextPrimary(b),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Modo de entrada
                _sectionLabel(b, Icons.input_rounded, 'DATOS DE ENTRADA'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: DesignTokens.getCardBackground(b),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DesignTokens.getBorderColor(b)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<EntradaModo>(
                      value: _entrada,
                      isExpanded: true,
                      dropdownColor: DesignTokens.getSurface(b),
                      icon: const Icon(
                        Icons.expand_more_rounded,
                        color: _kElectric,
                      ),
                      style: TextStyle(
                        color: DesignTokens.getTextPrimary(b),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      items: EntradaModo.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                entradaLabels[e]!,
                                style: TextStyle(
                                  color: DesignTokens.getTextPrimary(b),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _entrada = v;
                            _resultado = null;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Inputs dinámicos
                for (int i = 0; i < inputs.length; i += 2) ...[
                  Row(
                    children: [
                      Expanded(child: inputs[i]),
                      if (i + 1 < inputs.length) ...[
                        const SizedBox(width: 12),
                        Expanded(child: inputs[i + 1]),
                      ] else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  if (i + 2 < inputs.length) const SizedBox(height: 12),
                ],
                const SizedBox(height: 24),
                // Botones — "CALCULADORA" según instrucciones del usuario
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(b),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: DesignTokens.getBorderColor(b)),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.electric_meter_rounded,
                          color: DesignTokens.getTextSecondary(b).withAlpha(80),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Selecciona tipo, modo e ingresa datos',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(b),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kElectric.withAlpha(12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _kElectric.withAlpha(120),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kElectric.withAlpha(40),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.electric_meter_rounded,
                              color: _kElectric,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'CORRIENTE RESULTANTE (I)',
                              style: TextStyle(
                                color: DesignTokens.getTextSecondary(b),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${_formatValue(_resultado!)} A',
                          style: GoogleFonts.outfit(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: _kElectric,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Amperios',
                          style: TextStyle(
                            color: _kElectric.withAlpha(150),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                // Fórmula integrada (sin pestaña)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DesignTokens.getCardBackground(b),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _kFormula.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.functions_rounded,
                            color: _kFormula,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'FÓRMULA ACTIVA',
                            style: TextStyle(
                              color: _kFormula,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _kFormula.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'NOM-001-SEDE',
                              style: TextStyle(
                                color: _kFormula,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          _formulaActual,
                          style: GoogleFonts.firaCode(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kFormula,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: DesignTokens.getBorderColor(b)),
                      const SizedBox(height: 10),
                      _legendRow('I', 'Corriente eléctrica', 'A', b),
                      _legendRow('P', 'Potencia activa', 'W', b),
                      _legendRow('V', 'Tensión de línea', 'V', b),
                      _legendRow('R', 'Resistencia del circuito', 'Ω', b),
                      _legendRow('Z', 'Impedancia del circuito', 'Ω', b),
                      _legendRow('cos φ', 'Factor de potencia', 'f.p', b),
                      _legendRow('√3', 'Factor trifásico ≈ 1.732', '—', b),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String sym, String desc, String unit, Brightness b) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(
                sym,
                style: GoogleFonts.firaCode(
                  fontSize: 12,
                  color: _kFormula,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                desc,
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(b),
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: DesignTokens.getTextPrimary(b),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}

