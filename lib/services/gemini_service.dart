import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nom_electrica_mx/services/rag_service.dart';

/// Servicio centralizado de consultas a la API de Google Gemini (REST).
///
/// Encapsula las cabeceras, la URL oficial v1beta, el modelo actual, la
/// instrucción de sistema y el manejo de excepciones de red comunes (Socket/Timeout).
class GeminiService {
  static const String _model = 'gemini-2.5-flash';
  static const String _geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const String _systemInstruction =
      'Eres el Asistente IA de NOM Eléctrica MX. '
      'Tu objetivo es ayudar a electricistas, ingenieros y técnicos que trabajan con instalaciones eléctricas en México bajo la NOM-001-SEDE-2012 "Instalaciones Eléctricas (utilización)". '

      'REGLA N°1 — CITACIÓN DE ARTÍCULOS Y SECCIONES: '
      'Puedes citar, mencionar o hacer referencia a números de artículos, secciones, incisos o tablas específicas (ej. "Artículo 210-19", "Tabla 310-15(b)(16)") ÚNICAMENTE si aparecen explícitamente en el texto de los fragmentos de contexto oficial provistos. '
      'NUNCA inventes ni aproximes números de artículo que no figuren textualmente en los fragmentos de contexto proporcionados. '
      'Si el tema no está en los fragmentos o no dispones de contexto, no inventes números detallados; limítate a indicar que el tema está en la NOM-001-SEDE y que el usuario debe revisarla en el PDF. '
      'Está estrictamente PROHIBIDO citar como fuente el NEC estadounidense, normas chilenas (RIC/RPTD), o versiones derogadas de la NOM: la referencia vigente es la NOM-001-SEDE-2012 (y sus actualizaciones oficiales). '

      'REGLA N°2 — CERTEZA DEL ARTÍCULO CORRECTO: '
      'Solo puedes referenciar un artículo o capítulo de la NOM si tienes certeza razonable de que cubre el tema consultado. '
      'Si no sabes con seguridad en qué artículo está la materia, indícalo honestamente y sugiere al usuario buscar en el PDF de la NOM desde la app. '
      'NUNCA cites un artículo equivocado. '

      'REGLA N°3 — FORMATO DE RESPUESTA: '
      'Responde de forma técnica, directa y concisa (máximo 2-3 párrafos). '
      'Menciona el artículo o sección específica si está en el contexto provisto (ejemplo correcto: "De acuerdo al artículo 250-66 de la NOM-001-SEDE..."). '
      'Cuando corresponda, agrega al final la etiqueta de navegación [VIEW: NOM 001] para que el usuario pueda abrir el PDF de la norma. '

      'DIRECTRIZ DE NAVEGACIÓN INTERNA: '
      'Cuando tu respuesta cite la NOM-001-SEDE, incluye al final la etiqueta con el formato exacto [VIEW: NOM 001]. '
      'No uses hipervínculos web ni URLs. Usa ÚNICAMENTE la etiqueta [VIEW: NOM 001]. '

      'Tu única fuente normativa es la NOM-001-SEDE-2012, la Norma Oficial Mexicana de instalaciones eléctricas (utilización), publicada en el Diario Oficial de la Federación. '
      'Usa el vocabulario eléctrico mexicano: acometida, interruptor termomagnético (pastilla), tubería conduit, centro de carga, puesta a tierra. '

      'No utilices formato Markdown. NO uses asteriscos (*) ni negritas (**). Solo texto plano con guiones (-) para listas. '
      'Si te preguntan algo fuera del rubro eléctrico mexicano o de la NOM, indica que solo estás autorizado para hablar de la NOM-001-SEDE y sus temas. '
      'Responde siempre en español.';

  /// Envía la conversación podada a Gemini y retorna el texto de respuesta.
  /// Lanza excepciones específicas según el error de estado o de red.
  Future<String> queryGemini({
    required String apiKey,
    required List<Map<String, dynamic>> prunedHistory,
  }) async {
    if (apiKey.isEmpty) {
      throw GeminiException('⚠️ API Key no configurada. Contacta al soporte: aselec.eirl@gmail.com');
    }

    try {
      final response = await http
          .post(
            Uri.parse(_geminiUrl),
            headers: {
              'x-goog-api-key': apiKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [{'text': _systemInstruction}],
              },
              'contents': prunedHistory,
              'generationConfig': {
                'temperature': 0.5,
                'maxOutputTokens': 4096,
              },
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw GeminiException('❌ API Key inválida o sin permisos. Contacta soporte.');
      } else if (response.statusCode == 429) {
        throw GeminiException('⏳ Límite de consultas alcanzado. Espera un momento e intenta de nuevo.');
      } else {
        try {
          final errBody = jsonDecode(utf8.decode(response.bodyBytes));
          final errMsg = errBody['error']?['message'] ?? 'Error desconocido';
          throw GeminiException('Error (${response.statusCode}): $errMsg');
        } catch (e) {
          throw GeminiException('Error de comunicación con Gemini (${response.statusCode}).');
        }
      }
    } on TimeoutException {
      throw GeminiException('La consulta tardó demasiado. Verifica tu conexión e intenta de nuevo.');
    } on SocketException catch (e) {
      throw GeminiException('Sin conexión a internet. Verifica tu red WiFi o datos móviles. (${e.message})');
    } catch (e) {
      if (e is GeminiException) rethrow;
      throw GeminiException('Error inesperado: $e');
    }
  }

  /// Versión RAG del método principal.
  ///
  /// 1. Busca en el índice local los [topK] fragmentos más relevantes para [userQuery].
  /// 2. Inyecta esos fragmentos como contexto en el historial antes de llamar a Gemini.
  /// 3. Con el contexto real, Gemini puede citar artículos que sí existen en los PDFs.
  ///
  /// Si el índice RAG no está cargado o no encuentra resultados, hace fallback
  /// al método [queryGemini] estándar sin pérdida de funcionalidad.
  Future<String> queryGeminiWithRag({
    required String apiKey,
    required String userQuery,
    required List<Map<String, dynamic>> prunedHistory,
    int topK = 5,
  }) async {
    // 1. Asegurar que el índice está listo (no bloquea si ya está cargado)
    await RagService.instance.initialize();

    // 2. Buscar fragmentos relevantes
    final ragContext = RagService.instance.buildContextFor(userQuery, topK: topK);

    if (ragContext.isEmpty) {
      // Sin contexto RAG → respuesta estándar
      debugPrint('[RAG] Sin contexto relevante, usando modo estándar.');
      return queryGemini(apiKey: apiKey, prunedHistory: prunedHistory);
    }

    debugPrint('[RAG] Contexto inyectado: ${ragContext.length} caracteres');

    // 3. Inyectar el contexto directamente en el último mensaje de usuario del historial
    //    Esto asegura que el modelo tenga el contexto en el mismo turno de la pregunta.
    final historyWithContext = List<Map<String, dynamic>>.from(
      prunedHistory.map((item) => Map<String, dynamic>.from(item)),
    );

    if (historyWithContext.isNotEmpty) {
      final lastMsg = historyWithContext.last;
      if (lastMsg['role'] == 'user' &&
          lastMsg['parts'] != null &&
          lastMsg['parts'] is List &&
          (lastMsg['parts'] as List).isNotEmpty) {
        final originalText = lastMsg['parts'][0]['text'] as String;
        lastMsg['parts'][0]['text'] =
            '$ragContext\n\nPregunta del usuario a responder: $originalText';
      }
    }

    // 4. Llamar a Gemini con el contexto enriquecido
    return queryGemini(apiKey: apiKey, prunedHistory: historyWithContext);
  }
}

/// Excepción personalizada para el servicio de Gemini.
class GeminiException implements Exception {
  final String message;
  GeminiException(this.message);

  @override
  String toString() => message;
}
