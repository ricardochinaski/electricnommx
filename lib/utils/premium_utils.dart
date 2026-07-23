import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/screens/paywall_screen.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';

import 'dart:async';

/// Verifica si el usuario es Premium. Si sí, ejecuta [action] directamente.
/// Si no, muestra un dialog con dos opciones:
///   1. Ver un RewardedAd para desbloquear la función una vez.
///   2. Ir al Paywall para hacerse Premium.
///
/// Se usa en los botones "Exportar PDF" de las calculadoras.
Future<void> checkPremiumAndExecute(BuildContext context, String featureName, FutureOr<void> Function() action) async {
  final isPremium = context.read<PremiumProvider>().isPremium;
  if (isPremium) {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al ejecutar $featureName: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
    return;
  }

  // Usuario gratuito: mostrar dialog con opciones
  if (!context.mounted) return;

  showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withAlpha(180),
    builder: (ctx) {
      bool isLoading = false;

      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final brightness = Theme.of(ctx).brightness;

          return Dialog(
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
                    color: DesignTokens.accent.withAlpha(25),
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
                  // Icono
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
                      Icons.picture_as_pdf_rounded,
                      color: DesignTokens.accent,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Título
                  Text(
                    'Exportar a PDF',
                    style: DesignTokens.getDisplay(brightness, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Subtítulo
                  Text(
                    'La exportación a PDF requiere ver un breve anuncio o ser usuario Premium.',
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
                      onPressed: isLoading
                          ? null
                          : () {
                              // Si el anuncio aún no está cargado, avisamos y ejecutamos acción de todos modos
                              if (!AdService.instance.isRewardedReady) {
                                Navigator.pop(ctx);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.white, size: 20),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'El anuncio se está preparando. Intenta nuevamente en unos segundos.',
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF0EA5E9),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                                return;
                              }
                              setDialogState(() => isLoading = true);
                              AdService.instance.showRewardedAd(
                                onRewardEarned: () async {
                                  // El usuario vio el anuncio completo: ejecutar la acción
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  try {
                                    await action();
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text("Error al exportar: $e"),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  }
                                },
                                onAdClosed: () {
                                  if (ctx.mounted) {
                                    setDialogState(() => isLoading = false);
                                  }
                                },
                                onAdNotReady: () {
                                  // Política "falla cerrado": sin anuncio completado no hay
                                  // exportación gratuita (consistente con el chequeo
                                  // isRewardedReady del inicio del botón).
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Row(
                                          children: [
                                            Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'El anuncio no está disponible. Verifica tu conexión o hazte Premium.',
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
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.play_circle_fill_rounded, size: 20),
                      label: Text(
                        isLoading
                            ? 'Cargando...'
                            : AdService.instance.isRewardedReady
                                ? 'Desbloquear viendo un anuncio'
                                : 'Preparando anuncio...',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Opción 2: Premium
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, size: 20),
                      label: const Text(
                        'Hacerse Premium (sin anuncios)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.accent,
                        side: BorderSide(color: DesignTokens.accent.withAlpha(120)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancelar
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness).withAlpha(150),
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
