import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/firebase_options.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/providers/chat_provider.dart';
import 'package:nom_electrica_mx/providers/user_profile_provider.dart';
import 'package:nom_electrica_mx/screens/login_screen.dart';
import 'package:nom_electrica_mx/screens/dashboard_screen.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:nom_electrica_mx/services/rag_service.dart';

// Claves PUBLICAS del SDK de RevenueCat (appl_... / goog_...). RevenueCat las
// disena para embeberse en el binario; el .env ya viaja dentro del IPA como
// asset plano, asi que esto no expone nada nuevo. Sirven de respaldo cuando
// el pipeline de CI no inyecta las variables en el .env (causa del
// "Servicio de suscripciones no disponible" en los builds 22-25 de TestFlight).
// IMPORTANTE: esta clave debe coincidir CARÁCTER A CARÁCTER con la
// "Public API Key" de la app iOS en el dashboard de RevenueCat (API Keys).
const String kRevenueCatIosKeyFallback = 'appl_AJAHPTMPwJKcKYheRqayOYc1hvu';
const String kRevenueCatAndroidKeyFallback = '';

void main() async {
  // 1. WidgetsFlutterBinding.ensureInitialized() at the very beginning
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enforce Edge-to-Edge UI natively on Android 15+
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Barras del sistema completamente transparentes (evita parpadeo en ROMs Android 15)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  
  // Cargar variables de entorno (.env)
  await dotenv.load(fileName: ".env");

  // Pre-cargar índice RAG en background (no bloquea el arranque de la app).
  // Cuando el usuario abra el chat, el índice ya estará listo.
  unawaited(RagService.instance.initialize());
  
  // 2. Firebase correctly initialized with await
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Habilitar persistencia offline de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 2. ATT + AdMob + restauración Premium se difieren a después del primer
  //    frame (_initAfterFirstFrame) para cumplir el SLA de arranque < 1.8 s.
  //    AdMob se inicializa una sola vez dentro de AdService.initialize().

  // 3. PurchasesConfiguration configured asynchronously BEFORE calling runApp()
  //    RevenueCat emite claves distintas por tienda:
  //      • iOS  → empieza con "appl_..."  → variable REVENUECAT_API_KEY_IOS
  //      • Android → empieza con "goog_..." → variable REVENUECAT_API_KEY_ANDROID
  //    Mezclar claves entre plataformas causa crash inmediato en iOS.
  bool isRevenueCatConfigured = false;
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // Selección de clave según plataforma
      final String rcKey;
      if (Platform.isIOS) {
        final envKey = dotenv.env['REVENUECAT_API_KEY_IOS'] ?? '';
        rcKey = envKey.isNotEmpty ? envKey : kRevenueCatIosKeyFallback;
        debugPrint('[RevenueCat] iOS → clave desde ${envKey.isNotEmpty ? ".env" : "fallback embebido"}');
      } else {
        final envKey = dotenv.env['REVENUECAT_API_KEY_ANDROID'] ?? '';
        rcKey = envKey.isNotEmpty ? envKey : kRevenueCatAndroidKeyFallback;
        debugPrint('[RevenueCat] Android → clave desde ${envKey.isNotEmpty ? ".env" : "fallback embebido"}');
      }

      if (rcKey.isNotEmpty) {
        // Si el usuario ya tiene sesión activa, lo inicializamos con su UID real
        // para evitar que quede bajo un $RCAnonymousID en el dashboard de RevenueCat.
        final firebaseUser = FirebaseAuth.instance.currentUser;
        final configuration = PurchasesConfiguration(rcKey);
        if (firebaseUser != null && !firebaseUser.isAnonymous) {
          configuration.appUserID = firebaseUser.uid;
          debugPrint('[RevenueCat] Inicializado con UID de Firebase: ${firebaseUser.uid}');
        } else {
          debugPrint('[RevenueCat] Inicializado en modo anónimo (sin sesión activa).');
        }
        await Purchases.configure(configuration);
        isRevenueCatConfigured = true;
        debugPrint('[RevenueCat] SDK configurado correctamente.');
      } else {
        final missingVar = Platform.isIOS
            ? 'REVENUECAT_API_KEY_IOS'
            : 'REVENUECAT_API_KEY_ANDROID';
        debugPrint('[CRITICAL] $missingVar no encontrada en .env → RevenueCat no se inicializará.');
      }
    } catch (e) {
      debugPrint('[RevenueCat] Error configurando SDK: $e');
    }
  }

  final premiumProvider     = PremiumProvider();
  final chatProvider        = ChatProvider();
  final userProfileProvider = UserProfileProvider();

  // 4. Antes del primer frame solo corre inicialización local y rápida
  //    (SharedPreferences). Lo que toca red se difiere a _initAfterFirstFrame.
  await chatProvider.init();
  await userProfileProvider.init(); // carga SP de forma síncrona, Firestore en background

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: premiumProvider),
        ChangeNotifierProvider.value(value: chatProvider),
        ChangeNotifierProvider.value(value: userProfileProvider),
      ],
      child: const PliegosRicApp(),
    ),
  );

  // Inicialización diferida: no bloquea el primer frame.
  unawaited(_initAfterFirstFrame(premiumProvider, isRevenueCatConfigured));
}

/// Corre después del primer frame para no bloquear el arranque (SLA < 1.8 s):
/// solicita ATT (iOS), restaura el estado Premium (llamada de red a RevenueCat)
/// y recién entonces inicializa AdMob vía AdService.updatePremiumStatus().
Future<void> _initAfterFirstFrame(
  PremiumProvider premiumProvider,
  bool isRevenueCatConfigured,
) async {
  try {
    await WidgetsBinding.instance.endOfFrame;

    if (!kIsWeb && Platform.isIOS) {
      // App Tracking Transparency (obligatorio en iOS 14+). Debe resolverse
      // ANTES de inicializar AdMob para que el SDK respete la elección.
      try {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        if (status == TrackingStatus.notDetermined) {
          await Future.delayed(const Duration(milliseconds: 200));
          await AppTrackingTransparency.requestTrackingAuthorization();
        }
      } catch (e) {
        debugPrint('[ATT] Error solicitando autorización de rastreo: $e');
      }
    }

    if (isRevenueCatConfigured) {
      await premiumProvider.init();
    } else if (!kIsWeb) {
      AdService.instance.updatePremiumStatus(false);
    }
  } catch (e) {
    debugPrint('[Bootstrap] Error en inicialización diferida: $e');
    // Ante cualquier fallo aseguramos el flujo gratuito (con anuncios).
    if (!kIsWeb) {
      AdService.instance.updatePremiumStatus(false);
    }
  }
}

class PliegosRicApp extends StatelessWidget {
  const PliegosRicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NOM ELÉCTRICA MX',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: DesignTokens.lightBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.accent,
              brightness: Brightness.light,
              surface: DesignTokens.lightSurface,
            ),
            iconTheme: const IconThemeData(
              size: 24,
              color: DesignTokens.accent,
            ),
            textTheme: TextTheme(
              displayLarge: DesignTokens.getDisplay(Brightness.light),
              bodyMedium: DesignTokens.getBody(Brightness.light),
              bodySmall: DesignTokens.getCaption(Brightness.light),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: DesignTokens.darkBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: DesignTokens.accent,
              brightness: Brightness.dark,
              surface: DesignTokens.darkSurface,
            ),
            iconTheme: const IconThemeData(
              size: 24,
              color: DesignTokens.accent,
            ),
            textTheme: TextTheme(
              displayLarge: DesignTokens.getDisplay(Brightness.dark),
              bodyMedium: DesignTokens.getBody(Brightness.dark),
              bodySmall: DesignTokens.getCaption(Brightness.dark),
            ),
          ),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  backgroundColor: DesignTokens.getBackground(
                    mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
                  ),
                  body: const Center(
                    child: CircularProgressIndicator(color: DesignTokens.accent),
                  ),
                );
              }
              if (snapshot.hasData) {
                return const DashboardScreen();
              }
              return const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
