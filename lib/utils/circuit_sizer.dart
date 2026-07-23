import 'dart:math';
import 'package:nom_electrica_mx/data/nom310_ampacidad_data.dart';

/// Resultado del dimensionado inverso de un circuito (NOM-001-SEDE).
class CircuitSizerResult {
  /// Calibre recomendado (ej. "12 AWG", "1/0 AWG", "250 kcmil"); null si no hay solución.
  final String? calibreRecomendado;

  /// Área en mm² del calibre recomendado (para referencia y reportes).
  final double? areaMm2;

  final String? minPorAmpacidad;
  final String? minPorCaida;
  final double? iAdmisibleFinal;
  final double? caidaPct;
  final String? criterioDominante;
  final bool sinSolucion;

  const CircuitSizerResult({
    required this.calibreRecomendado,
    required this.areaMm2,
    required this.minPorAmpacidad,
    required this.minPorCaida,
    required this.iAdmisibleFinal,
    required this.caidaPct,
    required this.criterioDominante,
    required this.sinSolucion,
  });
}

/// Lógica pura de dimensionado de circuitos según NOM-001-SEDE-2012:
/// dada la carga y las condiciones reales de instalación, recorre los
/// calibres comerciales de cobre (AWG/kcmil) y determina el mínimo que
/// cumple SIMULTÁNEAMENTE:
///  1) Ampacidad corregida (Tabla 310-15(b)(16) × f_t × f_agrup) ≥ I diseño.
///  2) Caída de tensión ≤ límite (3% circuito derivado / 5% total,
///     notas de los Arts. 210-19 y 215-2).
///
/// Tensiones nominales mexicanas: 127 V (1Φ) y 220 V (3Φ).
/// Sin dependencia de Flutter — testeada en test/utils/circuit_sizer_test.dart.
class CircuitSizer {
  CircuitSizer._();

  static const double _rhoCobre = 0.018; // Ω·mm²/m (cobre a Tª de servicio)

  static const double tensionMonofasica = 127.0;
  static const double tensionTrifasica = 220.0;

  /// Caída de tensión porcentual para un área de conductor, corriente y largo.
  static double caidaPorcentual({
    required double areaMm2,
    required double corriente,
    required double largo,
    required double cosPhi,
    required bool esTrifasico,
  }) {
    final double vNominal = esTrifasico ? tensionTrifasica : tensionMonofasica;
    final double vp = esTrifasico
        ? (sqrt(3) * _rhoCobre * largo * corriente * cosPhi) / areaMm2
        : (2 * _rhoCobre * largo * corriente) / areaMm2;
    return (vp / vNominal) * 100;
  }

  /// Calcula el calibre mínimo de cobre que satisface ampacidad corregida y
  /// caída de tensión a la vez.
  ///
  /// [limiteCaidaPct]: 3.0 para circuito derivado, 5.0 para alimentador o
  /// caída total (notas Arts. 210-19 / 215-2).
  /// [conductoresAgrupados]: conductores PORTADORES de corriente en la misma
  /// canalización (la Tabla 310-15(b)(3)(a) aplica sobre ese conteo).
  ///
  /// Lanza [ArgumentError] si [temperaturaAmbiente] queda fuera del rango
  /// soportado por el aislamiento seleccionado (f_t = 0).
  static CircuitSizerResult calcular({
    required double corriente,
    required double largo,
    required double cosPhi,
    required bool esTrifasico,
    required String aislamiento,
    required double temperaturaAmbiente,
    required int conductoresAgrupados,
    required double limiteCaidaPct,
  }) {
    final double ft =
        Nom310AmpacidadData.factorTemperatura(aislamiento, temperaturaAmbiente);
    final double fg =
        Nom310AmpacidadData.factorAgrupamiento(conductoresAgrupados);

    if (ft <= 0) {
      throw ArgumentError(
        'Temperatura ambiente fuera de rango para el aislamiento seleccionado.',
      );
    }

    String? recomendado;
    double? recomendadoArea;
    String? minAmp;
    String? minCaida;
    double? iAdmFinal;
    double? caidaFinal;
    int? idxMinAmp;
    int? idxMinCaida;

    final calibres = Nom310AmpacidadData.calibres;
    for (int i = 0; i < calibres.length; i++) {
      final String awg = calibres[i]['awg'] as String;
      final double area = (calibres[i]['mm2'] as num).toDouble();
      final double iAdm =
          Nom310AmpacidadData.iBase[aislamiento]![awg]! * ft * fg;
      final double caida = caidaPorcentual(
        areaMm2: area,
        corriente: corriente,
        largo: largo,
        cosPhi: cosPhi,
        esTrifasico: esTrifasico,
      );
      final bool okAmp = iAdm >= corriente;
      final bool okCaida = caida <= limiteCaidaPct;

      if (okAmp && minAmp == null) {
        minAmp = awg;
        idxMinAmp = i;
      }
      if (okCaida && minCaida == null) {
        minCaida = awg;
        idxMinCaida = i;
      }

      if (okAmp && okCaida && recomendado == null) {
        recomendado = awg;
        recomendadoArea = area;
        iAdmFinal = iAdm;
        caidaFinal = caida;
      }
    }

    String? criterio;
    if (recomendado != null && idxMinAmp != null && idxMinCaida != null) {
      criterio = idxMinAmp >= idxMinCaida
          ? 'Ampacidad (Tabla 310-15(b)(16))'
          : 'Caída de tensión';
    }

    return CircuitSizerResult(
      calibreRecomendado: recomendado,
      areaMm2: recomendadoArea,
      minPorAmpacidad: minAmp,
      minPorCaida: minCaida,
      iAdmisibleFinal: iAdmFinal,
      caidaPct: caidaFinal,
      criterioDominante: criterio,
      sinSolucion: recomendado == null,
    );
  }
}
