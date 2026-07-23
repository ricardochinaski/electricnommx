import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kEmeraldGreen = Color(0xFF10B981);
const _kCopperColor = Color(0xFFD97706);

class CodigoColoresScreen extends StatefulWidget {
  const CodigoColoresScreen({super.key});

  @override
  State<CodigoColoresScreen> createState() => _CodigoColoresScreenState();
}

class _CodigoColoresScreenState extends State<CodigoColoresScreen> {
  int _selectedNormIndex = 0; // 0 = NOM-001-SEDE (México), 1 = Norma Europea/Internacional (IEC)

  // NOM-001-SEDE: el neutro (puesto a tierra) DEBE ser blanco o gris claro
  // (Art. 200-6) y la tierra de equipos verde, verde/amarillo o desnuda
  // (Art. 250-119). Las fases pueden ser de cualquier otro color; en la
  // práctica mexicana se usa negro/rojo/azul.
  final List<Map<String, dynamic>> _chileanColores = [
    {
      'name': 'Fase 1 (L1)',
      'color': Colors.black,
      'textColor': Colors.white,
      'borderColor': Colors.white24,
      'desc': 'Fase. Color libre (no blanco/gris/verde); en la práctica: Negro.',
      'code': 'L1'
    },
    {
      'name': 'Fase 2 (L2)',
      'color': Colors.red,
      'textColor': Colors.white,
      'desc': 'Fase. Color libre (no blanco/gris/verde); en la práctica: Rojo.',
      'code': 'L2'
    },
    {
      'name': 'Fase 3 (L3)',
      'color': Colors.blue,
      'textColor': Colors.white,
      'desc': 'Fase. Color libre (no blanco/gris/verde); en la práctica: Azul.',
      'code': 'L3'
    },
    {
      'name': 'Neutro (N)',
      'color': Colors.white,
      'textColor': Colors.black,
      'borderColor': Colors.black26,
      'desc': 'Conductor puesto a tierra. Blanco o gris claro obligatorio (Art. 200-6).',
      'code': 'N'
    },
    {
      'name': 'Tierra de Equipos (PE)',
      'color': Colors.green,
      'textColor': Colors.white,
      'desc': 'Puesta a tierra de equipos: verde, verde/amarillo o desnudo (Art. 250-119).',
      'code': 'PE',
      'striped': true // Efecto rayado verde/amarillo visual
    }
  ];

  final List<Map<String, dynamic>> _iecColores = [
    {
      'name': 'Fase L1',
      'color': const Color(0xFF78350F), // Café / Marrón
      'textColor': Colors.white,
      'desc': 'Fase 1 según norma internacional IEC 60446. Color Café.',
      'code': 'L1'
    },
    {
      'name': 'Fase L2',
      'color': Colors.black,
      'textColor': Colors.white,
      'borderColor': Colors.white24,
      'desc': 'Fase 2 según norma internacional IEC 60446. Color Negro.',
      'code': 'L2'
    },
    {
      'name': 'Fase L3',
      'color': const Color(0xFF6B7280), // Gris
      'textColor': Colors.white,
      'desc': 'Fase 3 según norma internacional IEC 60446. Color Gris.',
      'code': 'L3'
    },
    {
      'name': 'Neutro (N)',
      'color': Colors.blue,
      'textColor': Colors.white,
      'desc': 'Conductor Neutro en norma IEC. Color Celeste / Azul claro.',
      'code': 'N'
    },
    {
      'name': 'Tierra (PE)',
      'color': Colors.green,
      'textColor': Colors.white,
      'desc': 'Conductor de protección a tierra. Color Verde/Amarillo.',
      'code': 'PE',
      'striped': true
    }
  ];

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final currentList = _selectedNormIndex == 0 ? _chileanColores : _iecColores;

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(Icons.palette_rounded, color: _kEmeraldGreen, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CÓDIGO DE COLORES',
                    style: DesignTokens.getDisplay(b, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'NOM-001-SEDE (México) vs IEC',
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de Norma (Nacional vs Internacional)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: DesignTokens.getCardBackground(b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DesignTokens.getBorderColor(b)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNormToggleOption('México (NOM)', _selectedNormIndex == 0, () {
                            setState(() => _selectedNormIndex = 0);
                          }, b),
                          _buildNormToggleOption('Europeo (IEC 60446)', _selectedNormIndex == 1, () {
                            setState(() => _selectedNormIndex = 1);
                          }, b),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'CABLES Y CONDUCTORES',
                    style: TextStyle(
                      color: _kEmeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Barras de conductores animadas/estilizadas
                  ...currentList.map((cable) {
                    final color = cable['color'] as Color;
                    final isStriped = cable['striped'] == true;
                    final name = cable['name'] as String;
                    final code = cable['code'] as String;
                    final desc = cable['desc'] as String;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: DesignTokens.getCardBackground(b),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: DesignTokens.getBorderColor(b)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // El visualizador de cable físico
                          Row(
                            children: [
                              // Cable Aislado
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isStriped ? null : color,
                                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                        border: cable['borderColor'] != null
                                            ? Border.all(color: cable['borderColor'] as Color)
                                            : null,
                                        gradient: isStriped
                                            ? const LinearGradient(
                                                colors: [
                                                  Colors.green,
                                                  Colors.green,
                                                  Colors.yellow,
                                                  Colors.yellow,
                                                  Colors.green,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                stops: [0.0, 0.35, 0.45, 0.65, 0.75],
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        code,
                                        style: GoogleFonts.outfit(
                                          color: cable['textColor'] as Color,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Cobre expuesto
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: _kCopperColor,
                                  borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Detalle e información del cable
                          Text(
                            name,
                            style: GoogleFonts.outfit(
                              color: DesignTokens.getTextPrimary(b),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(b),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Nota Técnica Regulatoria NOM-001-SEDE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getSurface(b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kEmeraldGreen.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: _kEmeraldGreen, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'NOTAS REGULATORIAS (NOM-001-SEDE)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kEmeraldGreen,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Secciones mayores a 21 mm² (4 AWG): Si comercialmente no se dispone de conductores con aislaciones de colores específicos, se permite el uso de conductores negros, marcando los extremos con pintura o cintas de color correspondientes (Punto 5.1.3).\n\n'
                          '• Identificación de Canalizaciones: Queda estrictamente prohibido pintar las tuberías o canalizaciones con los colores Azul, Negro o Rojo, ya que estos están reservados exclusivamente para identificar las fases activas.',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(b),
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormToggleOption(String label, bool active, VoidCallback onTap, Brightness b) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _kEmeraldGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : DesignTokens.getTextSecondary(b),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

