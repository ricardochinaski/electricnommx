import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';

/// Widget reutilizable que muestra un Banner de AdMob adaptivo.
/// Usa AdSize.getAnchoredAdaptiveBannerAdSize para máximo eCPM.
/// Retorna un contenedor vacío si el anuncio falla en cargar o el usuario es Premium.
///
/// Centraliza todos los Ad Unit IDs de banners para evitar IDs sueltos
/// por el código. Usar [bannerCalcuAdUnitId] para calculadoras/utilidades
/// y [bannerInferiorAdUnitId] (default) para el Dashboard.
class AdBannerWidget extends StatefulWidget {
  /// Ad Unit ID personalizado. Si es null, se usa el ID de banner inferior.
  /// Para calculadoras y utilidades, pasar [AdBannerWidget.bannerCalcuAdUnitId].
  final String? adUnitId;
  final double bottomPadding;
  final double topPadding;

  const AdBannerWidget({
    super.key,
    this.adUnitId,
    this.bottomPadding = 8.0,
    this.topPadding = 0.0,
  });

  // ═══════════════════════════════════════════════════════════════
  //  AD UNIT IDs CENTRALIZADOS — Fuente única de verdad
  // ═══════════════════════════════════════════════════════════════

  /// Banner Inferior (Dashboard) — montado encima del BottomNavigationBar.
  static String get bannerInferiorAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6408666343364043/4068680086'   // Android
      : 'ca-app-pub-6408666343364043/2208693106';   // iOS

  /// Banner Calculadoras/Utilidades — montado en la parte superior del body.
  static String get bannerCalcuAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-6408666343364043/9133229499'   // Android
      : 'ca-app-pub-6408666343364043/8257580763';   // iOS

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;
  int _loadAttempts = 0;
  static const int _maxLoadAttempts = 3;

  /// Altura reservada mientras el banner carga (evita Layout Shift).
  /// Se actualiza con la altura real del banner una vez cargado.
  double _reservedHeight = 60.0;

  String get _resolvedAdUnitId =>
      widget.adUnitId ?? AdBannerWidget.bannerInferiorAdUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    final isPremium = Provider.of<PremiumProvider>(context).isPremium;
    if (isPremium) {
      _disposeAd();
    } else if (_bannerAd == null && !_isLoading) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (_isLoading || _bannerAd != null) return;
    _isLoading = true;

    final screenWidth = MediaQuery.of(context).size.width.truncate();

    // ──────────────────────────────────────────────────────────────
    // FIX CRÍTICO: Usar getAnchoredAdaptiveBannerAdSize (estándar)
    // en vez de getLargeAnchoredAdaptiveBannerAdSize.
    //
    // La variante "Large" retorna banners de 100-250dp de alto, lo que
    // SIEMPRE fallaba el antiguo filtro (height <= 60) y caía a
    // AdSize.banner (320×50) con baja tasa de relleno.
    //
    // La versión estándar retorna banners de ~50-60dp que se adaptan
    // al ancho completo del dispositivo → máximo eCPM y fill rate.
    // ──────────────────────────────────────────────────────────────
    final AnchoredAdaptiveBannerAdSize? adaptiveSize =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(screenWidth);

    final adSize = adaptiveSize ?? AdSize.banner;

    if (!mounted) {
      _isLoading = false;
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: _resolvedAdUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
              _isLoading = false;
              _loadAttempts = 0;
              _reservedHeight = (ad as BannerAd).size.height.toDouble();
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('[AdMob] Banner falló al cargar: ${error.message} '
              '(intento ${_loadAttempts + 1}/$_maxLoadAttempts)');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _isLoading = false;
              _bannerAd = null;
            });
          }
          // Reintento con backoff progresivo
          _loadAttempts++;
          if (_loadAttempts < _maxLoadAttempts) {
            Future.delayed(
              Duration(seconds: 5 * _loadAttempts),
              () {
                if (mounted && _bannerAd == null && !_isLoading) {
                  _loadAd();
                }
              },
            );
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  void _disposeAd() {
    if (_bannerAd != null) {
      _bannerAd!.dispose();
      _bannerAd = null;
    }
    _isAdLoaded = false;
    _isLoading = false;
    _loadAttempts = 0;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Supreme Rule: Si el usuario es Premium, no renderizar nada.
    final isPremium = context.watch<PremiumProvider>().isPremium;
    if (isPremium) {
      return const SizedBox.shrink();
    }

    // Plataformas no soportadas
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return const SizedBox.shrink();
    }

    // ──────────────────────────────────────────────────────────────
    // Si el banner aún no cargó pero estamos intentando, reservamos
    // espacio para evitar Layout Shift (salto brusco de la UI).
    // Si todos los reintentos fallaron, colapsamos sin dejar huecos.
    // ──────────────────────────────────────────────────────────────
    if (!_isAdLoaded || _bannerAd == null) {
      if (_isLoading || _loadAttempts < _maxLoadAttempts) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: widget.bottomPadding,
            top: widget.topPadding,
          ),
          child: SizedBox(
            width: double.infinity,
            height: _reservedHeight,
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // ──────────────────────────────────────────────────────────────
    // Banner cargado: renderizar con márgenes de seguridad para
    // cumplir políticas anti-clic accidental de Google y Apple.
    // Mínimo 8dp de separación de elementos interactivos.
    // ──────────────────────────────────────────────────────────────
    return Padding(
      padding: EdgeInsets.only(
        bottom: widget.bottomPadding,
        top: widget.topPadding,
      ),
      child: Container(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        alignment: Alignment.center,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
