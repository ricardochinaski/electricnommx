import 'package:flutter_test/flutter_test.dart';
import 'package:nom_electrica_mx/data/nom310_ampacidad_data.dart';

void main() {
  group('Nom310AmpacidadData.iBase — integridad de la Tabla 310-15(b)(16)', () {
    test('los 3 aislamientos tienen todos los calibres del catálogo', () {
      for (final aislamiento in ['60', '75', '90']) {
        final tabla = Nom310AmpacidadData.iBase[aislamiento];
        expect(tabla, isNotNull);
        for (final c in Nom310AmpacidadData.calibres) {
          final awg = c['awg'] as String;
          expect(tabla![awg], isNotNull,
              reason: 'Falta $awg en la columna $aislamiento°C');
        }
      }
    });

    test('valores puntuales conocidos de la tabla (cobre)', () {
      expect(Nom310AmpacidadData.iBase['60']!['14 AWG'], 15);
      expect(Nom310AmpacidadData.iBase['75']!['14 AWG'], 20);
      expect(Nom310AmpacidadData.iBase['90']!['14 AWG'], 25);
      expect(Nom310AmpacidadData.iBase['75']!['10 AWG'], 35);
      expect(Nom310AmpacidadData.iBase['60']!['4/0 AWG'], 195);
      expect(Nom310AmpacidadData.iBase['75']!['4/0 AWG'], 230);
      expect(Nom310AmpacidadData.iBase['90']!['4/0 AWG'], 260);
      expect(Nom310AmpacidadData.iBase['75']!['500 kcmil'], 380);
      expect(Nom310AmpacidadData.iBase['90']!['500 kcmil'], 430);
    });

    test('a igual calibre: 90°C > 75°C > 60°C', () {
      for (final c in Nom310AmpacidadData.calibres) {
        final awg = c['awg'] as String;
        final i60 = Nom310AmpacidadData.iBase['60']![awg]!;
        final i75 = Nom310AmpacidadData.iBase['75']![awg]!;
        final i90 = Nom310AmpacidadData.iBase['90']![awg]!;
        expect(i75, greaterThan(i60), reason: '$awg: 75°C debe superar a 60°C');
        expect(i90, greaterThan(i75), reason: '$awg: 90°C debe superar a 75°C');
      }
    });

    test('la ampacidad crece con el calibre y el área también', () {
      for (final aislamiento in ['60', '75', '90']) {
        double ampAnterior = 0;
        double areaAnterior = 0;
        for (final c in Nom310AmpacidadData.calibres) {
          final awg = c['awg'] as String;
          final area = (c['mm2'] as num).toDouble();
          final amp = Nom310AmpacidadData.iBase[aislamiento]![awg]!;
          expect(amp, greaterThan(ampAnterior),
              reason: '$aislamiento°C/$awg debe admitir más que el calibre anterior');
          expect(area, greaterThan(areaAnterior),
              reason: '$awg: el área debe crecer con el calibre');
          ampAnterior = amp;
          areaAnterior = area;
        }
      }
    });
  });

  group('Nom310AmpacidadData.factorTemperatura (Tabla 310-15(b)(2)(a))', () {
    test('retorna 1.00 a 30°C o menos, para los 3 aislamientos', () {
      for (final a in ['60', '75', '90']) {
        expect(Nom310AmpacidadData.factorTemperatura(a, 30), 1.00);
        expect(Nom310AmpacidadData.factorTemperatura(a, 20), 1.00);
      }
    });

    test('valores puntuales de la tabla oficial', () {
      expect(Nom310AmpacidadData.factorTemperatura('60', 35), 0.91);
      expect(Nom310AmpacidadData.factorTemperatura('75', 40), 0.88);
      expect(Nom310AmpacidadData.factorTemperatura('90', 50), 0.82);
      expect(Nom310AmpacidadData.factorTemperatura('90', 80), 0.41);
    });

    test('a igual temperatura, el aislamiento superior tolera mejor', () {
      for (final t in [35.0, 40.0, 45.0, 50.0, 55.0]) {
        final f60 = Nom310AmpacidadData.factorTemperatura('60', t);
        final f75 = Nom310AmpacidadData.factorTemperatura('75', t);
        final f90 = Nom310AmpacidadData.factorTemperatura('90', t);
        expect(f75, greaterThan(f60), reason: 'a $t°C, 75 debe tolerar más que 60');
        expect(f90, greaterThan(f75), reason: 'a $t°C, 90 debe tolerar más que 75');
      }
    });

    test('retorna 0 fuera del rango soportado', () {
      expect(Nom310AmpacidadData.factorTemperatura('60', 60), 0.00);
      expect(Nom310AmpacidadData.factorTemperatura('75', 75), 0.00);
      expect(Nom310AmpacidadData.factorTemperatura('90', 85), 0.00);
    });
  });

  group('Nom310AmpacidadData.factorAgrupamiento (Tabla 310-15(b)(3)(a))', () {
    test('hasta 3 conductores portadores no hay ajuste', () {
      expect(Nom310AmpacidadData.factorAgrupamiento(1), 1.00);
      expect(Nom310AmpacidadData.factorAgrupamiento(3), 1.00);
    });

    test('valores puntuales de la tabla oficial', () {
      expect(Nom310AmpacidadData.factorAgrupamiento(4), 0.80);
      expect(Nom310AmpacidadData.factorAgrupamiento(6), 0.80);
      expect(Nom310AmpacidadData.factorAgrupamiento(7), 0.70);
      expect(Nom310AmpacidadData.factorAgrupamiento(10), 0.50);
      expect(Nom310AmpacidadData.factorAgrupamiento(21), 0.45);
      expect(Nom310AmpacidadData.factorAgrupamiento(31), 0.40);
      expect(Nom310AmpacidadData.factorAgrupamiento(41), 0.35);
    });

    test('el factor decrece monótonamente', () {
      double anterior = 1.01;
      for (final n in [1, 3, 4, 6, 7, 9, 10, 20, 21, 30, 31, 40, 41, 50]) {
        final f = Nom310AmpacidadData.factorAgrupamiento(n);
        expect(f, lessThanOrEqualTo(anterior));
        anterior = f;
      }
    });
  });
}
