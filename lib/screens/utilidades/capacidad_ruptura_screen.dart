import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kWarningAmber = Color(0xFFF59E0B);

class CapacidadRupturaScreen extends StatefulWidget {
  const CapacidadRupturaScreen({super.key});

  @override
  State<CapacidadRupturaScreen> createState() => _CapacidadRupturaScreenState();
}

class _CapacidadRupturaScreenState extends State<CapacidadRupturaScreen> {
  int _selectedCategoryIndex = 0; // 0 = Residencial, 1 = Comercial, 2 = Industrial

  // La NOM-001-SEDE (Art. 110-9) exige que la capacidad interruptiva sea
  // suficiente para la corriente de cortocircuito DISPONIBLE en el punto de
  // instalación — no fija mínimos por categoría. Los valores mostrados son
  // la práctica comercial típica en México (pastillas QO/atornillables).
  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Residencial',
      'icon': Icons.home_rounded,
      'ka': '10 kA',
      'sub': 'Casas y Departamentos',
      'desc': 'Práctica típica en centros de carga residenciales: los interruptores termomagnéticos comerciales (QO y atornillables) traen 10 kA de capacidad interruptiva estándar, suficiente para el cortocircuito disponible tras la acometida y el medidor CFE en vivienda.',
      'norma': 'NOM-001-SEDE, Art. 110-9 - Capacidad interruptiva suficiente para la corriente disponible.'
    },
    {
      'title': 'Comercial',
      'icon': Icons.storefront_rounded,
      'ka': '14-25 kA',
      'sub': 'Locales, Oficinas y Tableros Generales',
      'desc': 'En locales comerciales y tableros generales de edificios la corriente de cortocircuito disponible es mayor por transformadores dedicados o cercanía a la subestación. Se usan interruptores de 14, 18 o 25 kA según el estudio de cortocircuito.',
      'norma': 'NOM-001-SEDE, Arts. 110-9 y 110-10 - Coordinación con la corriente disponible.'
    },
    {
      'title': 'Industrial',
      'icon': Icons.precision_manufacturing_rounded,
      'ka': '25-65 kA',
      'sub': 'Fábricas, Subestaciones e Industrias',
      'desc': 'En entornos industriales con transformadores de gran capacidad y cargas motoras, es obligatorio el estudio de cortocircuito punto a punto. Interruptores de caja moldeada (MCCB) de 25, 35, 50 o 65 kA según el resultado del cálculo.',
      'norma': 'NOM-001-SEDE, Art. 110-9 - Verificación por estudio de corrientes de cortocircuito.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final current = _categories[_selectedCategoryIndex];

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(Icons.offline_bolt_rounded, color: _kWarningAmber, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPACIDAD DE RUPTURA',
                    style: DesignTokens.getDisplay(b, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'NOM Art. 110-9 - Capacidad Interruptiva',
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
                  Text(
                    'TIPO DE INSTALACIÓN',
                    style: TextStyle(
                      color: _kWarningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3 Tarjetas de selección rápida
                  Row(
                    children: List.generate(_categories.length, (index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategoryIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCategoryIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: EdgeInsets.only(
                              left: index == 0 ? 0 : 6,
                              right: index == _categories.length - 1 ? 0 : 6,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _kWarningAmber.withAlpha(20)
                                  : DesignTokens.getCardBackground(b),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? _kWarningAmber : DesignTokens.getBorderColor(b),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: _kWarningAmber.withAlpha(25),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  cat['icon'] as IconData,
                                  color: isSelected ? _kWarningAmber : DesignTokens.getTextSecondary(b),
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  cat['title'] as String,
                                  style: GoogleFonts.outfit(
                                    color: isSelected ? _kWarningAmber : DesignTokens.getTextPrimary(b),
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 28),

                  // Visualización interactiva del valor mínimo con animación
                  Text(
                    'CAPACIDAD MÍNIMA REQUERIDA',
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(b),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      key: ValueKey<int>(_selectedCategoryIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _kWarningAmber.withAlpha(15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: _kWarningAmber.withAlpha(80)),
                        boxShadow: [
                          BoxShadow(
                            color: _kWarningAmber.withAlpha(15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            current['sub'] as String,
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(b),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            current['ka'] as String,
                            style: GoogleFonts.outfit(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: _kWarningAmber,
                            ),
                          ),
                          Text(
                            'Simétrica Mínima (Icu)',
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(b),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Descripción detallada
                  Text(
                    'DESCRIPCIÓN DE LA EXIGENCIA',
                    style: TextStyle(
                      color: _kWarningAmber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(b),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.getBorderColor(b)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          current['desc'] as String,
                          style: TextStyle(
                            color: DesignTokens.getTextPrimary(b).withAlpha(220),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(color: DesignTokens.getBorderColor(b)),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.menu_book_rounded,
                              color: _kWarningAmber,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                current['norma'] as String,
                                style: TextStyle(
                                  color: DesignTokens.getTextSecondary(b),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Banner de Advertencia Ámbar Normativo Fijo/Preeminente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ADVERTENCIA NORMATIVA SEC',
                                style: GoogleFonts.outfit(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Bajo ninguna circunstancia se permite el uso de protecciones de 1.5 kA o 3 kA en tableros de distribución general o derivaciones secundarias reguladas por los pliegos técnicos RIC.\n\n'
                                'Es responsabilidad del instalador autorizado por la SEC verificar la corriente de cortocircuito presunta de la red eléctrica para asegurar el poder de corte.',
                                style: TextStyle(
                                  color: DesignTokens.getTextPrimary(b).withAlpha(200),
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
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
}

