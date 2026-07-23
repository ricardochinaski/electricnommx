// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Generador del índice RAG para NOM Eléctrica MX.
///
/// Corre como test de Flutter (igual que en la app chilena madre):
///   flutter test test/extract_chunks_test.dart
///
/// Lee los PDF normativos mexicanos de assets/pdfs y produce
/// assets/rag/rag_chunks.json con la MISMA estructura de chunk que
/// consume RagService: {id, pliego_id, titulo, pagina, texto}.
/// El campo se sigue llamando pliego_id por compatibilidad con el
/// servicio heredado; para México contiene el identificador de la norma.
void main() {
  test('Generate RAG Chunks (NOM Mexico)', () async {
    const int chunkSize = 400; // palabras por chunk
    const int chunkOverlap = 60; // palabras de solapamiento
    const int minChunkWords = 30; // ignorar chunks más pequeños
    const String pdfDir = 'assets/pdfs';
    const String outputPath = 'assets/rag/rag_chunks.json';

    // Catálogo de documentos normativos mexicanos a indexar.
    // Al agregar nuevos PDF (NOM-007-ENER, specs CFE, etc.), sumarlos aquí.
    final List<Map<String, dynamic>> normas = [
      {
        'id': 'NOM-001',
        'titulo': 'NOM-001-SEDE-2012 Instalaciones Eléctricas (utilización)',
        'file': 'nom001sede2012.pdf',
      },
    ];

    String cleanText(String text) {
      var clean = text.replaceAll(RegExp(r'\n{2,}'), '\n');
      clean = clean.replaceAll(RegExp(r'[ \t]+'), ' ');
      clean = clean.replaceAll(RegExp(r'\n\s*\d+\s*\n'), '\n');
      // Encabezado repetido del DOF en cada página del PDF de la NOM
      // (ej: "19/11/2019 SENER www.dof.gob.mx/normasOficiales/... /")
      clean = clean.replaceAll(
        RegExp(r'\d{1,2}/\d{1,2}/\d{4}\s+SENER\s+www\.dof\.gob\.mx\S*\s*/?\s*'),
        ' ',
      );
      return clean.trim();
    }

    List<String> chunkText(String text) {
      final List<String> words = text.split(RegExp(r'\s+'));
      final List<String> chunks = [];
      int i = 0;
      while (i < words.length) {
        int end = i + chunkSize;
        if (end > words.length) {
          end = words.length;
        }
        final chunkWords = words.sublist(i, end);
        final chunk = chunkWords.join(' ');
        if (chunkWords.length >= minChunkWords) {
          chunks.add(chunk);
        }
        i += (chunkSize - chunkOverlap);
      }
      return chunks;
    }

    print('============================================================');
    print('  RAG Extractor (Flutter Test) — NOM Eléctrica MX');
    print('============================================================');

    final outputDir = Directory('assets/rag');
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final List<Map<String, dynamic>> allChunks = [];
    int totalPages = 0;

    for (final norma in normas) {
      final String normaId = norma['id'] as String;
      final String titulo = norma['titulo'] as String;
      final String filename = norma['file'] as String;
      final String pdfPath = '$pdfDir/$filename';

      final file = File(pdfPath);
      if (!file.existsSync()) {
        print('⚠️  No encontrado: $pdfPath');
        continue;
      }

      try {
        final bytes = file.readAsBytesSync();
        final PdfDocument document = PdfDocument(inputBytes: bytes);
        int chunksCount = 0;
        final int pages = document.pages.count;
        totalPages += pages;

        for (int pageNum = 0; pageNum < pages; pageNum++) {
          final String pageText = PdfTextExtractor(document)
              .extractText(startPageIndex: pageNum, endPageIndex: pageNum);

          if (pageText.trim().isEmpty) continue;

          final cleaned = cleanText(pageText);
          final pageChunks = chunkText(cleaned);

          for (int chunkIdx = 0; chunkIdx < pageChunks.length; chunkIdx++) {
            allChunks.add({
              'id': '${normaId.replaceAll("-", "")}_p${pageNum + 1}_c$chunkIdx',
              'pliego_id': normaId,
              'titulo': titulo,
              'pagina': pageNum + 1,
              'texto': pageChunks[chunkIdx],
            });
            chunksCount++;
          }
        }

        document.dispose();
        print('✅ $normaId — $titulo: $chunksCount chunks ($pages páginas)');
        if (chunksCount == 0) {
          print('❗ 0 chunks extraídos: el PDF podría ser escaneado (imágenes '
              'sin capa de texto). Requeriría OCR antes de indexarse.');
        }
      } catch (e) {
        print('❌ Error procesando $pdfPath: $e');
      }
    }

    final outputFile = File(outputPath);
    final jsonString = const JsonEncoder.withIndent('  ').convert(allChunks);
    outputFile.writeAsStringSync(jsonString, encoding: utf8);

    final double sizeKb = outputFile.lengthSync() / 1024;
    print('');
    print('============================================================');
    print('🎉 Total chunks generados : ${allChunks.length}');
    print('📄 Total páginas procesadas: $totalPages');
    print('💾 Archivo generado        : $outputPath');
    print('📦 Tamaño                  : ${sizeKb.toStringAsFixed(1)} KB');
    print('============================================================');
    expect(allChunks.isNotEmpty, true,
        reason: 'No se extrajo ningún chunk: revisar que el PDF tenga capa de '
            'texto (no sea un escaneo) y que exista en assets/pdfs.');
  });
}
