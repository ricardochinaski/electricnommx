
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fuente única de verdad para el perfil del usuario instalador:
/// nombre, cargo/ocupación e índice de avatar.
///
/// Arquitectura de persistencia (dos capas):
///   1. SharedPreferences → disponible offline, sin latencia.
///   2. Firestore          → sincronización multi-dispositivo.
///
/// El método [init] primero carga desde SharedPreferences (síncrono en práctica),
/// luego dispara una actualización desde Firestore en segundo plano.
///
/// Uso desde cualquier widget:
///   ```dart
///   final profile = context.read<UserProfileProvider>();
///   final nombre  = profile.nombre;    // lectura reactiva con watch<>
///   final cargo   = profile.cargo;
///   ```
class UserProfileProvider extends ChangeNotifier {
  // ─── Claves SharedPreferences ───────────────────────────────────────────
  static const String _keyNombre      = 'profileNombre';
  static const String _keyCargo       = 'profileCargo';
  static const String _keyAvatarIndex = 'avatarIndex';
  static const String _keyLastUpdated = 'profileLastUpdated';

  // ─── Estado interno ─────────────────────────────────────────────────────
  String _nombre      = '';
  String _cargo       = '';
  int    _avatarIndex = 0;
  int    _lastUpdated = 0;
  bool   _isLoading   = false;

  // ─── Getters públicos ────────────────────────────────────────────────────
  String get nombre      => _nombre;
  String get cargo       => _cargo;
  int    get avatarIndex => _avatarIndex;
  int    get lastUpdated => _lastUpdated;
  bool   get isLoading   => _isLoading;

  /// Nombre para mostrar: usa el nombre guardado o un fallback legible.
  String get displayName =>
      _nombre.isNotEmpty ? _nombre : 'Instalador';

  /// Cargo para mostrar: usa el cargo guardado o indica que no está definido.
  String get displayCargo =>
      _cargo.isNotEmpty ? _cargo : 'no especificado';

  // ─── Inicialización ─────────────────────────────────────────────────────

  /// Carga el perfil en dos fases:
  ///   1. SharedPreferences (inmediato, sin internet).
  ///   2. Firestore en background para refrescar si hay conexión.
  Future<void> init() async {
    await _loadFromPrefs();
    _refreshFromFirestore(); // no esperamos: corre en background
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nombre      = prefs.getString(_keyNombre)      ?? '';
      _cargo       = prefs.getString(_keyCargo)       ?? '';
      _avatarIndex = prefs.getInt(_keyAvatarIndex)    ?? 0;
      _lastUpdated = prefs.getInt(_keyLastUpdated)    ?? 0;
      notifyListeners();
      debugPrint('[UserProfileProvider] Cargado desde SP → nombre: $_nombre | cargo: $_cargo | timestamp: $_lastUpdated');
    } catch (e) {
      debugPrint('[UserProfileProvider] Error leyendo SharedPreferences: $e');
    }
  }

  Future<void> _refreshFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 6));

      if (!doc.exists) return;
      final data = doc.data()!;

      final fsNombre    = (data['nombre'] as String? ?? '').trim();
      final fsCargo     = (data['cargo']  as String? ?? '').trim();
      final fsAvatar    = (data['avatarIndex'] as int?) ?? _avatarIndex;
      final fsTimestamp = data['fecha_actualizacion'] as int? ?? 0;

      final prefs = await SharedPreferences.getInstance();
      final localTimestamp = prefs.getInt(_keyLastUpdated) ?? 0;

      // Solo actualizar si Firestore tiene datos más recientes
      if (fsTimestamp > localTimestamp) {
        _nombre      = fsNombre;
        _cargo       = fsCargo;
        _avatarIndex = fsAvatar;
        _lastUpdated = fsTimestamp;
        notifyListeners();

        // Mantener SP sincronizado con Firestore
        await Future.wait([
          prefs.setString(_keyNombre,      _nombre),
          prefs.setString(_keyCargo,       _cargo),
          prefs.setInt(_keyAvatarIndex,    _avatarIndex),
          prefs.setInt(_keyLastUpdated,    _lastUpdated),
        ]);
        debugPrint('[UserProfileProvider] Actualizado desde Firestore → nombre: $_nombre | cargo: $_cargo (timestamp: $fsTimestamp > $localTimestamp)');
      } else if (localTimestamp > fsTimestamp && localTimestamp > 0) {
        // Si el estado local es más nuevo, sincronizar local -> Firestore
        debugPrint('[UserProfileProvider] Local es más nuevo ($localTimestamp > $fsTimestamp). Sincronizando local a Firestore...');
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({
              'nombre'              : _nombre,
              'cargo'               : _cargo,
              'avatarIndex'         : _avatarIndex,
              'fecha_actualizacion' : localTimestamp,
            }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[UserProfileProvider] Firestore no disponible o al sincronizar en background: $e');
    }
  }

  // ─── Actualización de campos ─────────────────────────────────────────────

  /// Actualiza el avatar localmente (sin Firestore) para respuesta instantánea.
  /// Se sincronizará con Firestore en el próximo [guardar].
  Future<void> setAvatarIndex(int index) async {
    if (_avatarIndex == index) return;
    _avatarIndex = index;
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastUpdated = now;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyAvatarIndex, index);
      await prefs.setInt(_keyLastUpdated, now);
    } catch (e) {
      debugPrint('[UserProfileProvider] Error guardando avatarIndex: $e');
    }
  }

  // ─── Guardado completo ───────────────────────────────────────────────────

  /// Guarda nombre, cargo y avatar.
  /// Siempre persiste en SharedPreferences primero (offline-safe).
  /// Intenta sincronizar con Firestore con timeout de 4 s.
  ///
  /// Devuelve [ProfileSaveResult] para que la UI pueda reaccionar
  /// sin acoplarse a la lógica de guardado.
  Future<ProfileSaveResult> guardar({
    required String nombre,
    required String cargo,
    required int avatarIndex,
  }) async {
    // Validación mínima
    if (nombre.trim().isEmpty && cargo.trim().isEmpty) {
      return ProfileSaveResult.emptyFields;
    }

    _isLoading = true;
    notifyListeners();

    final trimNombre  = nombre.trim();
    final trimCargo   = cargo.trim();
    final now = DateTime.now().millisecondsSinceEpoch;

    try {
      // ── Capa 1: SharedPreferences (siempre funciona, sin red) ──
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_keyNombre,   trimNombre),
        prefs.setString(_keyCargo,    trimCargo),
        prefs.setInt(_keyAvatarIndex, avatarIndex),
        prefs.setInt(_keyLastUpdated, now),
      ]);

      // Actualizar estado en memoria inmediatamente
      _nombre      = trimNombre;
      _cargo       = trimCargo;
      _avatarIndex = avatarIndex;
      _lastUpdated = now;
      notifyListeners(); // UI responde al instante

      // ── Capa 2: Firestore (fire-and-forget) ──
      // Con persistenceEnabled=true, Firestore escribe en caché local
      // y sincroniza al servidor automáticamente cuando hay internet.
      // NO usamos await ni timeout para no bloquear la UI.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set({
              'nombre'              : trimNombre,
              'cargo'               : trimCargo,
              'avatarIndex'         : avatarIndex,
              'fecha_actualizacion' : now,
            }, SetOptions(merge: true))
            .then((_) {
              debugPrint('[UserProfileProvider] ✓ Perfil sincronizado con Firestore.');
            })
            .catchError((e) {
              // Firestore offline persistence reintentará automáticamente.
              debugPrint('[UserProfileProvider] Firestore pendiente (sin red). Se sincronizará al reconectar. Error: $e');
            });
        return ProfileSaveResult.syncedOnline;
      }

      return ProfileSaveResult.savedLocally;
    } catch (e) {
      debugPrint('[UserProfileProvider] Error guardando perfil: $e');
      return ProfileSaveResult.error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Reset (logout) ──────────────────────────────────────────────────────

  /// Limpia el estado en memoria (no borra SharedPreferences).
  /// Llamar al cerrar sesión si se quiere que el próximo usuario empiece limpio.
  void reset() {
    _nombre      = '';
    _cargo       = '';
    _avatarIndex = 0;
    _lastUpdated = 0;
    notifyListeners();
  }
}

/// Resultado del método [UserProfileProvider.guardar].
enum ProfileSaveResult {
  syncedOnline,   // Guardado en SP + Firestore exitosamente
  savedLocally,   // Guardado solo en SP (sin red o sin sesión)
  emptyFields,    // Nombre y cargo están vacíos
  error,          // Error inesperado
}
