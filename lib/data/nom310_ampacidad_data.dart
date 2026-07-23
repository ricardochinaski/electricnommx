/// Fuente única de verdad para los datos de ampacidad de la
/// NOM-001-SEDE-2012 (conductores de cobre) y sus factores de corrección.
///
/// Base normativa:
///  - Tabla 310-15(b)(16): ampacidades permisibles de conductores aislados
///    hasta 2000 V, no más de 3 conductores portadores de corriente en una
///    canalización (tubería conduit), temperatura ambiente de 30 °C.
///  - Tabla 310-15(b)(2)(a): factores de corrección por temperatura ambiente.
///  - Tabla 310-15(b)(3)(a): factores de ajuste por más de 3 conductores
///    portadores de corriente en la misma canalización.
///
/// Consumida por las calculadoras de dimensionado y ampacidad. Cualquier
/// ajuste normativo se hace SOLO aquí. Los valores deben validarse contra el
/// texto oficial del DOF antes de cada release (regla del proyecto: ningún
/// dato normativo sin revisión + test).
class Nom310AmpacidadData {
  Nom310AmpacidadData._();

  /// Calibres comerciales de cobre en orden ascendente de sección.
  /// Etiqueta AWG/kcmil y su área nominal en mm² (para caída de tensión).
  static const List<Map<String, Object>> calibres = [
    {'awg': '14 AWG', 'mm2': 2.08},
    {'awg': '12 AWG', 'mm2': 3.31},
    {'awg': '10 AWG', 'mm2': 5.26},
    {'awg': '8 AWG', 'mm2': 8.37},
    {'awg': '6 AWG', 'mm2': 13.3},
    {'awg': '4 AWG', 'mm2': 21.2},
    {'awg': '2 AWG', 'mm2': 33.6},
    {'awg': '1/0 AWG', 'mm2': 53.5},
    {'awg': '2/0 AWG', 'mm2': 67.4},
    {'awg': '3/0 AWG', 'mm2': 85.0},
    {'awg': '4/0 AWG', 'mm2': 107.2},
    {'awg': '250 kcmil', 'mm2': 127.0},
    {'awg': '350 kcmil', 'mm2': 177.0},
    {'awg': '500 kcmil', 'mm2': 253.0},
  ];

  /// Aislamiento por temperatura y sus tipos comerciales en México.
  static const Map<String, String> aislamientosDesc = {
    '60': '60°C (TW)',
    '75': '75°C (THW, THWN)',
    '90': '90°C (THHW, THHN, XHHW-2)',
  };

  /// Tabla 310-15(b)(16) — ampacidad base (A) del cobre en tubería conduit,
  /// máx. 3 conductores portadores, 30 °C ambiente.
  /// Estructura: iBase[aislamiento][awg].
  static final Map<String, Map<String, double>> iBase = {
    '60': {
      '14 AWG': 15, '12 AWG': 20, '10 AWG': 30, '8 AWG': 40, '6 AWG': 55,
      '4 AWG': 70, '2 AWG': 95, '1/0 AWG': 125, '2/0 AWG': 145,
      '3/0 AWG': 165, '4/0 AWG': 195, '250 kcmil': 215, '350 kcmil': 260,
      '500 kcmil': 320,
    },
    '75': {
      '14 AWG': 20, '12 AWG': 25, '10 AWG': 35, '8 AWG': 50, '6 AWG': 65,
      '4 AWG': 85, '2 AWG': 115, '1/0 AWG': 150, '2/0 AWG': 175,
      '3/0 AWG': 200, '4/0 AWG': 230, '250 kcmil': 255, '350 kcmil': 310,
      '500 kcmil': 380,
    },
    '90': {
      '14 AWG': 25, '12 AWG': 30, '10 AWG': 40, '8 AWG': 55, '6 AWG': 75,
      '4 AWG': 95, '2 AWG': 130, '1/0 AWG': 170, '2/0 AWG': 195,
      '3/0 AWG': 225, '4/0 AWG': 260, '250 kcmil': 290, '350 kcmil': 350,
      '500 kcmil': 430,
    },
  };

  /// Factor de corrección por temperatura ambiente (Tabla 310-15(b)(2)(a),
  /// base 30 °C) según el aislamiento ('60', '75' o '90').
  static double factorTemperatura(String aislamiento, double temp) {
    if (temp <= 30) return 1.00;
    switch (aislamiento) {
      case '60':
        if (temp <= 35) return 0.91;
        if (temp <= 40) return 0.82;
        if (temp <= 45) return 0.71;
        if (temp <= 50) return 0.58;
        if (temp <= 55) return 0.41;
        return 0.00;
      case '75':
        if (temp <= 35) return 0.94;
        if (temp <= 40) return 0.88;
        if (temp <= 45) return 0.82;
        if (temp <= 50) return 0.75;
        if (temp <= 55) return 0.67;
        if (temp <= 60) return 0.58;
        if (temp <= 70) return 0.33;
        return 0.00;
      default: // '90'
        if (temp <= 35) return 0.96;
        if (temp <= 40) return 0.91;
        if (temp <= 45) return 0.87;
        if (temp <= 50) return 0.82;
        if (temp <= 55) return 0.76;
        if (temp <= 60) return 0.71;
        if (temp <= 70) return 0.58;
        if (temp <= 80) return 0.41;
        return 0.00;
    }
  }

  /// Factor de ajuste por más de 3 conductores portadores de corriente en la
  /// misma canalización (Tabla 310-15(b)(3)(a)).
  static double factorAgrupamiento(int conductoresPortadores) {
    if (conductoresPortadores <= 3) return 1.00;
    if (conductoresPortadores <= 6) return 0.80;
    if (conductoresPortadores <= 9) return 0.70;
    if (conductoresPortadores <= 20) return 0.50;
    if (conductoresPortadores <= 30) return 0.45;
    if (conductoresPortadores <= 40) return 0.40;
    return 0.35; // 41 o más
  }
}
