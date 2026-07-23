import 'dart:convert' show utf8;
import 'package:crypto/crypto.dart' show sha256;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:purchases_flutter/purchases_flutter.dart';

// Web Client ID obtenido desde:
// Firebase Console → Authentication → Sign-in method → Google → Web SDK configuration
const String _webClientId = '276605821197-4c3a556cff3tue6oml8tgfsafuvsrtoq.apps.googleusercontent.com';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // En Windows/Web se necesita clientId; en Android lo toma del google-services.json
  GoogleSignIn get _googleSignIn => (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)
      ? GoogleSignIn(clientId: _webClientId)
      : GoogleSignIn();


  /// Vincula el UID de Firebase con RevenueCat (solo en móviles).
  Future<void> _syncRevenueCat(User? user) async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (user == null) return;
    try {
      if (!await Purchases.isConfigured) {
        debugPrint('[AuthService] RevenueCat no está configurado; se omite logIn.');
        return;
      }
      await Purchases.logIn(user.uid);
      debugPrint('[AuthService] RevenueCat vinculado con UID: ${user.uid}');
    } catch (e) {
      debugPrint('[AuthService] Error vinculando RevenueCat: $e');
    }
  }

  /// Iniciar sesión como invitado (anónimo)
  Future<String?> signInAnonymously() async {
    try {
      final cred = await _auth.signInAnonymously();
      // Los invitados usan $RCAnonymousID, NO llamamos logIn aquí
      // para que RevenueCat maneje el anonimato de forma nativa.
      debugPrint('[AuthService] Sesión anónima iniciada: ${cred.user?.uid}');
      return null; // null = éxito
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] signInAnonymously error: ${e.code} - ${e.message}');
      return _getFriendlyMessage(e.code);
    } catch (e) {
      debugPrint('[AuthService] signInAnonymously error general: $e');
      return 'Error inesperado al entrar como invitado.';
    }
  }

  /// Iniciar sesión con Google (API v6 estable)
  Future<String?> signInWithGoogle() async {
    try {
      // 1. Abrir selector de cuenta de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return 'Inicio de sesión cancelado.';

      // 2. Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Crear credencial de Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Iniciar sesión en Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      // 5. Vincular con RevenueCat usando el UID real de Firebase
      await _syncRevenueCat(userCredential.user);

      return null; // null = éxito
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] signInWithGoogle FirebaseAuthException: ${e.code} - ${e.message}');
      return _getFriendlyMessage(e.code);
    } catch (e) {
      debugPrint('[AuthService] signInWithGoogle error general: $e');
      return 'Error al conectar con Google: $e';
    }
  }

  /// Genera el hash SHA-256 de un string (usado para el nonce de Apple).
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Iniciar sesión con Apple (requerido por Guideline 4.8 de Apple al
  /// ofrecer Google Sign-In como login de terceros).
  Future<String?> signInWithApple() async {
    try {
      // 1. Generar nonce aleatorio crudo y su hash SHA-256.
      //    El hash se envía a Apple; el crudo se envía a Firebase para que
      //    pueda verificar que coincide con el que viene embebido en el
      //    identityToken (protección contra ataques de repetición).
      final rawNonce = generateNonce();
      final hashedNonce = _sha256ofString(rawNonce);

      // 2. Solicitar la credencial nativa de Apple.
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      // 3. Crear credencial de Firebase con el idToken + nonce crudo + authorizationCode.
      //    Sin accessToken (authorizationCode), Firebase rechaza la credencial
      //    con "invalid-credential" aunque el idToken y el nonce sean válidos.
      final credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      // 4. Iniciar sesión en Firebase.
      final userCredential = await _auth.signInWithCredential(credential);

      // 5. Vincular con RevenueCat usando el UID real de Firebase.
      await _syncRevenueCat(userCredential.user);

      return null; // null = éxito
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return 'Inicio de sesión cancelado.';
      }
      debugPrint('[AuthService] signInWithApple authorization error: ${e.code} - ${e.message}');
      return 'Error al conectar con Apple: ${e.message}';
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] signInWithApple FirebaseAuthException: ${e.code} - ${e.message}');
      if (e.code == 'invalid-credential') {
        return 'No se pudo validar tu cuenta de Apple con el servidor. Revisa la configuración de Sign in with Apple en Firebase Console.';
      }
      return _getFriendlyMessage(e.code);
    } catch (e) {
      debugPrint('[AuthService] signInWithApple error general: $e');
      return 'Error al conectar con Apple: $e';
    }
  }

  /// Iniciar sesión con correo y contraseña
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Vincular con RevenueCat usando el UID real de Firebase
      await _syncRevenueCat(userCredential.user);

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] signInWithEmail error: ${e.code}');
      return _getFriendlyMessage(e.code);
    } catch (e) {
      debugPrint('[AuthService] signInWithEmail error general: $e');
      return 'Error inesperado al iniciar sesión.';
    }
  }

  /// Registrar nuevo usuario con correo y contraseña
  Future<String?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Vincular con RevenueCat usando el UID real de Firebase
      await _syncRevenueCat(userCredential.user);

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] registerWithEmail error: ${e.code}');
      return _getFriendlyMessage(e.code);
    } catch (e) {
      debugPrint('[AuthService] registerWithEmail error general: $e');
      return 'Error inesperado al crear la cuenta.';
    }
  }

  /// Cerrar sesión (Firebase + Google + RevenueCat)
  Future<void> signOut() async {
    // 1. Cerrar sesión en Google y Firebase
    await _googleSignIn.signOut();
    await _auth.signOut();

    // 2. Desvincular de RevenueCat y generar nuevo ID anónimo limpio
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        await Purchases.logOut();
        debugPrint('[AuthService] RevenueCat desvinculado correctamente.');
      } catch (e) {
        debugPrint('[AuthService] Error desvinculando RevenueCat: $e');
      }
    }
  }

  /// Traduce códigos de error de Firebase a mensajes en español
  String _getFriendlyMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta. Intenta de nuevo.';
      case 'invalid-credential':
        return 'Credenciales inválidas. Verifica tu correo y contraseña.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'sign_in_failed':
        return 'Fallo en Google Sign-In. ¿Está registrado el SHA-1 en Firebase?';
      default:
        return 'Error: $code. Contacta al soporte técnico.';
    }
  }
}

