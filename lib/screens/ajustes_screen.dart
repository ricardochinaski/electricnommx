import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/screens/profile_sub_page.dart';
import 'package:nom_electrica_mx/screens/paywall_screen.dart';
import 'package:nom_electrica_mx/screens/premium_active_screen.dart';
import 'dart:io' show Platform;

class AjustesScreen extends StatefulWidget {
  const AjustesScreen({super.key});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    }
  }

  Widget _buildProfileButton(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Invitado';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSubPage())),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.getCardBackground(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DesignTokens.accent.withAlpha(60)),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_rounded, color: Color(0xFF1E3A5F), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: TextStyle(
                        color: DesignTokens.getTextPrimary(brightness),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Configurar perfil y privacidad",
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: DesignTokens.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumToggle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFF10B981).withAlpha(30), const Color(0xFF059669).withAlpha(20)]
              : [DesignTokens.accent.withAlpha(30), DesignTokens.accent.withAlpha(10)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? const Color(0xFF10B981).withAlpha(80)
              : DesignTokens.accent.withAlpha(80),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.star_rounded,
            color: isPremium ? const Color(0xFF10B981) : DesignTokens.accent,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? "Miembro Premium" : "Plan Gratuito",
                  style: TextStyle(
                    color: DesignTokens.getTextPrimary(brightness),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isPremium ? "Todos los beneficios activos" : "Publicidad activada",
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(brightness),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (isPremium) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PremiumActiveScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PaywallScreen()),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: isPremium ? const Color(0xFF10B981) : DesignTokens.accent,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
            child: Text(isPremium ? "GESTIONAR" : "VER PLANES"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: DesignTokens.getBackground(brightness),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildProfileButton(context),
              const SizedBox(height: 12),
              _buildThemeSwitch(context),
              const SizedBox(height: 24),
              _buildPremiumToggle(context),
              Divider(color: DesignTokens.getBorderColor(brightness)),
              const SizedBox(height: 24),
              _buildAjusteItem(
                context,
                Icons.account_balance_rounded,
                "Superintendencia (SEC)",
                "Ir al sitio web oficial de la SEC",
                const Color(0xFF0284C7),
                onTap: () async {
                  try {
                    final Uri url = Uri.parse('https://www.sec.cl');
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No se pudo abrir el enlace."), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildAjusteItem(
                context,
                Icons.gavel_rounded,
                "Aviso de Responsabilidad",
                "Toca para leer el aviso legal",
                const Color(0xFFF59E0B),
                onTap: () => _mostrarAvisoLegal(context),
              ),
              const SizedBox(height: 12),
              _buildAjusteItem(
                context,
                Icons.star_rate_rounded,
                "Calificar App",
                Platform.isAndroid
                    ? "Valora nuestro trabajo en Play Store"
                    : "Valora nuestro trabajo en App Store",
                const Color(0xFF10B981),
                onTap: () async {
                  try {
                    final Uri url = Uri.parse(
                      Platform.isAndroid
                          ? 'https://play.google.com/store/apps/details?id=com.aselec.pliegosric'
                          : 'https://apps.apple.com/cl/app/pliegos-ric-chile/id6779251175',
                    );
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("No se pudo abrir la tienda."),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  }
                },
              ),

              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Versión: ${_appVersion.isNotEmpty ? _appVersion : '...'}",
                      style: DesignTokens.getCaption(brightness).copyWith(
                        color: DesignTokens.getTextPrimary(brightness).withAlpha(200),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Tu feedback nos ayuda a mejorar. Reporta cualquier inconveniente mediante el botón de soporte.",
                      textAlign: TextAlign.center,
                      style: DesignTokens.getCaption(brightness, fontSize: 10)
                          .copyWith(
                            color: DesignTokens.getTextSecondary(brightness).withAlpha(100),
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSwitch(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentMode = themeNotifier.value;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: DesignTokens.getCardBackground(brightness),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DesignTokens.getBorderColor(brightness)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DesignTokens.accent.withAlpha(40),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    currentMode == ThemeMode.dark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: DesignTokens.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Modo",
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentMode == ThemeMode.dark ? "Oscuro" : "Claro",
                      style: TextStyle(
                        color: DesignTokens.getTextPrimary(brightness),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, mode, child) {
                return Switch(
                  value: mode == ThemeMode.dark,
                  onChanged: (value) {
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                  },
                  activeThumbColor: DesignTokens.accent,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAvisoLegal(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = DesignTokens.getSurface(brightness);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            Text(
              "Aviso de Responsabilidad",
              style: GoogleFonts.outfit(
                color: DesignTokens.getTextPrimary(brightness),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          "NOM ELÉCTRICA MX es una herramienta de apoyo y consulta técnica. Los cálculos y resultados deben ser verificados y ejecutados exclusivamente por personal calificado y certificado por la SEC. El uso de esta aplicación no reemplaza el cumplimiento estricto de la normativa vigente.",
          style: TextStyle(
            color: DesignTokens.getTextSecondary(brightness),
            height: 1.5,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ENTENDIDO",
              style: TextStyle(
                color: DesignTokens.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAjusteItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    final brightness = Theme.of(context).brightness;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DesignTokens.getCardBackground(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DesignTokens.getBorderColor(brightness)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        color: DesignTokens.getTextPrimary(brightness),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: DesignTokens.accent.withAlpha(100)),
            ],
          ),
        ),
      ),
    );
  }
}
