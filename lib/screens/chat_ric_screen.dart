import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/providers/chat_provider.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:nom_electrica_mx/services/gemini_service.dart';
import 'package:nom_electrica_mx/screens/paywall_screen.dart';
import 'package:nom_electrica_mx/screens/pdf_viewer_screen.dart';

class ChatRicScreen extends StatefulWidget {
  const ChatRicScreen({super.key});

  @override
  State<ChatRicScreen> createState() => _ChatRicScreenState();
}

class _ChatRicScreenState extends State<ChatRicScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();

  bool _isLoading = false;

  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Historial de conversación: role = 'user' | 'model'  (Gemini no usa 'assistant')
  final List<Map<String, dynamic>> _history = [];

  // Mensajes visibles en la UI
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          '¡Hola! Soy tu Asistente IA experto en Pliegos Técnicos RIC. ¿En qué te puedo ayudar hoy?',
      'time': _formatTime(DateTime.now()),
    },
  ];

  static const String _messagesPrefsKey = 'premium_chat_messages';
  static const String _historyPrefsKey = 'premium_chat_history';

  // ─── Helpers ──────────────────────────────────────────────────────────────

  static String _formatTime(DateTime t) {
    final h = t.hour > 12
        ? t.hour - 12
        : t.hour == 0
            ? 12
            : t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  // Carga de historial para usuarios Premium
  Future<void> _loadPersistedHistory() async {
    final isPremium = context.read<PremiumProvider>().isPremium;
    if (!isPremium) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_messagesPrefsKey);
      final historyJson = prefs.getString(_historyPrefsKey);

      if (messagesJson != null && historyJson != null) {
        final List<dynamic> decodedMsgs = jsonDecode(messagesJson);
        final List<dynamic> decodedHist = jsonDecode(historyJson);

        setState(() {
          _messages.clear();
          _messages.addAll(decodedMsgs.map((e) => Map<String, dynamic>.from(e)).toList());
          _history.clear();
          _history.addAll(decodedHist.map((e) => Map<String, dynamic>.from(e)).toList());
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  // Guardado de historial para usuarios Premium
  Future<void> _savePersistedHistory() async {
    final isPremium = context.read<PremiumProvider>().isPremium;
    if (!isPremium) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_messagesPrefsKey, jsonEncode(_messages));
      await prefs.setString(_historyPrefsKey, jsonEncode(_history));
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Eliminar historial
  Future<void> _clearPersistedHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_messagesPrefsKey);
      await prefs.remove(_historyPrefsKey);
      setState(() {
        _messages.clear();
        _messages.add({
          'isUser': false,
          'text':
              '¡Hola! Soy tu Asistente IA experto en Pliegos Técnicos RIC. ¿En qué te puedo ayudar hoy?',
          'time': _formatTime(DateTime.now()),
        });
        _history.clear();
      });
    } catch (e) {
      debugPrint('Error clearing chat history: $e');
    }
  }

  // Diálogo para confirmar borrado de historial
  void _showClearHistoryDialog() {
    final brightness = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DesignTokens.getSurface(brightness),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '¿Borrar historial?',
          style: TextStyle(color: DesignTokens.getTextPrimary(brightness), fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Se eliminará la conversación actual permanentemente.',
          style: TextStyle(color: DesignTokens.getTextSecondary(brightness)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: TextStyle(color: DesignTokens.getTextSecondary(brightness))),
          ),
          TextButton(
            onPressed: () {
              _clearPersistedHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Borrar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Recortar historial para evitar consumo excesivo de tokens
  List<Map<String, dynamic>> _getPrunedHistory() {
    // Si el historial es pequeño, lo enviamos completo
    if (_history.length <= 12) return _history;
    
    // Tomamos los últimos 12 mensajes
    int start = _history.length - 12;
    
    // Nos aseguramos de que el primer mensaje del historial recortado sea de rol 'user'
    while (start < _history.length && _history[start]['role'] != 'user') {
      start++;
    }
    
    return _history.sublist(start);
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPersistedHistory();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── Scroll ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Send Logic ───────────────────────────────────────────────────────────

  /// Punto de entrada del botón Enviar y onSubmitted del TextField.
  /// Si el usuario gratuito no tiene preguntas disponibles,
  /// dispara el diálogo de desbloqueo IA (NUNCA bloqueo silencioso).
  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final isPremium = context.read<PremiumProvider>().isPremium;
    final chatProvider = context.read<ChatProvider>();

    // Usuario free sin preguntas → mostrar diálogo de desbloqueo
    if (!isPremium && !chatProvider.puedePreguntar) {
      _showAiChatAdUnlockDialog(context);
      return;
    }

    await _sendMessage(text);
  }

  Future<void> _sendMessage(String text) async {
    // Agregar mensaje del usuario al historial ANTES del setState
    _history.add({
      'role': 'user',
      'parts': [{'text': text}],
    });

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': _formatTime(DateTime.now()),
      });
      _isLoading = true;
    });

    _savePersistedHistory();
    _messageController.clear();
    _scrollToBottom();

    try {
      final String botResponse = await _geminiService.queryGeminiWithRag(
        apiKey: _apiKey,
        userQuery: text,
        prunedHistory: _getPrunedHistory(),
      );

      if (!mounted) return;

      // Guardar respuesta del modelo en el historial (role: 'model')
      _history.add({
        'role': 'model',
        'parts': [{'text': botResponse}],
      });

      // Descontar 1 pregunta SOLO después de una respuesta exitosa de la IA
      final isPremium = context.read<PremiumProvider>().isPremium;
      if (!isPremium) {
        await context.read<ChatProvider>().consumirPregunta();
      }

      if (!mounted) return;
      setState(() {
        _messages.add({
          'isUser': false,
          'text': botResponse,
          'time': _formatTime(DateTime.now()),
        });
        _isLoading = false;
      });
      _savePersistedHistory();
      _scrollToBottom();
    } on GeminiException catch (e) {
      _addErrorMessage(e.message);
    } catch (e) {
      _addErrorMessage('Error inesperado: $e');
    }
  }

  void _addErrorMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add({
        'isUser': false,
        'text': text,
        'time': _formatTime(DateTime.now()),
      });
      _isLoading = false;
    });
    _scrollToBottom();
  }

  // ─── Rewarded Ad Dialog ───────────────────────────────────────────────────

  /// Diálogo exclusivo del Chat IA para desbloquear 3 preguntas viendo un video.
  /// Se dispara ÚNICAMENTE cuando el usuario pulsa Enviar con preguntas = 0.
  void _showAiChatAdUnlockDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    bool isAdLoading = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withAlpha(190),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DesignTokens.getSurface(brightness),
                      DesignTokens.getBackground(brightness),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: DesignTokens.accent.withAlpha(100),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accent.withAlpha(30),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícono
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DesignTokens.accent.withAlpha(25),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: DesignTokens.accent.withAlpha(80)),
                      ),
                      child: const Icon(
                        Icons.smart_toy_rounded,
                        color: DesignTokens.accent,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Título
                    Text(
                      '¡Consulta gratuita agotada!',
                      style:
                          DesignTokens.getDisplay(brightness, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // Descripción
                    Text(
                      'Mira un breve video para desbloquear '
                      '3 consultas extras con el Asistente IA.',
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness),
                        fontSize: 14,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Botón: Ver video
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isAdLoading
                            ? null
                            : () {
                                setStateDialog(() => isAdLoading = true);
                                AdService.instance.showRewardedAdIa(
                                  onRewardEarned: () async {
                                    // +3 preguntas guardadas en SharedPreferences
                                    await context
                                        .read<ChatProvider>()
                                        .otorgarRecompensa();

                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.check_circle_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Text(
                                                '¡+3 preguntas desbloqueadas!',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              const Color(0xFF10B981),
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  onAdClosed: () {
                                    if (dialogContext.mounted) {
                                      setStateDialog(
                                          () => isAdLoading = false);
                                    }
                                  },
                                  onAdNotReady: () {
                                    // NO otorgar recompensa si el anuncio no está listo.
                                    // Hacerlo sería fraude de AdMob y viola las políticas de Apple.
                                    if (dialogContext.mounted) {
                                      Navigator.pop(dialogContext);
                                    }
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(
                                                Icons.wifi_off_rounded,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  'El video no está disponible ahora. Intenta en unos minutos.',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor:
                                              Colors.orangeAccent,
                                          behavior:
                                              SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                        icon: isAdLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.play_circle_fill_rounded,
                                size: 20, color: Colors.black),
                        label: Text(
                          isAdLoading
                              ? 'Cargando anuncio...'
                              : 'Ver Video y Desbloquear 🎬',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Botón: Ir al Paywall
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: isAdLoading
                            ? null
                            : () {
                                Navigator.pop(dialogContext);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const PaywallScreen()),
                                );
                              },
                        icon: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 18,
                            color: DesignTokens.accent),
                        label: const Text(
                          'Hacerse Premium (ilimitado)',
                          style: TextStyle(
                              fontSize: 13,
                              color: DesignTokens.accent,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: DesignTokens.accent.withAlpha(120)),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Cancelar
                    TextButton(
                      onPressed: isAdLoading
                          ? null
                          : () => Navigator.pop(dialogContext),
                      child: Text(
                        'Tal vez más tarde',
                        style: TextStyle(
                          color: DesignTokens.getTextSecondary(brightness)
                              .withAlpha(150),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final brightness = Theme.of(context).brightness;
    final surfaceColor = DesignTokens.getSurface(brightness);
    final bgColor = DesignTokens.getBackground(brightness);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: DesignTokens.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Asistente IA - Pliegos RIC',
                style: DesignTokens.getDisplay(brightness, fontSize: 18),
              ),
            ),
          ],
        ),
        iconTheme:
            IconThemeData(color: DesignTokens.getTextPrimary(brightness)),
        actions: [
          if (!isPremium)
            _buildQuestionBadge(brightness)
          else
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: DesignTokens.accent),
              tooltip: 'Borrar historial',
              onPressed: _showClearHistoryDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // Lista de mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _buildMessageBubble(
                  msg['text'] as String,
                  msg['isUser'] as bool,
                  msg['time'] as String,
                  brightness,
                );
              },
            ),
          ),

          // Indicador de carga de la IA
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DesignTokens.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'El inspector está analizando los pliegos…',
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(brightness),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Banner informativo cuando no quedan preguntas (NO es un bloqueador)
          if (!isPremium &&
              !context.watch<ChatProvider>().puedePreguntar)
            _buildAdUnlockBanner(brightness),

          // Área de entrada (siempre habilitada — el diálogo es la barrera)
          _buildInputArea(brightness, surfaceColor),
        ],
      ),
    );
  }

  // ─── Widgets auxiliares ───────────────────────────────────────────────────

  /// Badge compacto en el AppBar con las preguntas restantes.
  Widget _buildQuestionBadge(Brightness brightness) {
    return Consumer<ChatProvider>(
      builder: (context, chatProv, _) {
        final remaining = chatProv.preguntasRestantes;
        final color = remaining > 0
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444);

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    remaining > 0
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.lock_outline_rounded,
                    color: color,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$remaining',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Banner informativo cuando el balance de preguntas llega a 0.
  /// No bloquea el chat — solo orienta al usuario sobre cómo desbloquear.
  Widget _buildAdUnlockBanner(Brightness brightness) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.getSurface(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: DesignTokens.accent.withAlpha(120), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accent.withAlpha(25),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: DesignTokens.accent.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded,
                    color: DesignTokens.accent, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consultas Agotadas',
                      style: DesignTokens.getDisplay(brightness,
                              fontSize: 16)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pulsa Enviar para desbloquear 3 consultas extras.',
                      style: TextStyle(
                        color:
                            DesignTokens.getTextSecondary(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAiChatAdUnlockDialog(context),
              icon: const Icon(Icons.play_circle_fill_rounded,
                  size: 20, color: Colors.black),
              label: const Text(
                'Desbloquear 3 preguntas (Ver Video)',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            ),
            icon: const Icon(Icons.workspace_premium_rounded,
                size: 16, color: DesignTokens.accent),
            label: const Text(
              'Hacerse Premium para uso ilimitado',
              style: TextStyle(
                fontSize: 12,
                color: DesignTokens.accent,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Parser de etiquetas [VIEW: NOM XXX] ────────────────────────────────

  /// RegExp que captura las ocurrencias de [VIEW: NOM XXX] (ej: [VIEW: NOM 001]).
  /// También acepta el formato heredado [VIEW: RIC XX] para tolerar respuestas
  /// antiguas en historiales guardados; ambos se eliminan del texto visible.
  static final RegExp _viewTagRegExp = RegExp(
    r'\[VIEW:\s*(?:NOM|RIC)\s*(\d{1,3})\]',
    caseSensitive: false,
  );

  /// Extrae los números de norma únicos detectados en [text].
  /// Hoy solo la NOM-001 está indexada (número 1).
  List<int> _extractRicNumbers(String text) {
    final matches = _viewTagRegExp.allMatches(text);
    final seen = <int>{};
    final result = <int>[];
    for (final m in matches) {
      final num = int.tryParse(m.group(1) ?? '') ?? -1;
      if (num == 1 && seen.add(num)) {
        result.add(num);
      }
    }
    return result;
  }

  /// Elimina todas las etiquetas [VIEW: ...] del texto para no mostrárselas
  /// en bruto al usuario.
  String _removeViewTags(String text) =>
      text.replaceAll(_viewTagRegExp, '').trim();

  /// Construye el botón de navegación interna hacia el PDF de la NOM.
  /// Nota Fase 2: cuando el catálogo se reorganice por capítulos/artículos
  /// (reemplazo de RicData), este botón debe resolver contra ese catálogo.
  Widget _buildRicNavigationButton(int ricNum, Brightness brightness) {
    if (ricNum != 1) return const SizedBox.shrink();

    const String titulo = 'NOM-001-SEDE-2012';
    const Color color = Color(0xFF16A34A);
    const String label = 'Abrir $titulo: Instalaciones Eléctricas';

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PDFViewerPage(
                title: titulo,
                assetPath: 'assets/pdfs/nom001sede2012.pdf',
              ),
            ),
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded,
              size: 18, color: Colors.white),
          label: const Text(
            '📄 $label',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            shadowColor: color.withAlpha(100),
          ),
        ),
      ),
    );
  }

  // ─── Burbuja de mensaje ───────────────────────────────────────────────────

  /// Burbuja de mensaje del chat.
  Widget _buildMessageBubble(
      String text, bool isUser, String time, Brightness brightness) {
    final textColor =
        isUser ? Colors.black : DesignTokens.getTextPrimary(brightness);
    final bubbleColor = isUser
        ? DesignTokens.accent
        : DesignTokens.getCardBackground(brightness);

    // Texto limpio: quita markdown y, en mensajes de la IA, las etiquetas VIEW.
    final rawClean = text.replaceAll('**', '');
    final cleanText =
        isUser ? rawClean : _removeViewTags(rawClean);

    // Números de pliego RIC detectados (solo en mensajes de la IA)
    final ricNumbers = isUser ? <int>[] : _extractRicNumbers(rawClean);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: DesignTokens.accent.withAlpha(40),
              child: const Icon(Icons.smart_toy_rounded,
                  color: DesignTokens.accent, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: DesignTokens.getBorderColor(brightness)),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // ✅ SelectableText en burbujas de la IA para permitir
                  // selección y copia nativa en Android e iOS.
                  // En burbujas del usuario se usa Text normal (no necesitan copia).
                  if (!isUser)
                    SelectableText(
                      cleanText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    )
                  else
                    Text(
                      cleanText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),

                  // ✅ Botones de navegación interna: uno por cada RIC citado.
                  // Solo aparecen en mensajes de la IA cuando se detectan etiquetas.
                  for (final ricNum in ricNumbers)
                    _buildRicNavigationButton(ricNum, brightness),

                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                        color: textColor.withAlpha(150), fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 24),
        ],
      ),
    );
  }


  /// Área de entrada.
  /// El TextField y el botón Enviar están SIEMPRE habilitados.
  /// Si el usuario free no tiene preguntas, _handleSend() abre el diálogo.
  Widget _buildInputArea(Brightness brightness, Color surfaceColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          top:
              BorderSide(color: DesignTokens.getBorderColor(brightness)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // TextField — siempre habilitado
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: DesignTokens.getBackground(brightness),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: DesignTokens.getBorderColor(brightness)),
                ),
                child: TextField(
                  controller: _messageController,
                  enabled: !_isLoading,
                  style: TextStyle(
                      color: DesignTokens.getTextPrimary(brightness)),
                  decoration: InputDecoration(
                    hintText: 'Pregunta sobre la normativa RIC...',
                    hintStyle: TextStyle(
                      color: DesignTokens.getTextSecondary(brightness)
                          .withAlpha(150),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                  ),
                  onSubmitted: _isLoading ? null : (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Enviar — siempre visible; _handleSend() gestiona la lógica
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [Colors.grey, Colors.grey.shade400]
                      : [DesignTokens.accent, const Color(0xFF10B981)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black),
                onPressed: _isLoading ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
