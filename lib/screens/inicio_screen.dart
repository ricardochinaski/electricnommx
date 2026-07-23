import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/models/ric_data.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/providers/user_profile_provider.dart';
import 'package:nom_electrica_mx/widgets/animated_elevation_card.dart';
import 'package:nom_electrica_mx/screens/pdf_viewer_screen.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:nom_electrica_mx/services/user_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class InicioScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const InicioScreen({super.key, this.onTabChange});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredPliegos = [];
  bool _isSearching = false;
  final List<Map<String, String>> _consejosRIC = [
    {
      "texto":
          "Protege con GFCI donde hay agua: Los contactos de baños, cocinas, garajes, exteriores y azoteas de viviendas requieren interruptor de falla a tierra (GFCI).",
      "fuente": "NOM-001-SEDE, Art. 210-8",
    },
    {
      "texto":
          "Verifica tu electrodo de tierra: Si una sola varilla supera 25 ohms de resistencia a tierra, debes complementarla con un electrodo adicional.",
      "fuente": "NOM-001-SEDE, Art. 250-56",
    },
    {
      "texto":
          "Respeta el código de colores: El neutro (conductor puesto a tierra) se identifica en blanco o gris claro; la tierra en verde, verde con amarillo o desnudo.",
      "fuente": "NOM-001-SEDE, Arts. 200-6 y 250-119",
    },
    {
      "texto":
          "Cuida la caída de tensión: Dimensiona los conductores para no exceder 3% en el circuito derivado y 5% en total sumando el alimentador.",
      "fuente": "NOM-001-SEDE, Arts. 210-19 y 215-2 (notas)",
    },
    {
      "texto":
          "Deja espacio de trabajo frente al tablero: Mínimo 90 cm de profundidad libre frente a centros de carga y tableros para maniobrar con seguridad.",
      "fuente": "NOM-001-SEDE, Art. 110-26",
    },
    {
      "texto":
          "No sobrellenes la tubería conduit: Máximo 40% de ocupación con 3 o más conductores (53% para uno solo, 31% para dos).",
      "fuente": "NOM-001-SEDE, Capítulo 10, Tabla 1",
    },
    {
      "texto":
          "Usa pastillas con capacidad interruptiva adecuada: El interruptor termomagnético debe soportar la corriente de cortocircuito disponible en el punto de instalación.",
      "fuente": "NOM-001-SEDE, Art. 110-9",
    },
    {
      "texto":
          "Identifica cada circuito: El centro de carga debe tener un directorio legible que indique claramente qué alimenta cada interruptor.",
      "fuente": "NOM-001-SEDE, Art. 408-4",
    },
    {
      "texto":
          "Nunca interrumpas el conductor de tierra: No se permiten dispositivos de sobrecorriente en serie con el conductor de puesta a tierra de equipos.",
      "fuente": "NOM-001-SEDE, Art. 250",
    },
    {
      "texto":
          "Albercas con máxima precaución: Luminarias sumergidas y contactos cercanos exigen GFCI y unión equipotencial de todas las partes metálicas.",
      "fuente": "NOM-001-SEDE, Art. 680",
    },
  ];

  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = info.version);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPliegos(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPliegos = [];
        _isSearching = false;
      });
      return;
    }

    final results = RicData.pliegos.where((p) {
      final titulo = p['titulo'].toString().toLowerCase();
      final desc = p['desc'].toString().toLowerCase();
      final num = p['num'].toString();
      final keywords = (p['keywords'] as List<String>).join(' ').toLowerCase();
      final input = query.toLowerCase();

      return titulo.contains(input) ||
          desc.contains(input) ||
          num.contains(input) ||
          keywords.contains(input);
    }).toList();

    setState(() {
      _filteredPliegos = results;
      _isSearching = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              sliver: SliverToBoxAdapter(child: _buildSearchBar(context)),
            ),
            if (!_isSearching) ...[
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 10),
                    _buildDynamicHeader(context),
                    const SizedBox(height: 24),
                    _buildSecurityTipsCarousel(context),
                    const SizedBox(height: 32),
                    _buildSummarySection(context),
                    const SizedBox(height: 32),
                    _buildHomeBookmarks(context),
                    const SizedBox(height: 32),
                    _buildInstallerNotes(context),
                    const SizedBox(height: 32),
                    _buildSupportSection(context),
                    const SizedBox(height: 24),
                    _buildBetaMessage(context),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
            if (_isSearching)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: _buildSearchResults(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardBg = DesignTokens.getCardBackground(brightness);
    final borderColor = DesignTokens.getBorderColor(brightness);
    final textColor = DesignTokens.getTextPrimary(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);
    return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
        ),
        child: TextField(
          enabled: true,
          controller: _searchController,
          onChanged: _filterPliegos,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: "Buscar por RIC, palabras clave o contenido...",
            hintStyle: TextStyle(
              color: textSecondary.withAlpha(80),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: DesignTokens.accent,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: textSecondary.withAlpha(150),
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _filterPliegos("");
                    },
                  )
                : null,
          ),
        ),
      );
  }

  Widget _buildSummarySection(BuildContext context) {
    return Column(
      children: [
        _buildSummaryCard(
          context,
          "Pliegos Técnicos RIC",
          Icons.menu_book_rounded,
          DesignTokens.accent,
          () {
            normasIsRicNotifier.value = true;
            widget.onTabChange?.call(1);
          },
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSummaryCard(
              context,
              "Pliegos RPTD",
              Icons.library_books_rounded,
              const Color(0xFF6366F1),
              () {
                normasIsRicNotifier.value = false;
                widget.onTabChange?.call(1);
              },
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              "Utilidades",
              Icons.handyman_rounded,
              const Color(0xFF10B981),
              () {
                herramientasTabNotifier.value = 1;
                widget.onTabChange?.call(2);
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryCard(
              context,
              "Calculadoras",
              Icons.calculate_rounded,
              const Color(0xFFF472B6),
              () {
                herramientasTabNotifier.value = 0;
                widget.onTabChange?.call(2);
              },
            ),
            const SizedBox(width: 12),
            _buildSummaryCard(
              context,
              "Canal YouTube",
              Icons.play_circle_fill_rounded,
              Colors.redAccent,
              () => _launchUrl(
                "https://www.youtube.com/watch?v=g_8RYQQ1USM&list=PLNcrSBNu_jDSYrj3dSr7Bkg-zimTa_FQo",
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildDynamicHeader(BuildContext context) {
    final b = Theme.of(context).brightness;
    final profileName = context.watch<UserProfileProvider>().displayName;
    // Si el perfil tiene nombre, usarlo; si no, fallback al email
    final name = profileName != 'Instalador'
        ? profileName
        : (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? 'Instalador');
    final hour = DateTime.now().hour;
    String greeting = "Buenas noches";
    if (hour < 12) {
      greeting = "Buenos días";
    } else if (hour < 19) {
      greeting = "Buenas tardes";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.accent, DesignTokens.accent.withAlpha(150)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.accent.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "¡$greeting, $name! ⚡",
                style: DesignTokens.getDisplay(
                  b,
                  fontSize: 22,
                ).copyWith(color: Colors.white, height: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Mantén tus instalaciones seguras y bajo norma.",
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeBookmarks(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bookmark_rounded, color: DesignTokens.accent),
            const SizedBox(width: 8),
            Text(
              "Mis Marcadores Recientes",
              style: DesignTokens.getDisplay(b, fontSize: 18),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<List<String>>(
          valueListenable: globalBookmarksNotifier,
          builder: (context, bookmarks, _) {
            if (bookmarks.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: DesignTokens.getCardBackground(b),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DesignTokens.getBorderColor(b)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.bookmark_border_rounded,
                      color: DesignTokens.getTextSecondary(b).withAlpha(80),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No tienes marcadores guardados. Abre un Pliego Técnico para agregar marcadores.",
                      textAlign: TextAlign.center,
                      style: DesignTokens.getCaption(b),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: bookmarks.take(3).map((bm) {
                final parts = bm.split('|');
                if (parts.length < 3) return const SizedBox();
                final nombre = parts[0];
                final page = int.tryParse(parts[1]) ?? 1;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    tileColor: DesignTokens.getCardBackground(b),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: DesignTokens.getBorderColor(b).withAlpha(100),
                      ),
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: DesignTokens.accent.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        color: DesignTokens.accent,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      nombre,
                      style: DesignTokens.getBody(b, fontSize: 14)
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Página $page",
                      style: DesignTokens.getCaption(b),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () => _eliminarMarcadorHome(context, bm),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: DesignTokens.accent,
                        ),
                      ],
                    ),
                    onTap: () => _openBookmark(
                      title: nombre,
                      assetPath: parts[2],
                      initialPage: page,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildInstallerNotes(BuildContext context) {
    final b = Theme.of(context).brightness;
    final cardBg = DesignTokens.getCardBackground(b);
    final borderColor = DesignTokens.getBorderColor(b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit_note_rounded,
                  color: DesignTokens.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  "Bloc del Instalador",
                  style: DesignTokens.getDisplay(b, fontSize: 18),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: DesignTokens.accent,
              ),
              onPressed: () => _showNoteEditor(context),
              tooltip: "Nueva Nota",
            ),
          ],
        ),
        const SizedBox(height: 12),
        ValueListenableBuilder<List<String>>(
          valueListenable: notesNotifier,
          builder: (context, notes, _) {
            if (notes.isEmpty) {
              return GestureDetector(
                onTap: () => _showNoteEditor(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.edit_note_rounded,
                        color: DesignTokens.getTextSecondary(b).withAlpha(80),
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Anote medidas, recordatorios o datos rápidos aquí.",
                        textAlign: TextAlign.center,
                        style: DesignTokens.getCaption(b),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DesignTokens.getSurface(b),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: DesignTokens.accent.withAlpha(120),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showNoteEditor(
                              context,
                              note: note,
                              index: index,
                            ),
                            child: Text(
                              note,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: DesignTokens.getBody(b, fontSize: 13)
                                  .copyWith(
                                    height: 1.3,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () => _deleteNote(context, index),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: Colors.red.withAlpha(200),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  void _showNoteEditor(BuildContext context, {String? note, int? index}) {
    final b = Theme.of(context).brightness;
    final controller = TextEditingController(text: note);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.getCardBackground(b),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: DesignTokens.accent.withAlpha(100)),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: DesignTokens.accent),
            const SizedBox(width: 10),
            Text(
              note == null ? "Nueva Nota" : "Editar Nota",
              style: DesignTokens.getDisplay(b, fontSize: 18),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 8,
          autofocus: true,
          style: DesignTokens.getBody(b),
          decoration: InputDecoration(
            hintText: "Escribe aquí algo rápido...",
            hintStyle: DesignTokens.getCaption(b),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DesignTokens.getBorderColor(b)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: DesignTokens.getBorderColor(b)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: DesignTokens.accent,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: b == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCELAR",
              style: TextStyle(
                color: DesignTokens.getTextSecondary(b),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final currentNotes = List<String>.from(notesNotifier.value);
                if (index != null) {
                  currentNotes[index] = controller.text.trim();
                } else {
                  currentNotes.insert(0, controller.text.trim());
                }
                saveNotes(currentNotes);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.accent,
              foregroundColor: Colors.black,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              note == null ? "GUARDAR" : "ACTUALIZAR",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteNote(BuildContext context, int index) {
    final b = Theme.of(context).brightness;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignTokens.getSurface(b),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withAlpha(50)),
        ),
        title: Text(
          "¿Eliminar nota?",
          style: DesignTokens.getDisplay(b, fontSize: 18),
        ),
        content: Text(
          "Esta acción no se puede deshacer.",
          style: DesignTokens.getCaption(b),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "CANCELAR",
              style: TextStyle(color: DesignTokens.getTextSecondary(b)),
            ),
          ),
          TextButton(
            onPressed: () {
              final currentNotes = List<String>.from(notesNotifier.value);
              currentNotes.removeAt(index);
              saveNotes(currentNotes);
              Navigator.pop(context);
            },
            child: const Text(
              "ELIMINAR",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBetaMessage(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.accent.withAlpha(15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: DesignTokens.accent.withAlpha(30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: DesignTokens.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Versión ${_appVersion.isNotEmpty ? _appVersion : '...'}. Ayúdanos a mejorar reportando cualquier error o sugerencia.",
              style: DesignTokens.getCaption(b),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    return AnimatedElevationCard(
      context: context,
      title: title,
      icon: icon,
      color: color,
      onTap: onTap,
      isFullWidth: isFullWidth,
    );
  }

  Widget _buildSecurityTipsCarousel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.lightbulb_outline_rounded,
              color: DesignTokens.accent,
            ),
            const SizedBox(width: 8),
            Text(
              "Tip de Seguridad RIC",
              style: DesignTokens.getDisplay(
                Theme.of(context).brightness,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SecurityTipCarousel(tips: _consejosRIC),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "¿Necesitas ayuda?",
          style: DesignTokens.getDisplay(b, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildContactButton(
              context: context,
              label: "WhatsApp",
              icon: Icons.chat_bubble_outline_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _launchUrl(
                "https://wa.me/56998273951?text=Estimados%20Aselec%20Developer,%20les%20contacto%20desde%20la%20App%20Pliegos%20RIC%20Chile.%20Me%20gustar%C3%ADa%20realizar%20una%20consulta%20o%20sugerencia%20t%C3%A9cnica%20sobre%20la%20aplicaci%C3%B3n.",
              ),
            ),
            const SizedBox(width: 12),
            _buildContactButton(
              context: context,
              label: "Correo",
              icon: Icons.email_outlined,
              color: const Color(0xFF0EA5E9),
              onTap: () => _launchUrl(
                "mailto:aselec.eirl@gmail.com?subject=Feedback%20App%20Norma%20RIC.",
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final brightness = Theme.of(context).brightness;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withAlpha(50)),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: DesignTokens.getBody(
                  brightness,
                  fontSize: 14,
                ).copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    if (_filteredPliegos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: DesignTokens.getTextSecondary(brightness).withAlpha(100),
              ),
              const SizedBox(height: 16),
              Text(
                "No se encontraron resultados",
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(brightness),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final p = _filteredPliegos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            tileColor: DesignTokens.getCardBackground(brightness),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: DesignTokens.getBorderColor(brightness)),
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (p['color'] as Color).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                p['icon'] as IconData,
                color: p['color'] as Color,
                size: 24,
              ),
            ),
            title: Text(
              "${p['articulo']} - ${p['titulo']}",
              style: TextStyle(
                color: DesignTokens.getTextPrimary(brightness),
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              p['desc'] as String,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: DesignTokens.getTextSecondary(brightness),
              ),
            ),
            onTap: () {
              setState(() {
                _searchController.clear();
                _isSearching = false;
              });
              RicData.navegarARic(context, p['num'] as int);
            },
          ),
        );
      }, childCount: _filteredPliegos.length),
    );
  }

  /// Navega directamente al marcador seleccionado sin ningún bloqueo previo.
  ///
  /// Flujo para usuarios FREE:
  ///   1. Navega inmediatamente al [PDFViewerPage].
  ///   2. Cuando el usuario regresa (pop), muestra un intersticial (post-view).
  ///
  /// Flujo para usuarios PREMIUM:
  ///   1. Navega directamente. Sin anuncios en ningún momento.
  Future<void> _eliminarMarcadorHome(BuildContext context, String entry) async {
    final prefs = await SharedPreferences.getInstance();
    final lista = prefs.getStringList('bookmarks') ?? [];
    final index = lista.indexOf(entry);
    if (index != -1) {
      lista.removeAt(index);
      await prefs.setStringList('bookmarks', lista);
      globalBookmarksNotifier.value = List.from(lista);
      try {
        await UserService().syncBookmarks(lista);
      } catch (e) {
        debugPrint('Error syncing bookmarks: $e');
      }
      if (context.mounted) {
        final b = Theme.of(context).brightness;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Marcador eliminado.'),
            action: SnackBarAction(
              label: 'DESHACER',
              textColor: Colors.amber,
              onPressed: () async {
                final newLista = prefs.getStringList('bookmarks') ?? [];
                if (!newLista.contains(entry)) {
                  newLista.insert(index < newLista.length ? index : newLista.length, entry);
                  await prefs.setStringList('bookmarks', newLista);
                  globalBookmarksNotifier.value = List.from(newLista);
                  try {
                    await UserService().syncBookmarks(newLista);
                  } catch (e) {
                    debugPrint('Error syncing bookmarks: $e');
                  }
                }
              },
            ),
            backgroundColor: DesignTokens.getCardBackground(b),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _openBookmark({
    required String title,
    required String assetPath,
    required int initialPage,
  }) async {
    final isPremium = context.read<PremiumProvider>().isPremium;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PDFViewerPage(
          title: title,
          assetPath: assetPath,
          initialPage: initialPage,
        ),
      ),
    );

    // El usuario ya terminó de ver el documento — mostrar intersticial solo si:
    //   • No es Premium
    //   • El widget sigue montado (no se destruyó la pantalla durante la navegación)
    if (!isPremium && mounted) {
      AdService.instance.showInterstitial(context);
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $uri');
    }
  }
}

class _SecurityTipCarousel extends StatefulWidget {
  final List<Map<String, String>> tips;
  const _SecurityTipCarousel({required this.tips});

  @override
  State<_SecurityTipCarousel> createState() => _SecurityTipCarouselState();
}

class _SecurityTipCarouselState extends State<_SecurityTipCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_currentPage < widget.tips.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return SizedBox(
      height: 140,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (idx) => setState(() => _currentPage = idx),
        itemCount: widget.tips.length,
        itemBuilder: (context, index) {
          final tip = widget.tips[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: DesignTokens.accent.withAlpha(15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DesignTokens.accent.withAlpha(40)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    tip["texto"]!,
                    textAlign: TextAlign.center,
                    style: DesignTokens.getBody(b, fontSize: 14).copyWith(
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip["fuente"]!,
                  style: DesignTokens.getCaption(b).copyWith(
                    color: DesignTokens.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
