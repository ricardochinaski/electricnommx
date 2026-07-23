import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// Enlaces legales obligatorios para suscripciones autorenovables
// (App Store Review Guideline 3.1.2c). Ambos deben ser funcionales
// dentro de la app; el EULA además debe referenciarse en la
// descripción de la ficha de App Store.
const String kPrivacyPolicyUrl = 'https://ricardochinaski.github.io/#privacidad';
const String kTermsOfUseUrl = 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  bool _isLoadingOfferings = true;
  bool _isRestoring = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOfferings();
  }

  Future<void> _retryOfferings() async {
    setState(() {
      _isLoadingOfferings = true;
      _errorMessage = null;
    });
    await _fetchOfferings();
  }

  Future<void> _fetchOfferings() async {
    try {
      if (!await Purchases.isConfigured) {
        debugPrint('[RevenueCat] SDK no configurado; no se cargan ofertas.');
        if (mounted) {
          setState(() {
            _isLoadingOfferings = false;
            _errorMessage = "Servicio de suscripciones no disponible por ahora.";
          });
        }
        return;
      }
      final offerings = await Purchases.getOfferings();
      debugPrint('[Paywall] Offerings loaded. current=${offerings.current != null}, packages=${offerings.current?.availablePackages.length ?? 0}');
      if (offerings.current != null) {
        for (final pkg in offerings.current!.availablePackages) {
          debugPrint('[Paywall]   Package: ${pkg.identifier} / ${pkg.storeProduct.priceString}');
        }
      }
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _isLoadingOfferings = false;
          if (offerings.current == null || offerings.current!.availablePackages.isEmpty) {
            _errorMessage = "No se encontraron productos activos en RevenueCat.";
          }
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOfferings = false;
          _errorMessage = e.message ?? 'Error de la tienda (código ${e.code}).';
        });
      }
      debugPrint('[RevenueCat] Error cargando ofertas: ${e.code} - ${e.message} - ${e.details}');
    } catch (e) {
      final errorStr = e.toString();
      String friendlyMsg = "Sin conexión a internet. Verifica tu red e intenta de nuevo.";
      if (errorStr.contains('singleton') || errorStr.contains('configure') || errorStr.contains('Purchases')) {
        friendlyMsg = "Error de configuración interna (RevenueCat no inicializado).";
      }
      if (mounted) {
        setState(() {
          _isLoadingOfferings = false;
          _errorMessage = friendlyMsg;
        });
      }
      debugPrint('[RevenueCat] Error inesperado cargando ofertas: $e');
    }
  }

  /// Abre un enlace legal (privacidad / EULA) en el navegador externo.
  Future<void> _abrirEnlaceLegal(String url) async {
    try {
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('launchUrl retornó false');
    } catch (e) {
      debugPrint('[Paywall] Error abriendo enlace legal $url: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el enlace: $url'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Restaura compras anteriores via RevenueCat.
  /// Obligatorio por política de App Store y Google Play.
  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    try {
      if (!await Purchases.isConfigured) {
        debugPrint('[RevenueCat] SDK no configurado; no se restauran compras.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Servicio de suscripciones no disponible por ahora.'),
              backgroundColor: Colors.orangeAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final customerInfo = await Purchases.restorePurchases();
      final isPro = customerInfo.entitlements.all['premium']?.isActive ?? false;
      if (!mounted) return;
      if (isPro) {
        // Actualizar el estado global Premium
        await context.read<PremiumProvider>().init();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text('✔ Compra restaurada. ¡Bienvenido a Premium!'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se encontraron compras anteriores para restaurar.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al restaurar: ${e.message}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin conexión. Verifica tu red e intenta de nuevo.'),
            backgroundColor: Colors.orangeAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = DesignTokens.getBackground(brightness);
    final surfaceColor = DesignTokens.getCardBackground(brightness);

    // Obtener el paquete anual
    final Package? packageToBuy = _offerings?.current?.annual;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // Cabecera con imagen/gradiente y botón cerrar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: surfaceColor,
            leading: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E293B),
                      Color(0xFF0F172A),
                      DesignTokens.accent,
                    ],
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignTokens.accent.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: DesignTokens.accent,
                          size: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido de beneficios
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Suscripción Anual\nPliegos RIC Premium",
                    style: TextStyle(
                      color: DesignTokens.getTextPrimary(brightness),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Lleva tu productividad eléctrica al siguiente nivel sin interrupciones.",
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(brightness),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildBenefitItem(
                    context,
                    Icons.block_rounded,
                    "Sin anuncios publicitarios",
                    "(Bloqueo de banners e intersticiales).",
                  ),
                  _buildBenefitItem(
                    context,
                    Icons.auto_awesome_rounded,
                    "Asistente IA Eléctrico",
                    "Consultas ilimitadas con nuestro experto normativo.",
                  ),
                  _buildBenefitItem(
                    context,
                    Icons.bookmark_rounded,
                    "Marcadores ilimitados",
                    "Espacios ilimitados para guardar tus Marcadores / Favoritos.",
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Botón de Acción con RevenueCat
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      onPressed: (_isLoadingOfferings) ? null : () async {
                        if (_errorMessage != null) {
                          await _retryOfferings();
                          return;
                        }
                        if (packageToBuy == null) return;
                        
                        setState(() => _isLoadingOfferings = true);
                        
                        final String? errorMsg = await context.read<PremiumProvider>().purchasePremium(packageToBuy);
                        
                        if (mounted) {
                          setState(() => _isLoadingOfferings = false);
                        }
                        
                        if (!context.mounted) return;
                        
                        if (errorMsg == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("✨ ¡Bienvenido a Premium! Disfruta la experiencia."),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                          Navigator.pop(context);
                        } else if (errorMsg != "cancelado") {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $errorMsg"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: _buildButtonContent(packageToBuy),
                    ),
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withAlpha(15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.cloud_off_rounded, color: Colors.redAccent.withAlpha(180), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            "No se pudieron cargar los planes",
                            style: TextStyle(
                              color: DesignTokens.getTextPrimary(brightness),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(brightness),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      "Facturado anualmente. Cancela cuando quieras desde App Store.",
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness).withAlpha(120),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Botón obligatorio por política de ambas stores ──
                  Center(
                    child: TextButton(
                      onPressed: _isRestoring ? null : _restorePurchases,
                      child: _isRestoring
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: DesignTokens.accent,
                              ),
                            )
                          : Text(
                              'Restaurar compras anteriores',
                              style: TextStyle(
                                color: DesignTokens.getTextSecondary(brightness).withAlpha(180),
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Enlaces legales obligatorios (Guideline 3.1.2c) ──
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        TextButton(
                          onPressed: () => _abrirEnlaceLegal(kPrivacyPolicyUrl),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Política de Privacidad',
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(brightness).withAlpha(180),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Text(
                          '•',
                          style: TextStyle(
                            color: DesignTokens.getTextSecondary(brightness).withAlpha(120),
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _abrirEnlaceLegal(kTermsOfUseUrl),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Términos de Uso (EULA)',
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(brightness).withAlpha(180),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonContent(Package? package) {
    if (_isLoadingOfferings) {
      return const SizedBox(
        height: 24, width: 24,
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
      );
    }
    if (_errorMessage != null) {
      return const Text(
        "Reintentar",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }
    final priceText = package != null
        ? "Suscribirse por ${package.storeProduct.priceString} / año"
        : "Cargando planes...";
    return Text(
      priceText,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String title, String subtitle) {
    final brightness = Theme.of(context).brightness;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignTokens.accent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: DesignTokens.getTextPrimary(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(brightness),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
