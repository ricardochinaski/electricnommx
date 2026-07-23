import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/app_state.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_caida_tension_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/dimensionador_circuito_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_voltaje_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_corriente_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_ductos_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_malla_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_motores_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_alumbrado_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_awg_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_protecciones_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_consumo_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_baterias_screen.dart';
import 'package:nom_electrica_mx/screens/calculadoras/calculadora_capacidad_screen.dart';

import 'package:nom_electrica_mx/screens/utilidades/tabla_corrientes_screen.dart';
import 'package:nom_electrica_mx/screens/utilidades/capacidad_ruptura_screen.dart';
import 'package:nom_electrica_mx/screens/utilidades/codigo_colores_screen.dart';
import 'package:nom_electrica_mx/screens/utilidades/grados_proteccion_screen.dart';
import 'package:nom_electrica_mx/screens/utilidades/memoria_prete1_screen.dart';
import 'package:nom_electrica_mx/screens/utilidades/cubicador_tableros_screen.dart';

class HerramientasScreen extends StatefulWidget {
  const HerramientasScreen({super.key});

  @override
  State<HerramientasScreen> createState() => _HerramientasScreenState();
}

class _HerramientasScreenState extends State<HerramientasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _activeTabIndex = _tabController.index;
        });
      } else {
        if (_activeTabIndex != _tabController.index) {
          setState(() {
            _activeTabIndex = _tabController.index;
          });
        }
      }
    });
    // Escucha el notifier global para saltar a la pestaña correcta
    herramientasTabNotifier.addListener(_onTabNotifier);
  }

  void _onTabNotifier() {
    final idx = herramientasTabNotifier.value;
    if (_tabController.index != idx) {
      _tabController.animateTo(idx);
    }
  }

  @override
  void dispose() {
    herramientasTabNotifier.removeListener(_onTabNotifier);
    _tabController.dispose();
    super.dispose();
  }

  List<_ToolItem> _getCalculadoras(BuildContext context) => [
        _ToolItem(
          "Caída de Tensión",
          "Sistemas 1Φ y 3Φ",
          Icons.flash_on_rounded,
          const Color(0xFF00E5FF),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraCaidaTensionPage())),
        ),
        _ToolItem(
          "Dimensionador de Circuito",
          "Sección mínima (ampacidad + caída)",
          Icons.design_services_rounded,
          const Color(0xFF7C3AED),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const DimensionadorCircuitoScreen())),
        ),
        _ToolItem(
          "Tensión (Voltaje)",
          "Ley de Ohm y Potencia",
          Icons.bolt_rounded,
          const Color(0xFF00FBFF),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculadoraVoltajePage())),
        ),
        _ToolItem(
          "Corriente (Amp)",
          "Circuitos 1Φ y 3Φ",
          Icons.electrical_services_rounded,
          DesignTokens.accent,
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraCorrientePage())),
        ),
        _ToolItem(
          "Ductos (RIC 04)",
          "Ocupación de tuberías",
          Icons.circle_outlined,
          const Color(0xFF10B981),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraDuctosScreen())),
        ),
        _ToolItem(
          "Malla de Tierra",
          "Método de Laurent",
          Icons.grid_4x4_rounded,
          const Color(0xFFF59E0B),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculadoraMallaScreen())),
        ),
        _ToolItem(
          "Motores (RIC 04)",
          "Partida y protección",
          Icons.settings_input_component_rounded,
          const Color(0xFF06B6D4),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraMotoresScreen())),
        ),
        _ToolItem(
          "Alumbrado (RIC 09)",
          "Método de lúmenes",
          Icons.lightbulb_outline_rounded,
          const Color(0xFFEAB308),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraAlumbradoScreen())),
        ),
        _ToolItem(
          "Protecciones",
          "Disyuntores (RIC 04)",
          Icons.security_rounded,
          const Color(0xFFF87171),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraProteccionesScreen())),
        ),
        _ToolItem(
          "Consumo y Costo",
          "Gasto mensual CLP",
          Icons.payments_rounded,
          const Color(0xFF10B981),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraConsumoScreen())),
        ),
        _ToolItem(
          "Baterías UPS",
          "Autonomía y respaldo",
          Icons.battery_charging_full_rounded,
          const Color(0xFFFBBF24),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraBateriasScreen())),
        ),
        _ToolItem(
          "Ampacidad Cables",
          "RIC N° 04 (Corrección)",
          Icons.amp_stories_rounded,
          const Color(0xFF00D1FF),
          () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CalculadoraCapacidadScreen())),
        ),
      ];

  List<_ToolItem> _getUtilidades(BuildContext context) => [
        _ToolItem(
          "Conversor AWG",
          "Equivalencia métrica",
          Icons.cable_rounded,
          const Color(0xFF64748B),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CalculadoraAWGScreen())),
        ),
        _ToolItem(
          "Tabla de Corrientes",
          "RIC N° 04 (Admisibles)",
          Icons.table_chart_rounded,
          const Color(0xFF00E5FF),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TablaCorrientesScreen())),
        ),
        _ToolItem(
          "Capacidad de Ruptura",
          "RIC N° 02 (kA Mínimos)",
          Icons.offline_bolt_rounded,
          const Color(0xFFF59E0B),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CapacidadRupturaScreen())),
        ),
        _ToolItem(
          "Código de Colores",
          "RIC N° 04 vs IEC",
          Icons.palette_rounded,
          const Color(0xFF10B981),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CodigoColoresScreen())),
        ),
        _ToolItem(
          "Grados IP / IK",
          "RIC N° 03 (Envolventes)",
          Icons.shield_rounded,
          const Color(0xFF8B5CF6),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GradosProteccionScreen())),
        ),
        _ToolItem(
          "Memoria Pre-TE1",
          "Trámite SEC simplificado",
          Icons.description_rounded,
          const Color(0xFF1E40AF),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MemoriaPrete1Screen())),
        ),
        _ToolItem(
          "Cubicador DIN",
          "Tableros RIC N° 02 (25% reserva)",
          Icons.grid_view_rounded,
          const Color(0xFF334155),
          () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CubicadorTablerosScreen())),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(brightness),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, brightness),
            _buildTabBarContainer(context, brightness),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ToolCategoryView(items: _getCalculadoras(context)),
                  _ToolCategoryView(items: _getUtilidades(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Brightness b) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "HERRAMIENTAS",
                style: TextStyle(
                  color: DesignTokens.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _activeTabIndex == 0
                    ? "Calculadoras Técnicas"
                    : "Utilidades Eléctricas",
                style: TextStyle(
                  color: DesignTokens.getTextPrimary(b),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: calculatorViewNotifier,
            builder: (context, isListView, _) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => saveCalculatorViewPreference(!isListView),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: DesignTokens.accent.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isListView
                              ? Icons.grid_view_rounded
                              : Icons.view_list_rounded,
                          size: 16,
                          color: DesignTokens.accent,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "VISTA",
                          style: TextStyle(
                            color: DesignTokens.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarContainer(BuildContext context, Brightness b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: DesignTokens.getCardBackground(b),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.getBorderColor(b)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: DesignTokens.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Colors.black,
          unselectedLabelColor: DesignTokens.getTextSecondary(b),
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "Calculadoras"),
            Tab(text: "Utilidades"),
          ],
        ),
      ),
    );
  }
}

class _ToolCategoryView extends StatefulWidget {
  final List<_ToolItem> items;

  const _ToolCategoryView({required this.items});

  @override
  State<_ToolCategoryView> createState() => _ToolCategoryViewState();
}

class _ToolCategoryViewState extends State<_ToolCategoryView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final brightness = Theme.of(context).brightness;

    return ValueListenableBuilder<bool>(
      valueListenable: calculatorViewNotifier,
      builder: (context, isListView, child) {
        return isListView
            ? _buildListView(context, brightness)
            : _buildGridView(context, brightness);
      },
    );
  }

  Widget _buildListView(BuildContext context, Brightness b) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: widget.items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildCalcCardList(context, item, b),
              ))
          .toList(),
    );
  }

  Widget _buildGridView(BuildContext context, Brightness b) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;

    return GridView.count(
      crossAxisCount: crossAxisCount,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: screenWidth > 600 ? 1.0 : 1.1,
      children: widget.items
          .map((item) => _buildCalcCardGrid(context, item, b))
          .toList(),
    );
  }

  Widget _buildCalcCardList(
      BuildContext context, _ToolItem item, Brightness b) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.getCardBackground(b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: DesignTokens.getBorderColor(b).withAlpha(80)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: item.color.withAlpha(20), shape: BoxShape.circle),
                  child: Icon(item.icon, color: item.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: DesignTokens.getTextPrimary(b))),
                      Text(item.subtitle,
                          style: TextStyle(
                              color: DesignTokens.getTextSecondary(b),
                              fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: item.color.withAlpha(120), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalcCardGrid(
      BuildContext context, _ToolItem item, Brightness b) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.getCardBackground(b),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: DesignTokens.getBorderColor(b).withAlpha(80)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: item.color.withAlpha(20), shape: BoxShape.circle),
                child: Icon(item.icon, color: item.color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: DesignTokens.getTextPrimary(b),
                    height: 1.1),
              ),
              const SizedBox(height: 4),
              Text(
                item.subtitle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: DesignTokens.getTextSecondary(b), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ToolItem(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
