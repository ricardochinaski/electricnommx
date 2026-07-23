import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider que gestiona el contador de preguntas gratuitas del Chat IA.
///
/// - El usuario gratuito inicia con 1 pregunta disponible.
/// - Cada pregunta enviada decrementa el contador.
/// - Ver un RewardedAd otorga +3 preguntas.
/// - Los usuarios Premium ignoran este contador (ilimitado).
/// - El estado persiste localmente con SharedPreferences.
class ChatProvider extends ChangeNotifier {
  static const String _storageKey = 'ai_questions_balance';
  static const int _initialQuestions = 1;
  static const int _rewardQuestions = 3;

  int _preguntasRestantes = _initialQuestions;

  /// Preguntas restantes del usuario gratuito.
  int get preguntasRestantes => _preguntasRestantes;

  /// `true` si el usuario puede enviar al menos una pregunta.
  bool get puedePreguntar => _preguntasRestantes > 0;

  /// Inicializa el provider cargando el contador desde disco.
  /// Debe llamarse una vez al crear la instancia.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _preguntasRestantes = prefs.getInt(_storageKey) ?? _initialQuestions;
      debugPrint('[ChatProvider] Preguntas restantes restauradas: $_preguntasRestantes');
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Error restaurando preguntas: $e');
    }
  }

  /// Consume una pregunta del contador. Retorna `true` si se pudo consumir.
  /// Retorna `false` si no hay preguntas disponibles (debe mostrar ad-wall).
  Future<bool> consumirPregunta() async {
    if (_preguntasRestantes <= 0) return false;

    _preguntasRestantes--;
    await _guardar();
    notifyListeners();
    debugPrint('[ChatProvider] Pregunta consumida. Restantes: $_preguntasRestantes');
    return true;
  }

  /// Otorga +3 preguntas como recompensa por ver un anuncio.
  Future<void> otorgarRecompensa() async {
    _preguntasRestantes += _rewardQuestions;
    await _guardar();
    notifyListeners();
    debugPrint('[ChatProvider] Recompensa: +$_rewardQuestions preguntas. Total: $_preguntasRestantes');
  }

  /// (DEBUG) Resetea el contador al valor inicial.
  Future<void> resetPreguntas() async {
    _preguntasRestantes = _initialQuestions;
    await _guardar();
    notifyListeners();
    debugPrint('[ChatProvider] Contador reseteado a: $_preguntasRestantes');
  }

  /// Persiste el contador actual en SharedPreferences.
  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_storageKey, _preguntasRestantes);
    } catch (e) {
      debugPrint('[ChatProvider] Error guardando preguntas: $e');
    }
  }
}
