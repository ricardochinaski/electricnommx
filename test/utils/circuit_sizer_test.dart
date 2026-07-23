import 'package:flutter_test/flutter_test.dart';
import 'package:nom_electrica_mx/utils/circuit_sizer.dart';

void main() {
  group('CircuitSizer.caidaPorcentual (tensiones mexicanas)', () {
    test('monofásico 127V: VP% = (2 · ρ · L · I / S) / 127 · 100', () {
      // 20A, 10m, 12 AWG (3.31mm²): vp = (2*0.018*10*20)/3.31 = 2.1752V -> 1.7128%
      final caida = CircuitSizer.caidaPorcentual(
        areaMm2: 3.31,
        corriente: 20,
        largo: 10,
        cosPhi: 1.0,
        esTrifasico: false,
      );
      expect(caida, closeTo(1.713, 0.01));
    });

    test('trifásico 220V: VP% = (√3 · ρ · L · I · cosφ / S) / 220 · 100', () {
      // 40A, 50m, cosφ 0.9, 6 AWG (13.3mm²) -> ≈1.918%
      final caida = CircuitSizer.caidaPorcentual(
        areaMm2: 13.3,
        corriente: 40,
        largo: 50,
        cosPhi: 0.9,
        esTrifasico: true,
      );
      expect(caida, closeTo(1.918, 0.01));
    });

    test('a mayor calibre (área), menor caída de tensión', () {
      final c14 = CircuitSizer.caidaPorcentual(
          areaMm2: 2.08, corriente: 20, largo: 20, cosPhi: 1, esTrifasico: false);
      final c6 = CircuitSizer.caidaPorcentual(
          areaMm2: 13.3, corriente: 20, largo: 20, cosPhi: 1, esTrifasico: false);
      expect(c6, lessThan(c14));
    });
  });

  group('CircuitSizer.calcular — caso dominado por ampacidad', () {
    test('tramo corto: la Tabla 310-15(b)(16) decide, no la caída', () {
      // 25A, 5m, THW 75°C: 14 AWG (20A) falla ampacidad pero pasa caída;
      // 12 AWG (25A) cumple ambos.
      final r = CircuitSizer.calcular(
        corriente: 25,
        largo: 5,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '75',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 3,
        limiteCaidaPct: 3.0,
      );

      expect(r.sinSolucion, isFalse);
      expect(r.calibreRecomendado, '12 AWG');
      expect(r.areaMm2, 3.31);
      expect(r.minPorAmpacidad, '12 AWG');
      expect(r.minPorCaida, '14 AWG');
      expect(r.criterioDominante, 'Ampacidad (Tabla 310-15(b)(16))');
      expect(r.iAdmisibleFinal, 25.0); // 25A base, sin correcciones
      expect(r.caidaPct, closeTo(1.070, 0.01));
    });
  });

  group('CircuitSizer.calcular — caso dominado por caída de tensión', () {
    test('carga baja pero tramo largo: la caída obliga a subir de calibre', () {
      // 15A, 60m, THHN 90°C: 14 AWG sobra en ampacidad (25A) pero la caída
      // en 127V no cumple 3% hasta 6 AWG (8 AWG da 3.05%, apenas falla).
      final r = CircuitSizer.calcular(
        corriente: 15,
        largo: 60,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '90',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 3,
        limiteCaidaPct: 3.0,
      );

      expect(r.sinSolucion, isFalse);
      expect(r.minPorAmpacidad, '14 AWG');
      expect(r.calibreRecomendado, '6 AWG');
      expect(r.minPorCaida, '6 AWG');
      expect(r.criterioDominante, 'Caída de tensión');
      expect(r.caidaPct, closeTo(1.918, 0.01));
    });

    test('límite 5% (alimentador) permite calibre menor que límite 3%', () {
      // Mismo escenario anterior pero como alimentador (5%): 10 AWG da 4.85% ≤5.
      final r = CircuitSizer.calcular(
        corriente: 15,
        largo: 60,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '90',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 3,
        limiteCaidaPct: 5.0,
      );
      expect(r.calibreRecomendado, '10 AWG');
    });
  });

  group('CircuitSizer.calcular — factor de agrupamiento 310-15(b)(3)(a)', () {
    test('más de 3 conductores portadores obliga a un calibre mayor', () {
      final base = CircuitSizer.calcular(
        corriente: 30,
        largo: 5,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '75',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 3, // f = 1.00
        limiteCaidaPct: 3.0,
      );
      final agrupado = CircuitSizer.calcular(
        corriente: 30,
        largo: 5,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '75',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 8, // f = 0.70
        limiteCaidaPct: 3.0,
      );

      expect(base.calibreRecomendado, '10 AWG'); // 35A ≥ 30A
      expect(agrupado.calibreRecomendado, '8 AWG'); // 35*0.7=24.5 <30; 50*0.7=35 ok
    });
  });

  group('CircuitSizer.calcular — sin solución', () {
    test('corriente sobre el máximo tabulado (500 kcmil / 90°C = 430A)', () {
      final r = CircuitSizer.calcular(
        corriente: 700,
        largo: 1,
        cosPhi: 1.0,
        esTrifasico: false,
        aislamiento: '90',
        temperaturaAmbiente: 30,
        conductoresAgrupados: 3,
        limiteCaidaPct: 3.0,
      );

      expect(r.sinSolucion, isTrue);
      expect(r.calibreRecomendado, isNull);
      expect(r.minPorAmpacidad, isNull);
      expect(r.criterioDominante, isNull);
    });
  });

  group('CircuitSizer.calcular — temperatura fuera de rango', () {
    test('lanza ArgumentError si f_t = 0 para el aislamiento seleccionado', () {
      expect(
        () => CircuitSizer.calcular(
          corriente: 20,
          largo: 10,
          cosPhi: 1.0,
          esTrifasico: false,
          aislamiento: '60',
          temperaturaAmbiente: 60, // TW no soporta 60°C ambiente
          conductoresAgrupados: 3,
          limiteCaidaPct: 3.0,
        ),
        throwsArgumentError,
      );
    });
  });
}
