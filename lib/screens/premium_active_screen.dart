import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/theme.dart';

/// Pantalla de Gestión Premium — se muestra cuando el usuario YA ES premium.
/// Mantiene la misma estructura visual elegante del PaywallScreen pero con
/// acentos en verde esmeralda y contenido de confirmación de beneficios activos.
class PremiumActiveScreen extends StatelessWidget {
  const PremiumActiveScreen({super.key});

  // ━━ Paleta verde esmeralda ━━
  static const Color _emerald      = Color(0xFF10B981);
  static const Color _emeraldLight = Color(0xFF34D399);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = DesignTokens.getBackground(brightness);
    final surfaceColor = DesignTokens.getCardBackground(brightness);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // CABECERA — Gradiente oscuro con ícono de escudo/premium verde
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          SliverAppBar(
            expandedHeight: 220,
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
                      Color(0xFF0F172A), // navy profundo
                      Color(0xFF1E293B), // slate oscuro
                      Color(0xFF064E3B), // verde bosque
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Ícono con halo animado
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _emerald.withAlpha(35),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _emerald.withAlpha(60),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _emerald.withAlpha(40),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: _emeraldLight,
                          size: 60,
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Badge "ACTIVO"
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _emerald.withAlpha(50),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _emeraldLight.withAlpha(80),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              color: _emeraldLight,
                              size: 8,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "ACTIVO",
                              style: TextStyle(
                                color: _emeraldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          // CONTENIDO — Título, subtítulo, beneficios, botón, pie de pág
          // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Título ──
                  Text(
                    "Pliegos RIC Premium\nActivo",
                    style: TextStyle(
                      color: DesignTokens.getTextPrimary(brightness),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtítulo ──
                  Text(
                    "Tu productividad eléctrica está al máximo nivel.",
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(brightness),
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Línea decorativa verde ──
                  Container(
                    width: 60,
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_emerald, _emeraldLight],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Lista de beneficios ──
                  _buildBenefitItem(
                    context,
                    Icons.block_rounded,
                    "Cero anuncios molestos",
                    "Sin interrupciones publicitarias en terreno.",
                  ),
                  _buildBenefitItem(
                    context,
                    Icons.auto_awesome_rounded,
                    "Acceso ilimitado al Asistente IA",
                    "Consultas normativas infinitas.",
                  ),
                  _buildBenefitItem(
                    context,
                    Icons.cloud_sync_rounded,
                    "Sincronización en la nube",
                    "Tus datos y marcadores siempre a salvo.",
                  ),

                  const SizedBox(height: 40),

                  // ── Botón principal "Volver al trabajo" ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _emerald,
                        foregroundColor: const Color(0xFF022C22),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        shadowColor: _emerald.withAlpha(100),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Volver al trabajo",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Texto legal / pie de página ──
                  Center(
                    child: Text(
                      "Suscripción anual con renovación automática.\nGestiona o cancela desde Ajustes > Apple ID > Suscripciones.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(brightness)
                            .withAlpha(120),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Widget reutilizable para cada ítem de beneficio
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícono con fondo verde translúcido
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _emerald.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _emerald.withAlpha(40),
              ),
            ),
            child: Icon(icon, color: _emeraldLight, size: 24),
          ),
          const SizedBox(width: 16),
          // Textos
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(brightness),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Check verde de confirmación
          const Icon(
            Icons.check_circle_rounded,
            color: _emeraldLight,
            size: 20,
          ),
        ],
      ),
    );
  }
}
