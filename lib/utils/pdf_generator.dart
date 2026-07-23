import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static String get _fecha => DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  static String get _fileStamp => DateFormat('yyyyMMdd_HHmm').format(DateTime.now());

  static pw.Widget _buildHeader(String validador) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'NOM ELÉCTRICA MX',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.Text('Reporte Técnico de Validación Normativa'),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Fecha: $_fecha'),
                pw.Text('Validador: $validador'),
              ],
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
        pw.SizedBox(height: 20),
      ],
    );
  }

  static pw.Widget _buildVeredicto(bool excede, String mensajeOk, String mensajeError) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: excede ? PdfColors.red100 : PdfColors.green100,
        border: pw.Border.all(
          color: excede ? PdfColors.red : PdfColors.green,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            excede ? mensajeError : mensajeOk,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: excede ? PdfColors.red900 : PdfColors.green900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.SizedBox(height: 40),
        pw.Divider(),
        pw.Center(
          child: pw.Text(
            'Este reporte fue generado automáticamente por la App NOM Eléctrica MX.',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ),
        pw.Center(
          child: pw.Text(
            'La validez de este cálculo depende de la veracidad de los datos ingresados por el usuario.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  /// REPORTE RIC 04 (Original)
  static Future<void> generateRic04Report({
    required String uso,
    required String aislacion,
    required String corriente,
    required String longitud,
    required double seccion,
    required String tempAmbiente,
    required double ic,
    required double deltaV,
    required double porcentajeDelta,
    required String? ocupacionDucto,
    required bool excedeNorma,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('RIC N° 04'),
                _buildVeredicto(
                  excedeNorma,
                  '✅ EL CÁLCULO CUMPLE CON LA NORMATIVA RIC',
                  '❌ EL CÁLCULO INCUMPLE LA NORMATIVA RIC',
                ),
                pw.SizedBox(height: 30),
                pw.Text('DATOS DE ENTRADA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 25,
                  data: [
                    ['Parámetro', 'Valor Ingresado'],
                    ['Uso del Circuito', uso],
                    ['Tipo de Aislación', aislacion],
                    ['Corriente de Diseño (Id)', '$corriente A'],
                    ['Longitud del Tramo (L)', '$longitud m'],
                    ['Sección Nominal', '$seccion mm²'],
                    ['Temperatura Ambiente', '$tempAmbiente °C'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('RESULTADOS DEL CÁLCULO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellHeight: 25,
                  data: [
                    ['Resultado', 'Valor Obtenido', 'Límite Normativo'],
                    ['Capacidad (Ic)', '${ic.toStringAsFixed(1)} A', 'Ic > Id'],
                    ['Caída de Tensión', '${deltaV.toStringAsFixed(2)} V (${porcentajeDelta.toStringAsFixed(2)}%)', 'Máximo 3.0%'],
                    ['Ocupación de Ducto', ocupacionDucto ?? 'N/A', '53%/31%/40% según N° cond.'],
                  ],
                ),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Reporte_RIC04_$_fileStamp.pdf',
    );
  }

  /// REPORTE CAÍDA DE TENSIÓN MONOFÁSICA
  static Future<void> generateMonofasicaReport({
    required double largo,
    required double corriente,
    required double seccion,
    required String material,
    required double rho,
    required double vp,
    required double porcentaje,
  }) async {
    final pdf = pw.Document();
    final bool excede = porcentaje > 3.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('Caída de Tensión (1Φ)'),
                _buildVeredicto(
                  excede,
                  '✅ DENTRO DEL LÍMITE NORMATIVO (≤ 3%)',
                  '❌ EXCEDE EL LÍMITE NORMATIVO (> 3%)',
                ),
                pw.SizedBox(height: 30),
                pw.Text('DATOS DE ENTRADA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Parámetro', 'Valor'],
                    ['Longitud (L)', '$largo m'],
                    ['Corriente (I)', '$corriente A'],
                    ['Sección (S)', '$seccion mm2'],
                    ['Material / Resistividad', '$material (rho=$rho)'],
                    ['Voltaje Nominal', '220 V'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('RESULTADOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Indicador', 'Valor Obtenido'],
                    ['Caída de Tensión (VP)', '${vp.toStringAsFixed(3)} V'],
                    ['Porcentaje de Caída', '${porcentaje.toStringAsFixed(2)}%'],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Fórmula Aplicada: VP = (2 * rho * L * I) / S', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_Monofasica_$_fileStamp.pdf');
  }

  /// REPORTE CAÍDA DE TENSIÓN TRIFÁSICA
  static Future<void> generateTrifasicaReport({
    required double largo,
    required double corriente,
    required double seccion,
    required double rho,
    required double cosPhi,
    required double vp,
    required double porcentaje,
  }) async {
    final pdf = pw.Document();
    final bool excede = porcentaje > 5.0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('Caída de Tensión (3Φ)'),
                _buildVeredicto(
                  excede,
                  '✅ DENTRO DEL LÍMITE (≤ 5% Alimentador)',
                  '❌ EXCEDE EL LÍMITE NORMATIVO (> 5%)',
                ),
                pw.SizedBox(height: 30),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Datos de Entrada', 'Valor'],
                    ['Largo (L)', '$largo m'],
                    ['Corriente (I)', '$corriente A'],
                    ['Sección (S)', '$seccion mm2'],
                    ['Resistividad (rho)', rho.toString()],
                    ['Factor Potencia (cos phi)', cosPhi.toString()],
                    ['Voltaje Nominal', '380 V'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Resultado', 'Valor Obtenido'],
                    ['VP Calculado', '${vp.toStringAsFixed(3)} V'],
                    ['Porcentaje', '${porcentaje.toStringAsFixed(2)}%'],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Fórmula Aplicada: VP = (sqrt(3) * rho * L * I * cos phi) / S', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_Trifasica_$_fileStamp.pdf');
  }

  /// REPORTE OCUPACIÓN DE DUCTOS
  static Future<void> generateDuctosReport({
    required int cantidad,
    required double diametroCable,
    required String ductoNominal,
    required double ocupacion,
    required double limite,
    required bool cumple,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('Ocupación de Ductos'),
                _buildVeredicto(
                  !cumple,
                  '✅ CUMPLE NORMATIVA RIC',
                  '❌ EXCEDE CAPACIDAD PERMITIDA',
                ),
                pw.SizedBox(height: 30),
                pw.Text('DATOS DE ENTRADA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Parámetro', 'Valor'],
                    ['Cantidad de Conductores', cantidad.toString()],
                    ['Ø Exterior Cable', '$diametroCable mm'],
                    ['Ducto Seleccionado', ductoNominal],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('RESULTADOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Indicador', 'Valor Obtenido', 'Límite RIC 04'],
                    ['Ocupación Real', '${ocupacion.toStringAsFixed(1)}%', '${limite.toStringAsFixed(1)}%'],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Referencia: RIC N° 04 - Tabla de Ocupación Máxima.', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_Ductos_$_fileStamp.pdf');
  }

  /// REPORTE PUESTA A TIERRA (MALLA)
  static Future<void> generateMallaReport({
    required double rho,
    required double largo,
    required double ancho,
    required int nx,
    required int ny,
    required double resistencia,
    required double area,
    required double longitud,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader('Puesta a Tierra (Malla)'),
                pw.SizedBox(height: 20),
                pw.Text('CÁLCULO PROYECTADO (MÉTODO DE LAURENT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text('DATOS DE LA INSTALACIÓN', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Parámetro', 'Valor'],
                    ['Resistividad del Terreno (rho)', '$rho Ohm*m'],
                    ['Dimensiones (L x A)', '$largo m x $ancho m'],
                    ['Conductores (X / Y)', '$nx / $ny'],
                  ],
                ),
                pw.SizedBox(height: 30),
                pw.Text('RESULTADOS DEL PROYECTO', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(
                  data: [
                    ['Indicador', 'Valor Calculado'],
                    ['Área de la Malla', '${area.toStringAsFixed(1)} m2'],
                    ['Longitud Total Conductor', '${longitud.toStringAsFixed(1)} m'],
                    ['Resistencia de Tierra (R)', '${resistencia.toStringAsFixed(2)} Ohm'],
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('Nota: Los valores son aproximados según el método de Laurent. Se recomienda medición directa en terreno (RIC N° 06).', style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic)),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_Malla_$_fileStamp.pdf');
  }

  /// REPORTE GENÉRICO (Ley de Ohm / Corriente / Voltaje)
  static Future<void> generateGenericReport({
    required String titulo,
    required List<List<String>> datosEntrada,
    required List<List<String>> resultados,
    required String formula,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(titulo),
                pw.SizedBox(height: 20),
                pw.Text('DATOS DE ENTRADA', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(data: datosEntrada),
                pw.SizedBox(height: 30),
                pw.Text('RESULTADOS', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.TableHelper.fromTextArray(data: resultados),
                pw.SizedBox(height: 20),
                pw.Text('Fórmula: $formula', style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                _buildFooter(),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Reporte_${titulo.replaceAll(" ", "_")}_$_fileStamp.pdf');
  }
}
