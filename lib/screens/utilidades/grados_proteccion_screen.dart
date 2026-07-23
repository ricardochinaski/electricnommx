import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kVioletAccent = Color(0xFF8B5CF6);

class GradosProteccionScreen extends StatefulWidget {
  const GradosProteccionScreen({super.key});

  @override
  State<GradosProteccionScreen> createState() => _GradosProteccionScreenState();
}

class _GradosProteccionScreenState extends State<GradosProteccionScreen> {
  int _firstDigit = 5; // Primer dígito IP (0-6)
  int _secondDigit = 4; // Segundo dígito IP (0-9)
  int _selectedIkIndex = 8; // Grado IK seleccionado (0 = IK00, 8 = IK08)

  // Datos de IP Sólidos
  final List<String> _solidos = [
    'Sin protección contra el ingreso de objetos sólidos.',
    'Protegido contra cuerpos sólidos de diámetro ≥ 50 mm (ej. contacto involuntario con la mano).',
    'Protegido contra cuerpos sólidos de diámetro ≥ 12.5 mm (ej. dedos de la mano).',
    'Protegido contra cuerpos sólidos de diámetro ≥ 2.5 mm (ej. herramientas o cables gruesos).',
    'Protegido contra cuerpos sólidos de diámetro ≥ 1.0 mm (ej. cables o alambres delgados).',
    'Protegido contra depósitos de polvo nocivos. La entrada de polvo no se evita por completo, pero no interfiere con el funcionamiento.',
    'Totalmente estanco al ingreso de polvo. Protección máxima contra sólidos.',
  ];

  // Datos de IP Líquidos
  final List<String> _liquidos = [
    'Sin protección contra el ingreso de agua.',
    'Protegido contra la caída vertical de gotas de agua (goteo vertical).',
    'Protegido contra goteo de agua con inclinación hasta 15° de la vertical.',
    'Protegido contra agua pulverizada o lluvia fina en ángulos hasta 60°.',
    'Protegido contra salpicaduras de agua desde cualquier dirección.',
    'Protegido contra chorros de agua a presión moderada (boquilla de 6.3 mm) desde cualquier dirección.',
    'Protegido contra chorros de agua potentes y de alta presión (boquilla de 12.5 mm) o golpes de mar.',
    'Protegido contra los efectos de la inmersión temporal en agua (1 metro de profundidad por 30 minutos).',
    'Protegido contra inmersión prolongada/continua en condiciones especificadas por el fabricante.',
    'Protegido contra chorros potentes de agua a alta presión y alta temperatura (limpieza a vapor/chorro).',
  ];

  // Datos de grados IK
  final List<Map<String, dynamic>> _ikData = [
    {'code': 'IK00', 'joules': '0 J', 'desc': 'Sin protección contra impactos mecánicos.'},
    {'code': 'IK01', 'joules': '0.14 J', 'desc': 'Protegido contra impacto de 0.2 kg cayendo desde 7.5 cm.'},
    {'code': 'IK02', 'joules': '0.20 J', 'desc': 'Protegido contra impacto de 0.2 kg cayendo desde 10 cm.'},
    {'code': 'IK03', 'joules': '0.35 J', 'desc': 'Protegido contra impacto de 0.2 kg cayendo desde 17.5 cm.'},
    {'code': 'IK04', 'joules': '0.50 J', 'desc': 'Protegido contra impacto de 0.2 kg cayendo desde 25 cm.'},
    {'code': 'IK05', 'joules': '0.70 J', 'desc': 'Protegido contra impacto de 0.2 kg cayendo desde 35 cm.'},
    {'code': 'IK06', 'joules': '1.00 J', 'desc': 'Protegido contra impacto de 0.5 kg cayendo desde 20 cm.'},
    {'code': 'IK07', 'joules': '2.00 J', 'desc': 'Protegido contra impacto de 0.5 kg cayendo desde 40 cm.'},
    {'code': 'IK08', 'joules': '5.00 J', 'desc': 'Protegido contra impacto de 1.7 kg cayendo desde 29.5 cm.'},
    {'code': 'IK09', 'joules': '10.00 J', 'desc': 'Protegido contra impacto de 5.0 kg cayendo desde 20 cm.'},
    {'code': 'IK10', 'joules': '20.00 J', 'desc': 'Protegido contra impacto de 5.0 kg cayendo desde 40 cm.'},
  ];

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final ikSelected = _ikData[_selectedIkIndex];

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: _kVioletAccent, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'GRADOS DE PROTECCIÓN IP / IK',
                    style: DesignTokens.getDisplay(b, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'RIC N° 03 - Resguardo de Envolventes',
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
                  // --- CÓDIGO IP INTERACTIVO ---
                  Text(
                    'INTERACTIVE IP CODE GENERATOR',
                    style: TextStyle(
                      color: _kVioletAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Caja principal del Código IP Armado
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _kVioletAccent.withAlpha(15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _kVioletAccent.withAlpha(80)),
                      boxShadow: [
                        BoxShadow(
                          color: _kVioletAccent.withAlpha(15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'CÓDIGO DE PROTECCIÓN INGRESO',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(b),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'IP',
                              style: GoogleFonts.outfit(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: DesignTokens.getTextPrimary(b),
                              ),
                            ),
                            Text(
                              '$_firstDigit',
                              style: GoogleFonts.outfit(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: _kVioletAccent,
                              ),
                            ),
                            Text(
                              '$_secondDigit',
                              style: GoogleFonts.outfit(
                                fontSize: 56,
                                fontWeight: FontWeight.w900,
                                color: _kVioletAccent.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Controles de Selección de los Dígitos
                  Row(
                    children: [
                      // Selector Primer Dígito (Sólidos)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '1er Dígito: Sólidos',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.getTextPrimary(b),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: DesignTokens.getCardBackground(b),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DesignTokens.getBorderColor(b)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _firstDigit,
                                  dropdownColor: DesignTokens.getSurface(b),
                                  isExpanded: true,
                                  style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 14),
                                  items: List.generate(7, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('$index - Sólidos'),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _firstDigit = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Selector Segundo Dígito (Líquidos)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '2do Dígito: Líquidos',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.getTextPrimary(b),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: DesignTokens.getCardBackground(b),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: DesignTokens.getBorderColor(b)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _secondDigit,
                                  dropdownColor: DesignTokens.getSurface(b),
                                  isExpanded: true,
                                  style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 14),
                                  items: List.generate(10, (index) {
                                    return DropdownMenuItem<int>(
                                      value: index,
                                      child: Text('$index - Líquidos'),
                                    );
                                  }),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _secondDigit = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Descripciones del IP armando en tiempo real
                  Text(
                    'SIGNIFICADO DEL CÓDIGO IP',
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(b),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: DesignTokens.getBorderColor(b)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Primer dígito
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kVioletAccent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_firstDigit',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _solidos[_firstDigit],
                                style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: DesignTokens.getBorderColor(b)),
                        const SizedBox(height: 12),
                        // Segundo dígito
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kVioletAccent.withAlpha(160),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$_secondDigit',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _liquidos[_secondDigit],
                                style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 12, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // --- SECCIÓN IK (IMPACTO MECÁNICO) ---
                  Text(
                    'GRADOS DE IMPACTO MECÁNICO (IK)',
                    style: TextStyle(
                      color: _kVioletAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tarjeta interactiva de IK
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getCardBackground(b),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: DesignTokens.getBorderColor(b)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selector horizontal de IK
                        Text(
                          'Selecciona Grado IK:',
                          style: GoogleFonts.outfit(
                            color: DesignTokens.getTextPrimary(b),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 38,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _ikData.length,
                            itemBuilder: (context, index) {
                              final isSelected = _selectedIkIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIkIndex = index;
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected ? _kVioletAccent : DesignTokens.getSurface(b),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected ? _kVioletAccent : DesignTokens.getBorderColor(b),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _ikData[index]['code'] as String,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : DesignTokens.getTextPrimary(b),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: DesignTokens.getBorderColor(b)),
                        const SizedBox(height: 10),
                        // Información de Impacto Seleccionada
                        Row(
                          children: [
                            Text(
                              ikSelected['code'] as String,
                              style: GoogleFonts.outfit(
                                color: _kVioletAccent,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _kVioletAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                ikSelected['joules'] as String,
                                style: const TextStyle(
                                  color: _kVioletAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ikSelected['desc'] as String,
                          style: TextStyle(
                            color: DesignTokens.getTextPrimary(b).withAlpha(200),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recomendaciones Normativas de Chile (Pliego RIC N° 03)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignTokens.getSurface(b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kVioletAccent.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: _kVioletAccent, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'RECOMENDACIONES EXIGIDAS (RIC N° 03)',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _kVioletAccent,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '• Instalación a la Intemperie: Se exige un envolvente mínimo de IP44. Se recomienda fuertemente usar protección superior (IP54 o IP65) para resistir el polvo en suspensión y lluvias copiosas locales.\n\n'
                          '• Salas de Baño / Zonas Húmedas: En tableros ubicados en cercanías a duchas o tuberías conductoras de agua, se debe asegurar un resguardo mínimo de IP44.\n\n'
                          '• Tableros Generales / Distribución: Deben cumplir mínimo con IP2X en recintos interiores no expuestos a riesgos adicionales (Punto 5.2.4).',
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
}

