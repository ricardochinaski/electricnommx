import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/providers/user_profile_provider.dart';
import 'package:nom_electrica_mx/screens/login_screen.dart';

/// Sub-página de perfil y privacidad.
/// Centraliza: avatar, info cuenta, estado suscripción, cerrar sesión y eliminar cuenta.
class ProfileSubPage extends StatefulWidget {
  const ProfileSubPage({super.key});

  @override
  State<ProfileSubPage> createState() => _ProfileSubPageState();
}

class _ProfileSubPageState extends State<ProfileSubPage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  int _avatarIndex = 0;
  bool _isSaving = false;

  // 10 avatares eléctricos: (icono, color, label)
  static const List<(IconData, Color, String)> _avatarOptions = [
    (Icons.bolt_rounded,                   Color(0xFFF59E0B), 'Flash'),
    (Icons.electrical_services_rounded,    Color(0xFF3B82F6), 'Servicio'),
    (Icons.lightbulb_rounded,              Color(0xFFFBBF24), 'Ampolleta'),
    (Icons.build_rounded,                  Color(0xFFEF4444), 'Técnico'),
    (Icons.shield_rounded,                 Color(0xFF10B981), 'Inspector'),
    (Icons.engineering_rounded,            Color(0xFF06B6D4), 'Ingeniero'),
    (Icons.architecture_rounded,           Color(0xFF8B5CF6), 'Proyectista'),
    (Icons.battery_charging_full_rounded,  Color(0xFF22C55E), 'Energía'),
    (Icons.developer_board_rounded,        Color(0xFF6366F1), 'Circuitos'),
    (Icons.settings_input_composite_rounded, Color(0xFFEC4899), 'Sistemas'),
  ];

  @override
  void initState() {
    super.initState();
    // Sincronizar los controladores locales con los valores del Provider.
    // El Provider ya cargó desde SharedPreferences en main() antes de que
    // este widget se construyera, por lo que los datos están disponibles
    // de forma inmediata sin ningún Future.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = context.read<UserProfileProvider>();
      _nombreController.text = profile.nombre;
      _cargoController.text  = profile.cargo;
      setState(() => _avatarIndex = profile.avatarIndex);
    });
  }

  @override
  void dispose() {
    // Los controladores son UI state local: se liberan aquí correctamente.
    // No hay Futures pendientes ni listeners externos que provoquen memory leaks.
    _nombreController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    // Delegar toda la lógica de persistencia al Provider.
    // El Provider maneja: validación, SP, Firestore, notifyListeners.
    // La pantalla solo reacciona al resultado para mostrar el SnackBar correcto.
    setState(() => _isSaving = true);

    final result = await context.read<UserProfileProvider>().guardar(
      nombre:      _nombreController.text,
      cargo:       _cargoController.text,
      avatarIndex: _avatarIndex,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case ProfileSaveResult.syncedOnline:
        _showSnackBar(
          '¡Perfil actualizado con éxito!',
          Icons.check_circle_rounded,
          const Color(0xFF10B981),
        );

      case ProfileSaveResult.savedLocally:
        _showSnackBar(
          'Guardado en el dispositivo. Inicia sesión para sincronizar con la nube.',
          Icons.offline_pin_rounded,
          Colors.orangeAccent,
        );

      case ProfileSaveResult.emptyFields:
        _showSnackBar(
          'Ingresa al menos tu nombre o cargo antes de guardar',
          Icons.warning_rounded,
          Colors.orangeAccent,
        );

      case ProfileSaveResult.error:
        _showSnackBar(
          'Error al guardar. Intenta de nuevo.',
          Icons.error_rounded,
          Colors.redAccent,
        );
    }
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = DesignTokens.getBackground(brightness);
    final isPremium = context.watch<PremiumProvider>().isPremium;
    final email = FirebaseAuth.instance.currentUser?.email ?? 'Invitado';
    final (avatarIcon, avatarColor, _) = _avatarOptions[_avatarIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: DesignTokens.getTextPrimary(brightness)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Mi Perfil",
          style: GoogleFonts.outfit(
            color: DesignTokens.getTextPrimary(brightness),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // ━━ Avatar + Email ━━
            _buildAvatarCard(brightness, email, avatarIcon, avatarColor),
            const SizedBox(height: 16),

            // ━━ Datos de perfil ━━
            _buildProfileForm(brightness),
            const SizedBox(height: 16),

            // ━━ Estado de suscripción ━━
            _buildSubscriptionCard(brightness, isPremium),
            const SizedBox(height: 24),

            // ━━ Acciones Críticas ━━
            _buildDangerZone(brightness),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Avatar + Email card
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildAvatarCard(Brightness brightness, String email, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.getBorderColor(brightness)),
      ),
      child: Column(
        children: [
          // Avatar grande
          GestureDetector(
            onTap: () => _mostrarSelectorAvatar(context),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: color.withAlpha(40),
                  child: Icon(icon, size: 44, color: color),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DesignTokens.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: DesignTokens.getCardBackground(brightness), width: 2),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            style: TextStyle(
              color: DesignTokens.getTextPrimary(brightness),
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _mostrarSelectorAvatar(context),
            child: Text(
              'Cambiar avatar ›',
              style: TextStyle(color: DesignTokens.accent, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Formulario nombre / cargo
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildProfileForm(Brightness brightness) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.getBorderColor(brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Datos de Perfil",
            style: TextStyle(color: DesignTokens.getTextPrimary(brightness), fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _nombreController,
            style: TextStyle(color: DesignTokens.getTextPrimary(brightness)),
            decoration: _inputDecoration(brightness, 'Nombre Usuario', Icons.badge_rounded),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cargoController,
            style: TextStyle(color: DesignTokens.getTextPrimary(brightness)),
            decoration: _inputDecoration(brightness, 'Especialidad / Cargo', Icons.work_rounded),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.cloud_upload_rounded, size: 20),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _isSaving ? null : _guardarCambios,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(Brightness brightness, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: DesignTokens.getTextSecondary(brightness)),
      prefixIcon: Icon(icon, color: DesignTokens.accent.withAlpha(180)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: DesignTokens.getBorderColor(brightness)),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: DesignTokens.accent),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Estado de suscripción
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildSubscriptionCard(Brightness brightness, bool isPremium) {
    final statusColor = isPremium ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final statusText = isPremium ? "Premium Activo" : "Plan Gratuito";
    final statusDesc = isPremium
        ? "Todos los beneficios desbloqueados"
        : "Publicidad activada · Funciones limitadas";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(brightness),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(80)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.workspace_premium_rounded : Icons.star_rounded,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Estado de Suscripción",
                  style: TextStyle(color: DesignTokens.getTextSecondary(brightness), fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  statusDesc,
                  style: TextStyle(color: DesignTokens.getTextSecondary(brightness), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Zona de peligro
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Widget _buildDangerZone(Brightness brightness) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "ZONA DE CUENTA",
            style: TextStyle(
              color: DesignTokens.getTextSecondary(brightness).withAlpha(150),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        // Cerrar Sesión
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.redAccent),
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text("Cerrar Sesión", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ),
        const SizedBox(height: 12),
        // Eliminar Cuenta (Requisito obligatorio Apple 5.1.1)
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.red.shade800),
              foregroundColor: Colors.red.shade800,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text("Eliminar Cuenta", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            onPressed: () => _showDeleteAccountDialog(context),
          ),
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Selector de avatares (dialog)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _mostrarSelectorAvatar(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(160),
      builder: (ctx) => Theme(
        data: ThemeData.dark(),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A2035),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF3B82F6).withAlpha(80), width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(140), blurRadius: 32, spreadRadius: 4)],
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF3B82F6).withAlpha(40), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF60A5FA), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Elige tu Avatar', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text('Avatares eléctricos – toca para seleccionar', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  const SizedBox(height: 20),
                  StatefulBuilder(
                    builder: (ctx2, setInner) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.95,
                        ),
                        itemCount: _avatarOptions.length,
                        itemBuilder: (context, index) {
                          final (icon, color, label) = _avatarOptions[index];
                          final isSelected = index == _avatarIndex;
                          return GestureDetector(
                            onTap: () {
                              setInner(() {});
                              setState(() => _avatarIndex = index);
                              // Persistir avatar inmediatamente vía Provider (SP sin Firestore)
                              context.read<UserProfileProvider>().setAvatarIndex(index);
                              Navigator.pop(ctx);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: isSelected ? color.withAlpha(50) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: isSelected ? color : Colors.white.withAlpha(15), width: isSelected ? 2 : 1),
                                boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(80), blurRadius: 8)] : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(icon, color: color, size: 36),
                                  const SizedBox(height: 8),
                                  Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF94A3B8)),
                    child: const Text('CANCELAR'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Diálogo eliminar cuenta (2 pasos)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  void _showDeleteAccountDialog(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = DesignTokens.getSurface(brightness);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text("Eliminar Cuenta", style: GoogleFonts.outfit(color: DesignTokens.getTextPrimary(brightness), fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(
          "Esta acción es IRREVERSIBLE. Se eliminarán permanentemente:\n\n"
          "• Tu perfil y datos personales\n"
          "• Todos tus marcadores guardados\n"
          "• Tu historial de configuración\n\n"
          "¿Estás seguro de que deseas continuar?",
          style: TextStyle(color: DesignTokens.getTextSecondary(brightness), height: 1.5, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCELAR", style: TextStyle(color: DesignTokens.getTextSecondary(brightness), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(ctx);
              _confirmarEliminacionFinal(context);
            },
            child: const Text("SÍ, ELIMINAR", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminacionFinal(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final surfaceColor = DesignTokens.getSurface(brightness);
    // Controller local al diálogo — se crea y destruye con el diálogo
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Confirmación Final", style: GoogleFonts.outfit(color: Colors.red.shade700, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text("Escribe ELIMINAR para confirmar la eliminación permanente de tu cuenta.", style: TextStyle(color: DesignTokens.getTextSecondary(brightness), fontSize: 14)),
        actions: [
          Column(
            children: [
              TextField(
                controller: controller,
                style: TextStyle(color: DesignTokens.getTextPrimary(brightness)),
                decoration: InputDecoration(
                  hintText: "Escribe ELIMINAR",
                  hintStyle: TextStyle(color: DesignTokens.getTextSecondary(brightness).withAlpha(100)),
                  filled: true,
                  fillColor: DesignTokens.getBackground(brightness),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    // No llamar controller.dispose() aquí: el TextField sigue vivo
                    // hasta que el diálogo se destruya. Flutter limpia el controller
                    // automáticamente cuando sale del scope del builder.
                    onPressed: () => Navigator.pop(ctx),
                    child: Text("CANCELAR", style: TextStyle(color: DesignTokens.getTextSecondary(brightness), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () async {
                      if (controller.text.trim() != "ELIMINAR") {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Debes escribir ELIMINAR exactamente."),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      // Cerrar el diálogo ANTES de la operación asíncrona.
                      // controller se libera al salir del scope del builder.
                      Navigator.pop(ctx);
                      await _ejecutarEliminacionCuenta(context);
                    },
                    child: const Text("CONFIRMAR", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _ejecutarEliminacionCuenta(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).delete();
      await user.delete();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Tu cuenta ha sido eliminada permanentemente."),
          backgroundColor: Color(0xFF10B981),
        ));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if (context.mounted) {
          await _reautenticarYEliminar(context, user);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Error: ${e.message}"),
            backgroundColor: Colors.redAccent,
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Error inesperado: $e"),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _reautenticarYEliminar(BuildContext context, User user) async {
    final providerInfo = user.providerData.firstOrNull;
    if (providerInfo == null) {
      _showSnackBar('Error al identificar método de autenticación.', Icons.error_rounded, Colors.redAccent);
      return;
    }

    final isGoogle = providerInfo.providerId == 'google.com';
    final isPassword = providerInfo.providerId == 'password';

    if (isGoogle) {
      await _reautenticarConGoogle(context, user);
    } else if (isPassword) {
      if (!context.mounted) return;
      await _reautenticarConPassword(context, user);
    } else {
      _showSnackBar(
        'Inicia sesión nuevamente desde Ajustes > Perfil e intenta de nuevo.',
        Icons.info_rounded,
        Colors.orangeAccent,
      );
    }
  }

  Future<void> _reautenticarConGoogle(BuildContext context, User user) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      if (context.mounted) {
        _showSnackBar('Re-autenticación exitosa. Eliminando cuenta...', Icons.check_circle_rounded, const Color(0xFF10B981));
        await _ejecutarEliminacionCuenta(context);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error en re-autenticación con Google: $e', Icons.error_rounded, Colors.redAccent);
      }
    }
  }

  Future<void> _reautenticarConPassword(BuildContext context, User user) async {
    final email = user.email;
    if (email == null || email.isEmpty) {
      _showSnackBar('No hay email registrado.', Icons.error_rounded, Colors.redAccent);
      return;
    }

    final passwordCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final brightness = Theme.of(context).brightness;
    final surfaceColor = DesignTokens.getSurface(brightness);

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.lock_rounded, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 10),
            Text("Re-autenticación requerida",
                style: GoogleFonts.outfit(
                    color: DesignTokens.getTextPrimary(brightness),
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: passwordCtrl,
            obscureText: true,
            style: TextStyle(color: DesignTokens.getTextPrimary(brightness)),
            decoration: InputDecoration(
              labelText: "Ingresa tu contraseña",
              labelStyle: TextStyle(color: DesignTokens.getTextSecondary(brightness)),
              filled: true,
              fillColor: DesignTokens.getBackground(brightness),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Contraseña requerida' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("CANCELAR",
                style: TextStyle(
                    color: DesignTokens.getTextSecondary(brightness),
                    fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, passwordCtrl.text);
              }
            },
            child: const Text("RE-AUTENTICAR",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    passwordCtrl.dispose();

    if (password == null || password.isEmpty) return;

    try {
      final credential = EmailAuthProvider.credential(email: email, password: password);
      await user.reauthenticateWithCredential(credential);
      if (context.mounted) {
        _showSnackBar('Re-autenticación exitosa. Eliminando cuenta...',
            Icons.check_circle_rounded, const Color(0xFF10B981));
        await _ejecutarEliminacionCuenta(context);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        _showSnackBar(
          e.code == 'wrong-password'
              ? 'Contraseña incorrecta. Intenta de nuevo.'
              : 'Error: ${e.message}',
          Icons.error_rounded,
          Colors.redAccent,
        );
      }
    }
  }
}
