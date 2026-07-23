import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';

/// Servicio centralizado de gestión de anuncios (Interstitial + Rewarded).
///
/// Maneja la inicialización del SDK, precarga automática, reintentos y
/// limpieza de memoria. Toda la lógica respeta el estado Premium del usuario.
class AdService {
  // ───────── Singleton ─────────
  static final AdService instance = AdService._internal();
  factory AdService() => instance;
  AdService._internal();

  // ───────── Ad Unit IDs — separados por plataforma ─────────
  // iOS:     ca-app-pub-XXXXXXXX/iOS_UNIT_ID
  // Android: ca-app-pub-XXXXXXXX/ANDROID_UNIT_ID
  String get _interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6408666343364043/8979285475'   // Android
      : 'ca-app-pub-6408666343364043/4451713065';   // iOS

  String get _rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6408666343364043/2765996223'    // Android
      : 'ca-app-pub-6408666343364043/9889696401';   // iOS

  String get _rewardedAdIaUnitId => Platform.isAndroid
      ? 'ca-app-pub-6408666343364043/1938403829'    // Android
      : 'ca-app-pub-6408666343364043/2202778077';   // iOS

  // ───────── Test Device IDs (obligatorio para ver anuncios en TestFlight) ─────────
  // Sin esto, AdMob bloquea silenciosamente todos los anuncios en dispositivos
  // no registrados, cumpliendo su política anti-fraude. Resultado: pantalla vacía.
  //
  // ► Cómo obtener tu Device ID real:
  //   1. Conecta tu iPhone a Codemagic/Xcode y corre la app en modo debug.
  //   2. Busca en los logs esta línea (aparece al primer request de AdMob):
  //      [GoogleMobileAds] To get test ads on this device, set:
  //      GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers
  //      = @[ @"TU_DEVICE_ID_AQUI" ];
  //   3. Copia ese ID de 32 chars y pégalo abajo.
  static const List<String> _testDeviceIds = [
    // iOS Simulator (funciona siempre, no necesita ID real)
    'GADSimulatorID',
    // ── Pegar aquí los Device IDs reales de cada tester ──
    // Cómo obtenerlo: corre la app en debug, busca en logs:
    //   "To get test ads on this device, set: ... testDeviceIdentifiers = @[ @\"<ID>\" ]"
    // Ejemplo: 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4',
  ];

  // ───────── Estado interno ─────────
  bool _sdkReady = false;
  bool _isPremium = false; // SUPREME RULE (RevenueCat)

  InterstitialAd? _interstitialAd;
  int _interstitialLoadAttempts = 0;

  RewardedAd? _rewardedAd;
  int _rewardedLoadAttempts = 0;

  RewardedAd? _rewardedAdIa;
  int _rewardedIaLoadAttempts = 0;

  static const int _maxLoadAttempts = 3;

  // ───────── Inicialización y Control Premium ─────────

  /// Actualiza el estado Premium en el servicio.
  /// Si es Premium, cancela cargas y libera memoria inmediatamente.
  /// Si no es Premium, inicializa o precarga los anuncios.
  void updatePremiumStatus(bool premium) {
    _isPremium = premium;
    if (_isPremium) {
      debugPrint('[AdService] Estado Premium detectado. Cancelando flujos de AdMob y liberando memoria...');
      dispose();
    } else {
      debugPrint('[AdService] Estado No-Premium detectado.');
      if (!_sdkReady) {
        initialize();
      } else {
        _preloadAllAds();
      }
    }
  }

  /// Inicializa el SDK de MobileAds y precarga ambos formatos de anuncio.
  /// Debe llamarse una sola vez al conocerse el estado Premium del usuario.
  void initialize() {
    if (kIsWeb) return;
    if (_isPremium) {
      debugPrint('[AdService] initialize abortado: El usuario es Premium.');
      return;
    }
    if (_sdkReady) return;

    // Registrar dispositivos de prueba ANTES de inicializar el SDK.
    // Sin esto, AdMob bloquea silenciosamente los anuncios en TestFlight.
    if (_testDeviceIds.isNotEmpty) {
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: _testDeviceIds),
      );
      debugPrint('[AdService] Test Device IDs registrados: $_testDeviceIds');
    }

    MobileAds.instance.initialize().then((_) {
      _sdkReady = true;
      debugPrint('[AdService] MobileAds SDK listo. Precargando anuncios...');
      if (!_isPremium) {
        _preloadAllAds();
      }
    });

  }

  void _preloadAllAds() {
    if (kIsWeb || !_sdkReady || _isPremium) return;
    _loadInterstitialAd();
    _loadRewardedAd();
    _loadRewardedAdIa();
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERSTITIAL ADS
  // ═══════════════════════════════════════════════════════════════

  /// Precarga un anuncio intersticial.
  void _loadInterstitialAd() {
    if (kIsWeb || !_sdkReady || _isPremium) return;

    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          if (_isPremium) {
            ad.dispose();
            return;
          }
          debugPrint('[AdService] Intersticial cargado correctamente.');
          _interstitialAd = ad;
          _interstitialLoadAttempts = 0;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Error cargando intersticial: $error');
          _interstitialLoadAttempts++;
          _interstitialAd = null;
          if (_interstitialLoadAttempts < _maxLoadAttempts && !_isPremium) {
            // Backoff progresivo: no quemar los reintentos en red intermitente
            Future.delayed(Duration(seconds: 5 * _interstitialLoadAttempts), () {
              if (!_isPremium) _loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  /// Muestra un intersticial si está disponible y el usuario NO es Premium.
  /// Se usa al salir de un PDF y al presionar "Calcular".
  ///
  /// [onDismissed] callback opcional que se ejecuta cuando el usuario cierra el ad.
  void showInterstitial(BuildContext context, {VoidCallback? onDismissed}) {
    if (kIsWeb || !_sdkReady || _isPremium) {
      onDismissed?.call();
      return;
    }

    // Usuarios Premium no ven anuncios
    final isPremium = context.read<PremiumProvider>().isPremium;
    if (isPremium) {
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('[AdService] Intersticial no estaba listo. Recargando...');
      _loadInterstitialAd();
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Intersticial mostrado.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Intersticial cerrado por el usuario.');
        ad.dispose();
        _interstitialAd = null;
        if (!_isPremium) {
          _loadInterstitialAd(); // Precargar el siguiente
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Error mostrando intersticial: $error');
        ad.dispose();
        _interstitialAd = null;
        if (!_isPremium) {
          _loadInterstitialAd();
        }
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null; // Previene doble-show
  }

  // ═══════════════════════════════════════════════════════════════
  //  REWARDED ADS
  // ═══════════════════════════════════════════════════════════════

  /// Precarga un anuncio bonificado (rewarded).
  void _loadRewardedAd() {
    if (kIsWeb || !_sdkReady || _isPremium) return;

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (_isPremium) {
            ad.dispose();
            return;
          }
          debugPrint('[AdService] Rewarded cargado correctamente.');
          _rewardedAd = ad;
          _rewardedLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Error cargando rewarded: $error');
          _rewardedLoadAttempts++;
          _rewardedAd = null;
          if (_rewardedLoadAttempts < _maxLoadAttempts && !_isPremium) {
            // Backoff progresivo: no quemar los reintentos en red intermitente
            Future.delayed(Duration(seconds: 5 * _rewardedLoadAttempts), () {
              if (!_isPremium) _loadRewardedAd();
            });
          }
        },
      ),
    );
  }

  /// Precarga un anuncio bonificado para IA.
  void _loadRewardedAdIa() {
    if (kIsWeb || !_sdkReady || _isPremium) return;

    RewardedAd.load(
      adUnitId: _rewardedAdIaUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (_isPremium) {
            ad.dispose();
            return;
          }
          debugPrint('[AdService] Rewarded IA cargado correctamente.');
          _rewardedAdIa = ad;
          _rewardedIaLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('[AdService] Error cargando rewarded IA: $error');
          _rewardedIaLoadAttempts++;
          _rewardedAdIa = null;
          if (_rewardedIaLoadAttempts < _maxLoadAttempts && !_isPremium) {
            // Backoff progresivo: no quemar los reintentos en red intermitente
            Future.delayed(Duration(seconds: 5 * _rewardedIaLoadAttempts), () {
              if (!_isPremium) _loadRewardedAdIa();
            });
          }
        },
      ),
    );
  }

  /// Retorna `true` si hay un anuncio rewarded precargado y listo.
  bool get isRewardedReady => _rewardedAd != null && !_isPremium;
  bool get isRewardedIaReady => _rewardedAdIa != null && !_isPremium;

  /// Muestra un anuncio bonificado (rewarded).
  ///
  /// [onRewardEarned] se ejecuta SOLO si el usuario completa el anuncio.
  /// [onAdClosed] se ejecuta siempre que el ad se cierra (haya o no recompensa).
  /// [onAdNotReady] se ejecuta si el anuncio no estaba precargado.
  void showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotReady,
  }) {
    if (kIsWeb || !_sdkReady || _isPremium) {
      onAdNotReady?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('[AdService] Rewarded no listo. Recargando...');
      _loadRewardedAd();
      onAdNotReady?.call();
      return;
    }

    bool rewardGranted = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded mostrado.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded cerrado. Recompensa otorgada: $rewardGranted');
        ad.dispose();
        _rewardedAd = null;
        if (!_isPremium) {
          _loadRewardedAd(); // Precargar el siguiente
        }
        if (rewardGranted) {
          onRewardEarned();
        }
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Error mostrando rewarded: $error');
        ad.dispose();
        _rewardedAd = null;
        if (!_isPremium) {
          _loadRewardedAd();
        }
        onAdNotReady?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('[AdService] ¡Recompensa ganada! ${reward.amount} ${reward.type}');
        rewardGranted = true;
      },
    );
    _rewardedAd = null; // Previene doble-show
  }

  /// Muestra un anuncio bonificado para IA.
  void showRewardedAdIa({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdClosed,
    VoidCallback? onAdNotReady,
  }) {
    if (kIsWeb || !_sdkReady || _isPremium) {
      onAdNotReady?.call();
      return;
    }

    if (_rewardedAdIa == null) {
      debugPrint('[AdService] Rewarded IA no listo. Recargando...');
      _loadRewardedAdIa();
      onAdNotReady?.call();
      return;
    }

    bool rewardGranted = false;

    _rewardedAdIa!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded IA mostrado.');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Rewarded IA cerrado. Recompensa otorgada: $rewardGranted');
        ad.dispose();
        _rewardedAdIa = null;
        if (!_isPremium) {
          _loadRewardedAdIa(); // Precargar el siguiente
        }
        if (rewardGranted) {
          onRewardEarned();
        }
        onAdClosed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Error mostrando rewarded IA: $error');
        ad.dispose();
        _rewardedAdIa = null;
        if (!_isPremium) {
          _loadRewardedAdIa();
        }
        onAdNotReady?.call();
      },
    );

    _rewardedAdIa!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('[AdService] ¡Recompensa ganada (IA)! ${reward.amount} ${reward.type}');
        rewardGranted = true;
      },
    );
    _rewardedAdIa = null; // Previene doble-show
  }

  // ═══════════════════════════════════════════════════════════════
  //  CLEANUP
  // ═══════════════════════════════════════════════════════════════

  /// Libera todos los recursos. Llamar al cerrar la app si es necesario.
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _rewardedAdIa?.dispose();
    _rewardedAdIa = null;
  }
}
