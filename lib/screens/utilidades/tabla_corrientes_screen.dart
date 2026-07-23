import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/data/nom310_ampacidad_data.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kElectricCyan = Color(0xFF00E5FF);

/// Tabla interactiva de ampacidades NOM-001-SEDE (Tabla 310-15(b)(16)):
/// conductores de cobre en tubería conduit, máx. 3 portadores, con las tres
/// columnas de aislamiento (60/75/90 °C) y corrección en vivo por temperatura
/// ambiente usando la Tabla 310-15(b)(2)(a) — cada columna con su factor.
class TablaCorrientesScreen extends StatefulWidget {
  const TablaCorrientesScreen({super.key});

  @override
  State<TablaCorrientesScreen> createState() => _TablaCorrientesScreenState();
}

class _TablaCorrientesScreenState extends State<TablaCorrientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _tempAmbiente = 30.0; // corrección en vivo por temperatura ambiente

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;

    final filteredList = Nom310AmpacidadData.calibres.where((item) {
      final awg = (item['awg'] as String).toLowerCase();
      return awg.contains(_searchQuery.toLowerCase());
    }).toList();

    final double ft60 = Nom310AmpacidadData.factorTemperatura('60', _tempAmbiente);
    final double ft75 = Nom310AmpacidadData.factorTemperatura('75', _tempAmbiente);
    final double ft90 = Nom310AmpacidadData.factorTemperatura('90', _tempAmbiente);

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(Icons.table_chart_rounded, color: _kElectricCyan, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AMPACIDADES NOM',
                    style: DesignTokens.getDisplay(b, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tabla 310-15(b)(16) - Cobre en tubería conduit',
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(b),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!isPremium) ...[
            AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
          ],
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador Rápido de Calibre
                  TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar calibre (ej. 12, 1/0, 250)...',
                      hintStyle: TextStyle(color: DesignTokens.getTextSecondary(b).withAlpha(150), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: DesignTokens.getTextSecondary(b), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded, color: DesignTokens.getTextSecondary(b), size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: DesignTokens.getCardBackground(b),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DesignTokens.getBorderColor(b)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DesignTokens.getBorderColor(b)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kElectricCyan, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Corrección en vivo por temperatura ambiente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            const Icon(Icons.thermostat_rounded, color: _kElectricCyan, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Tª ambiente: ${_tempAmbiente.toInt()}°C',
                              style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _tempAmbiente > 30 ? Colors.orange.withAlpha(30) : _kElectricCyan.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _tempAmbiente > 30
                                    ? 'f_t: ${ft60.toStringAsFixed(2)} / ${ft75.toStringAsFixed(2)} / ${ft90.toStringAsFixed(2)}'
                                    : 'Tabla base (f_t = 1.00)',
                                style: TextStyle(
                                  color: _tempAmbiente > 30 ? Colors.orange : _kElectricCyan,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: _tempAmbiente,
                          min: 30,
                          max: 60,
                          divisions: 6,
                          activeColor: _kElectricCyan,
                          inactiveColor: DesignTokens.getBackground(b),
                          onChanged: (v) => setState(() => _tempAmbiente = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tabla de Resultados
                  Text(
                    _tempAmbiente <= 30
                        ? 'CONDUCTORES DE COBRE (Tª ambiente 30°C)'
                        : 'VALORES CORREGIDOS A ${_tempAmbiente.toInt()}°C AMBIENTE',
                    style: TextStyle(
                      color: _tempAmbiente <= 30 ? _kElectricCyan : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (filteredList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'No se encontraron calibres para "$_searchQuery"',
                          style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 14),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: DesignTokens.getCardBackground(b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DesignTokens.getBorderColor(b)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1.5), // Calibre
                            1: FlexColumnWidth(1.0), // 60°C
                            2: FlexColumnWidth(1.0), // 75°C
                            3: FlexColumnWidth(1.0), // 90°C
                          },
                          children: [
                            // Cabecera de la Tabla
                            TableRow(
                              decoration: BoxDecoration(
                                color: _kElectricCyan.withAlpha(20),
                                border: Border(
                                  bottom: BorderSide(color: DesignTokens.getBorderColor(b)),
                                ),
                              ),
                              children: [
                                _buildTableHeaderCell('Calibre', b),
                                _buildTableHeaderCell('60°C\nTW', b),
                                _buildTableHeaderCell('75°C\nTHW', b),
                                _buildTableHeaderCell('90°C\nTHHN', b),
                              ],
                            ),
                            // Filas de Datos (corregidas por f_t si Tª > 30°C)
                            ...filteredList.map((item) {
                              final isEven = filteredList.indexOf(item) % 2 == 0;
                              final String awg = item['awg'] as String;
                              final double mm2 = (item['mm2'] as num).toDouble();
                              String celda(String aisl, double ft) {
                                if (ft <= 0) return '—';
                                final v = Nom310AmpacidadData.iBase[aisl]![awg]! * ft;
                                return '${v.round()} A';
                              }

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven ? Colors.transparent : DesignTokens.getSurface(b).withAlpha(100),
                                ),
                                children: [
                                  _buildCalibreCell(awg, '${mm2.toStringAsFixed(mm2 < 100 ? 2 : 0)} mm²', b),
                                  _buildTableCell(celda('60', ft60), b),
                                  _buildTableCell(celda('75', ft75), b),
                                  _buildTableCell(celda('90', ft90), b),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Nota Técnica Informativa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getSurface(b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kElectricCyan.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: _kElectricCyan, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'NOTA TÉCNICA (NOM-001-SEDE, ART. 310)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kElectricCyan,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Valores de la Tabla 310-15(b)(16): cobre, no más de 3 conductores portadores de corriente en tubería conduit, cable o directamente enterrados, a 30°C de temperatura ambiente.\n'
                          '• Con más de 3 conductores portadores en la misma canalización aplica además el factor de ajuste de la Tabla 310-15(b)(3)(a) — usa la calculadora de Ampacidad.\n'
                          '• Aislamientos típicos: 60°C (TW), 75°C (THW, THWN), 90°C (THHW, THHN, XHHW-2).\n'
                          '• Ojo: la columna de 90°C solo puede usarse si las terminales del equipo lo permiten; en la práctica la mayoría de las terminales están certificadas a 75°C (Art. 110-14(c)).\n'
                          '• Valores de referencia: confirmar contra el texto oficial del DOF antes de proyectos formales.',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(b),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Padding inferior extra para evitar colisiones con el banner principal del Dashboard
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, Brightness b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          color: DesignTokens.getTextPrimary(b),
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Celda de calibre: etiqueta AWG/kcmil + área mm² debajo.
  Widget _buildCalibreCell(String awg, String mm2, Brightness b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Column(
        children: [
          Text(
            awg,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: _kElectricCyan,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            mm2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.getTextSecondary(b).withAlpha(160),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, Brightness b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: DesignTokens.getTextPrimary(b),
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
