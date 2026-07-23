import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/screens/paywall_screen.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';

/// Dialog elegante que se muestra cuando el usuario gratuito
/// se queda sin preguntas en el Chat IA.
///
/// Ofrece dos opciones:
/// 1. Ver un RewardedAd para desbloquear +3 preguntas.
/// 2. Navegar al paywall para hacerse Premium.
class AdWallDialog extends StatefulWidget {
  /// Callback ejecutado cuando el usuario gana la recompensa viendo el anuncio.
  final VoidCallback onRewardEarned;

  const AdWallDialog({super.key, required this.onRewardEarned});

  @override
  State<AdWallDialog> createState() => _AdWallDialogState();

  /// Método estático de conveniencia para mostrar el dialog.
  static Future<void> show(BuildContext context, {required VoidCallback onRewardEarned}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(180),
      builder: (ctx) => AdWallDialog(onRewardEarned: onRewardEarned),
    );
  }
}

class _AdWallDialogState extends State<AdWallDialog> with SingleTickerProviderStateMixin {
  bool _isLoadingAd = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onWatchAd() {
    setState(() => _isLoadingAd = true);

    AdService.instance.showRewardedAd(
      onRewardEarned: () {
        widget.onRewardEarned();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text('¡+3 preguntas desbloqueadas!', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onAdClosed: () {
        if (mounted) setState(() => _isLoadingAd = false);
      },
      onAdNotReady: () {
        widget.onRewardEarned();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Anuncio no disponible temporalmente. Preguntas desbloqueadas de todos modos.',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
    );
  }

  void _onGoPremium() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
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
              color: DesignTokens.accent.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.accent.withAlpha(30),
                blurRadius: 40,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono con glow
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      DesignTokens.accent.withAlpha(40),
                      DesignTokens.accent.withAlpha(15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.accent.withAlpha(40),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: DesignTokens.accent,
                  size: 44,
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                'Preguntas agotadas',
                style: DesignTokens.getDisplay(brightness, fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Subtítulo
              Text(
                'Has utilizado todas tus consultas gratuitas al Asistente IA. Elige cómo continuar:',
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(brightness),
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Opción 1: Ver anuncio
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingAd ? null : _onWatchAd,
                  icon: _isLoadingAd
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.play_circle_fill_rounded, size: 22),
                  label: Text(
                    _isLoadingAd
                        ? 'Cargando anuncio...'
                        : 'Desbloquear 3 preguntas (ver anuncio)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DesignTokens.accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Opción 2: Premium
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onGoPremium,
                  icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                  label: const Text(
                    'Hacerse Premium (uso ilimitado)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DesignTokens.accent,
                    side: BorderSide(color: DesignTokens.accent.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cerrar
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(brightness).withAlpha(150),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
