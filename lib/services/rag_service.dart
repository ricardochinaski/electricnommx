import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Representa un fragmento de texto extraído de un Pliego RIC oficial.
class RagChunk {
  final String id;
  final String pliegoId; // Ej: "RIC 06"
  final String titulo;   // Ej: "Puesta a Tierra"
  final int pagina;
  final String texto;

  const RagChunk({
    required this.id,
    required this.pliegoId,
    required this.titulo,
    required this.pagina,
    required this.texto,
  });

  factory RagChunk.fromJson(Map<String, dynamic> json) => RagChunk(
        id: json['id'] as String,
        pliegoId: json['pliego_id'] as String,
        titulo: json['titulo'] as String,
        pagina: json['pagina'] as int,
        texto: json['texto'] as String,
      );
}

/// Resultado de una búsqueda RAG: chunk + score de relevancia.
class RagResult {
  final RagChunk chunk;
  final double score;
  const RagResult({required this.chunk, required this.score});
}

/// Servicio RAG (Retrieval-Augmented Generation).
///
/// Carga el índice de chunks generado por extract_chunks.py y expone
/// métodos de búsqueda por keyword para recuperar fragmentos reales
/// de los Pliegos RIC y construir el contexto que se inyecta a Gemini.
///
/// Uso:
///   await RagService.instance.initialize();
///   final context = await RagService.instance.buildContextFor(query);
class RagService {
  // ─── Singleton ────────────────────────────────────────────────────────────

  static RagService? _instance;
  static RagService get instance => _instance ??= RagService._();
  RagService._();

  // ─── Estado ───────────────────────────────────────────────────────────────

  List<RagChunk> _chunks = [];
  bool _isLoaded = false;
  bool _isLoading = false;

  bool get isReady => _isLoaded;

  // ─── Stopwords en español (ignoradas en el scoring) ───────────────────────

  static const _stopwords = {
    'de', 'la', 'el', 'en', 'y', 'a', 'los', 'del', 'las', 'un',
    'una', 'con', 'por', 'para', 'que', 'se', 'es', 'al', 'lo',
    'su', 'sus', 'o', 'u', 'no', 'si', 'son', 'ya', 'más', 'este',
    'esta', 'como', 'entre', 'ser', 'debe', 'puede', 'cuando',
    'cada', 'todo', 'toda', 'hay', 'han', 'sin', 'sobre',
  };

  // ─── Inicialización ───────────────────────────────────────────────────────

  /// Carga el índice JSON desde assets. Seguro de llamar múltiples veces.
  Future<void> initialize() async {
    if (_isLoaded || _isLoading) return;
    _isLoading = true;

    try {
      final jsonStr =
          await rootBundle.loadString('assets/rag/rag_chunks.json');

      // Parsear en un isolate para no bloquear el UI thread
      final List<dynamic> data = await compute(_parseJson, jsonStr);

      _chunks = data
          .map((e) => RagChunk.fromJson(e as Map<String, dynamic>))
          .toList();

      _isLoaded = true;
      debugPrint('[RAG] ✅ Índice cargado: ${_chunks.length} chunks');
    } catch (e) {
      debugPrint('[RAG] ❌ Error cargando índice: $e');
    } finally {
      _isLoading = false;
    }
  }

  static List<dynamic> _parseJson(String jsonStr) => jsonDecode(jsonStr);

  // ─── Tokenización ─────────────────────────────────────────────────────────

  /// Tokeniza texto: minúsculas, sin puntuación, sin stopwords cortas.
  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\wáéíóúüñ\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3 && !_stopwords.contains(w))
        .toList();
  }

  // ─── Búsqueda por keyword (TF-IDF simplificado) ───────────────────────────

  /// Busca los [topK] chunks más relevantes para [query] usando keyword matching.
  ///
  /// El score se calcula como:
  ///   - +2 por cada token de la query que aparece en el chunk
  ///   - +1 extra si el token aparece más de una vez (frecuencia)
  ///   - Normalizado por longitud del chunk para evitar favorecer textos largos
  List<RagResult> search(String query, {int topK = 5}) {
    if (!_isLoaded || _chunks.isEmpty) return [];

    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return [];

    final results = <RagResult>[];

    for (final chunk in _chunks) {
      final chunkTokens = _tokenize(chunk.texto);
      if (chunkTokens.isEmpty) continue;

      double score = 0;
      for (final token in queryTokens) {
        final count = chunkTokens.where((t) => t == token).length;
        if (count > 0) {
          score += 2 + (count > 1 ? 1 : 0);
        }
      }

      if (score > 0) {
        // Normalizar: favorece chunks con alta densidad de términos relevantes
        final normalizedScore = score / sqrt(chunkTokens.length.toDouble());
        results.add(RagResult(chunk: chunk, score: normalizedScore));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(topK).toList();
  }

  // ─── Construcción del contexto ────────────────────────────────────────────

  /// Busca los chunks más relevantes para [query] y los formatea como
  /// contexto listo para inyectar en el system prompt de Gemini.
  ///
  /// Retorna una cadena vacía si el índice no está cargado o no hay resultados.
  String buildContextFor(String query, {int topK = 5}) {
    final results = search(query, topK: topK);
    if (results.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln(
        '=== TEXTO OFICIAL EXTRAÍDO DE LOS PLIEGOS SEC CHILE ===');
    buffer.writeln(
        'INSTRUCCIÓN CRÍTICA: Responde usando ÚNICAMENTE la información de estos fragmentos.');
    buffer.writeln(
        'Si el fragmento no responde la pregunta, dilo honestamente. NUNCA inventes artículos.');
    buffer.writeln();

    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      final c = r.chunk;
      buffer.writeln(
          '--- Fuente ${i + 1}: ${c.pliegoId} — ${c.titulo} (pág. ${c.pagina}) ---');
      buffer.writeln(c.texto);
      buffer.writeln();
    }

    buffer.writeln('=== FIN DEL TEXTO OFICIAL ===');
    return buffer.toString();
  }

  // ─── Diagnóstico ──────────────────────────────────────────────────────────

  /// Retorna estadísticas de carga para depuración.
  Map<String, dynamic> get stats => {
        'loaded': _isLoaded,
        'totalChunks': _chunks.length,
        'pliegos': _chunks.map((c) => c.pliegoId).toSet().length,
      };
}
