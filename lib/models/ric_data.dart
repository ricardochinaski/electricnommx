import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/screens/pdf_viewer_screen.dart';

/// Catálogo normativo de NOM Eléctrica MX.
///
/// La NOM-001-SEDE-2012 es un solo documento (780 páginas) organizado por
/// artículos estilo NEC. En vez de PDFs separados (como los pliegos chilenos
/// de la app madre), cada entrada apunta al MISMO PDF con `pagina` de inicio
/// del artículo, y el visor abre directo ahí (deep-link por página).
///
/// La clase conserva el nombre RicData y las claves de mapa heredadas
/// (num/titulo/desc/icon/color/assetPath/keywords) para no romper las
/// pantallas consumidoras; `articulo` y `pagina` son las claves nuevas.
class RicData {
  static const String nomAssetPath = 'assets/pdfs/nom001sede2012.pdf';
  static const String nomNombre = 'NOM-001-SEDE-2012';

  /// Artículos clave de la NOM-001-SEDE para el trabajo diario del electricista.
  /// Páginas verificadas contra el PDF del DOF (inicio de la sección X-1).
  static final List<Map<String, dynamic>> pliegos = [
    {
      'num': 1,
      'articulo': 'Art. 100',
      'titulo': 'Definiciones',
      'desc': 'Vocabulario oficial: acometida, ampacidad, puesta a tierra y más',
      'icon': Icons.menu_book_rounded,
      'color': const Color(0xFF0284C7),
      'assetPath': nomAssetPath,
      'pagina': 10,
      'keywords': [
        'definiciones',
        'acometida',
        'ampacidad',
        'a la vista',
        'lugar mojado',
        'canalización',
        'medios de desconexión',
        'vocabulario',
      ],
    },
    {
      'num': 2,
      'articulo': 'Art. 110',
      'titulo': 'Requisitos Generales',
      'desc': 'Aprobación de equipos, espacios de trabajo y marcado',
      'icon': Icons.rule_rounded,
      'color': const Color(0xFF6366F1),
      'assetPath': nomAssetPath,
      'pagina': 19,
      'keywords': [
        'requisitos generales',
        'espacio de trabajo',
        'aprobado',
        'marcado',
        'terminales',
        'gabinete',
        'temperatura de terminación',
      ],
    },
    {
      'num': 3,
      'articulo': 'Art. 210',
      'titulo': 'Circuitos Derivados',
      'desc': 'Contactos, GFCI, cargas de alumbrado y circuitos de aparatos',
      'icon': Icons.electrical_services_rounded,
      'color': const Color(0xFF059669),
      'assetPath': nomAssetPath,
      'pagina': 32,
      'keywords': [
        'circuito derivado',
        'contacto',
        'receptáculo',
        'GFCI',
        'falla a tierra',
        'caída de tensión',
        '210-19',
        'cocina',
        'baño',
        'alumbrado',
      ],
    },
    {
      'num': 4,
      'articulo': 'Art. 215-220',
      'titulo': 'Alimentadores y Cálculo de Cargas',
      'desc': 'Dimensionamiento de alimentadores y factores de demanda',
      'icon': Icons.route_rounded,
      'color': const Color(0xFF7C3AED),
      'assetPath': nomAssetPath,
      'pagina': 42,
      'keywords': [
        'alimentador',
        'cálculo de carga',
        'factor de demanda',
        'carga continua',
        'vivienda',
        'método opcional',
        'watts por metro cuadrado',
      ],
    },
    {
      'num': 5,
      'articulo': 'Art. 230',
      'titulo': 'Acometidas',
      'desc': 'Entrada de servicio, medición y medios de desconexión principal',
      'icon': Icons.cable_rounded,
      'color': const Color(0xFF0EA5E9),
      'assetPath': nomAssetPath,
      'pagina': 60,
      'keywords': [
        'acometida',
        'aérea',
        'subterránea',
        'mufa',
        'medidor',
        'CFE',
        'interruptor principal',
        'medios de desconexión',
      ],
    },
    {
      'num': 6,
      'articulo': 'Art. 240',
      'titulo': 'Protección contra Sobrecorriente',
      'desc': 'Interruptores termomagnéticos, fusibles y su ubicación',
      'icon': Icons.shield_rounded,
      'color': const Color(0xFFF59E0B),
      'assetPath': nomAssetPath,
      'pagina': 71,
      'keywords': [
        'sobrecorriente',
        'interruptor termomagnético',
        'pastilla',
        'fusible',
        'capacidad interruptiva',
        'coordinación',
        'valores nominales estándar',
      ],
    },
    {
      'num': 7,
      'articulo': 'Art. 250',
      'titulo': 'Puesta a Tierra y Unión',
      'desc': 'Electrodos, conductor de tierra y unión equipotencial',
      'icon': Icons.electric_bolt_rounded,
      'color': const Color(0xFF10B981),
      'assetPath': nomAssetPath,
      'pagina': 83,
      'keywords': [
        'puesta a tierra',
        'electrodo',
        'varilla',
        'conductor de puesta a tierra',
        'unión',
        'puente de unión',
        '250-66',
        'resistencia a tierra',
        '25 ohms',
      ],
    },
    {
      'num': 8,
      'articulo': 'Art. 300',
      'titulo': 'Métodos de Alambrado',
      'desc': 'Instalación de conductores, profundidades y protección física',
      'icon': Icons.settings_input_component_rounded,
      'color': const Color(0xFFDB2777),
      'assetPath': nomAssetPath,
      'pagina': 118,
      'keywords': [
        'métodos de alambrado',
        'profundidad de enterrado',
        'protección física',
        'cajas',
        'continuidad',
        'conductores en paralelo',
      ],
    },
    {
      'num': 9,
      'articulo': 'Art. 310',
      'titulo': 'Conductores y Ampacidad',
      'desc': 'Tabla 310-15(b)(16), factores de corrección y agrupamiento',
      'icon': Icons.power_input_rounded,
      'color': const Color(0xFF059669),
      'assetPath': nomAssetPath,
      'pagina': 130,
      'keywords': [
        'ampacidad',
        'conductores',
        '310-15',
        'tabla 310',
        'AWG',
        'kcmil',
        'THW',
        'THHW',
        'THHN',
        'factor de corrección',
        'agrupamiento',
        'temperatura ambiente',
      ],
    },
    {
      'num': 10,
      'articulo': 'Art. 408',
      'titulo': 'Tableros y Centros de Carga',
      'desc': 'Tableros de distribución, centros de carga y sus circuitos',
      'icon': Icons.dashboard_rounded,
      'color': const Color(0xFFDB2777),
      'assetPath': nomAssetPath,
      'pagina': 258,
      'keywords': [
        'centro de carga',
        'tablero',
        'panel',
        'directorio de circuitos',
        'barras',
        'interruptor derivado',
      ],
    },
    {
      'num': 11,
      'articulo': 'Art. 430',
      'titulo': 'Motores',
      'desc': 'Conductores, protección y control de motores eléctricos',
      'icon': Icons.settings_rounded,
      'color': const Color(0xFF7C3AED),
      'assetPath': nomAssetPath,
      'pagina': 296,
      'keywords': [
        'motor',
        'corriente a plena carga',
        'rotor bloqueado',
        'arrancador',
        'sobrecarga',
        'letra de código',
        'tabla 430',
      ],
    },
    {
      'num': 12,
      'articulo': 'Art. 440',
      'titulo': 'Aire Acondicionado y Refrigeración',
      'desc': 'Equipos con motocompresor hermético y minisplits',
      'icon': Icons.ac_unit_rounded,
      'color': const Color(0xFF0EA5E9),
      'assetPath': nomAssetPath,
      'pagina': 326,
      'keywords': [
        'aire acondicionado',
        'minisplit',
        'motocompresor',
        'refrigeración',
        'RLA',
        'placa de datos',
      ],
    },
    {
      'num': 13,
      'articulo': 'Art. 450',
      'titulo': 'Transformadores',
      'desc': 'Protección, instalación y bóvedas de transformadores',
      'icon': Icons.account_tree_rounded,
      'color': const Color(0xFF6366F1),
      'assetPath': nomAssetPath,
      'pagina': 334,
      'keywords': [
        'transformador',
        'kVA',
        'bóveda',
        'subestación',
        'protección primaria',
        'protección secundaria',
      ],
    },
    {
      'num': 14,
      'articulo': 'Arts. 500-516',
      'titulo': 'Áreas Peligrosas (Clasificadas)',
      'desc': 'Clase I, II y III: gases, polvos y fibras combustibles',
      'icon': Icons.warning_rounded,
      'color': const Color(0xFFF59E0B),
      'assetPath': nomAssetPath,
      'pagina': 353,
      'keywords': [
        'área peligrosa',
        'clasificada',
        'clase I',
        'división',
        'zona',
        'a prueba de explosión',
        'gasolinera',
        'seguridad intrínseca',
      ],
    },
    {
      'num': 15,
      'articulo': 'Art. 680',
      'titulo': 'Albercas y Fuentes',
      'desc': 'Instalaciones en albercas, spas y fuentes ornamentales',
      'icon': Icons.pool_rounded,
      'color': const Color(0xFF0284C7),
      'assetPath': nomAssetPath,
      'pagina': 569,
      'keywords': [
        'alberca',
        'piscina',
        'spa',
        'fuente',
        'unión equipotencial',
        'GFCI',
        'luminarias sumergidas',
      ],
    },
    {
      'num': 16,
      'articulo': 'Art. 690',
      'titulo': 'Sistemas Solares Fotovoltaicos',
      'desc': 'Paneles solares, inversores e interconexión a la red',
      'icon': Icons.solar_power_rounded,
      'color': const Color(0xFF10B981),
      'assetPath': nomAssetPath,
      'pagina': 587,
      'keywords': [
        'fotovoltaico',
        'panel solar',
        'inversor',
        'interconexión',
        'cadena',
        'medios de desconexión fotovoltaica',
        'CFE net metering',
      ],
    },
    {
      'num': 17,
      'articulo': 'Arts. 700-702',
      'titulo': 'Sistemas de Emergencia y Reserva',
      'desc': 'Alumbrado de emergencia, plantas de reserva y transferencia',
      'icon': Icons.emergency_rounded,
      'color': const Color(0xFFEF4444),
      'assetPath': nomAssetPath,
      'pagina': 617,
      'keywords': [
        'emergencia',
        'planta de emergencia',
        'transferencia',
        'alumbrado de emergencia',
        'reserva',
        'generador',
      ],
    },
  ];

  /// Segunda pestaña del catálogo: la norma completa y (a futuro) documentos
  /// complementarios (NOM-007-ENER, especificaciones CFE, etc.).
  static final List<Map<String, dynamic>> pliegosRptd = [
    {
      'num': 1,
      'articulo': 'NOM-001-SEDE-2012',
      'titulo': 'Norma Completa',
      'desc': 'Texto íntegro publicado en el DOF (780 páginas), con búsqueda',
      'icon': Icons.picture_as_pdf_rounded,
      'color': const Color(0xFF16A34A),
      'assetPath': nomAssetPath,
      'pagina': 1,
      'keywords': [
        'norma completa',
        'NOM-001',
        'SEDE',
        'DOF',
        'instalaciones eléctricas',
        'utilización',
      ],
    },
  ];

  static void _abrirEntrada(
      BuildContext context, Map<String, dynamic> entrada, String titulo) {
    final String assetPath = entrada['assetPath'] as String;
    final int pagina = (entrada['pagina'] as int?) ?? 1;

    // El intersticial se muestra dentro del PDFViewerPage al salir (PopScope)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerPage(
          title: titulo,
          assetPath: assetPath,
          initialPage: pagina,
        ),
      ),
    );
  }

  static void navegarARic(BuildContext context, int ricNumero) {
    final entrada = pliegos.firstWhere(
      (p) => p['num'] == ricNumero,
      orElse: () => <String, dynamic>{},
    );
    if (entrada.isEmpty) return;
    _abrirEntrada(
        context, entrada, "${entrada['articulo']}: ${entrada['titulo']}");
  }

  static void navegarARptd(BuildContext context, int rptdNumero) {
    final entrada = pliegosRptd.firstWhere(
      (p) => p['num'] == rptdNumero,
      orElse: () => <String, dynamic>{},
    );
    if (entrada.isEmpty) return;
    _abrirEntrada(context, entrada, "$nomNombre: ${entrada['titulo']}");
  }
}
