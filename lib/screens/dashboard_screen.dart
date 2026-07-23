import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/screens/inicio_screen.dart';
import 'package:nom_electrica_mx/screens/normas_screen.dart';
import 'package:nom_electrica_mx/screens/herramientas_screen.dart';
import 'package:nom_electrica_mx/screens/ajustes_screen.dart';
import 'package:nom_electrica_mx/screens/chat_ric_screen.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadGlobalBookmarks();
  }

  List<Widget> get _screens => [
    InicioScreen(
      onTabChange: (index) => setState(() => _selectedIndex = index),
    ),
    const NormasScreen(),
    const HerramientasScreen(),
    const AjustesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = DesignTokens.getBackground(brightness);
    final surfaceColor = DesignTokens.getSurface(brightness);
    final borderColor = DesignTokens.getBorderColor(brightness);
    final textSecondary = DesignTokens.getTextSecondary(brightness);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        title: InkWell(
          onTap: () => setState(() => _selectedIndex = 0),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.electric_bolt_rounded,
                  color: DesignTokens.accent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  "NOM ELÉCTRICA MX",
                  style: DesignTokens.getDisplay(
                    brightness,
                    fontSize: 18,
                  ).copyWith(letterSpacing: 1.2),
                ),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(color: DesignTokens.accent.withAlpha(80)),
          ),
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Banner Inferior AdMob ───
            // topPadding: 8dp separa del contenido superior (anti-clic accidental)
            // bottomPadding: 12dp separa del BottomNavigationBar
            if (!context.watch<PremiumProvider>().isPremium) ...[
              const Divider(height: 1, thickness: 0.5),
              const AdBannerWidget(topPadding: 8.0, bottomPadding: 8.0),
            ],
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: (i) => setState(() => _selectedIndex = i),
                backgroundColor: bgColor,
                selectedItemColor: DesignTokens.accent,
                unselectedItemColor: textSecondary.withAlpha(150),
                type: BottomNavigationBarType.fixed,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded),
                    label: "INICIO",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.menu_book_rounded),
                    label: "PLIEGOS",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.build),
                    label: "HERRAMIENTAS",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings_rounded),
                    label: "AJUSTES",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatRicScreen()),
          );
        },
        backgroundColor: DesignTokens.accent,
        foregroundColor: Colors.black,
        elevation: 4,
        icon: const Icon(Icons.auto_awesome),
        label: const Text(
          "Asistente IA",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

