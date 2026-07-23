import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/models/ric_data.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/app_state.dart';

class NormasScreen extends StatefulWidget {
  const NormasScreen({super.key});

  @override
  State<NormasScreen> createState() => _NormasScreenState();
}

class _NormasScreenState extends State<NormasScreen> {
  bool _isRicSelected = true;

  @override
  void initState() {
    super.initState();
    normasIsRicNotifier.addListener(_onDeepLink);
  }

  void _onDeepLink() {
    if (mounted) {
      setState(() => _isRicSelected = normasIsRicNotifier.value);
    }
  }

  @override
  void dispose() {
    normasIsRicNotifier.removeListener(_onDeepLink);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: DesignTokens.getBackground(brightness),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, brightness),
            _buildToggleButtons(brightness),
            const SizedBox(height: 4),
            _buildInstructionBanner(brightness),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: normsViewNotifier,
                builder: (context, isListView, child) {
                  return isListView 
                      ? _buildListView(context, brightness)
                      : _buildGridView(context, brightness);
                },
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "NORMATIVA SEC",
                  style: TextStyle(
                    color: DesignTokens.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, -0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _isRicSelected ? "NOM-001-SEDE-2012" : "Norma Completa",
                    key: ValueKey<bool>(_isRicSelected),
                    style: TextStyle(
                      color: DesignTokens.getTextPrimary(b),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: normsViewNotifier,
            builder: (context, isListView, _) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => saveNormsViewPreference(!isListView),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DesignTokens.accent.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isListView ? Icons.grid_view_rounded : Icons.view_list_rounded,
                          size: 16,
                          color: DesignTokens.accent,
                        ),
                        const SizedBox(width: 8),
                        Text(
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

  Widget _buildToggleButtons(Brightness b) {
    final activeBgColor = DesignTokens.accent;
    final activeTextColor = Colors.black;
    final inactiveTextColor = DesignTokens.getTextSecondary(b);
    final borderColor = DesignTokens.getBorderColor(b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: b == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isRicSelected) {
                    setState(() {
                      _isRicSelected = true;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isRicSelected ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: _isRicSelected ? activeTextColor : inactiveTextColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Artículos Clave",
                        style: TextStyle(
                          color: _isRicSelected ? activeTextColor : inactiveTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isRicSelected) {
                    setState(() {
                      _isRicSelected = false;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: !_isRicSelected ? activeBgColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lan_rounded,
                        color: !_isRicSelected ? activeTextColor : inactiveTextColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Norma Completa",
                        style: TextStyle(
                          color: !_isRicSelected ? activeTextColor : inactiveTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionBanner(Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF6366F1).withAlpha(60),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: DesignTokens.accent,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isRicSelected 
                    ? "Toca un artículo para abrir la NOM directo en esa sección."
                    : "Abre el texto íntegro de la NOM-001-SEDE-2012 con buscador.",
                style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.getTextPrimary(
                    brightness,
                  ).withAlpha(204),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, Brightness b) {
    final list = _isRicSelected ? RicData.pliegos : RicData.pliegosRptd;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return _buildNormCardList(context, p, b);
      },
    );
  }

  Widget _buildGridView(BuildContext context, Brightness b) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;
    final list = _isRicSelected ? RicData.pliegos : RicData.pliegosRptd;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final p = list[index];
        return _buildNormCardGrid(context, p, b);
      },
    );
  }

  Widget _buildNormCardList(BuildContext context, Map<String, dynamic> p, Brightness b) {
    final int num = p['num'] as int;
    final Color color = p['color'] as Color;
    final IconData icon = p['icon'] as IconData;
    final String etiqueta = (p['articulo'] as String?) ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _isRicSelected 
              ? RicData.navegarARic(context, num) 
              : RicData.navegarARptd(context, num),
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withAlpha(40),
          highlightColor: color.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.getCardBackground(b),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DesignTokens.getBorderColor(b),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withAlpha(120),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            etiqueta,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['titulo'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: DesignTokens.getTextPrimary(b),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p['desc'] as String,
                        style: TextStyle(
                          color: DesignTokens.getTextSecondary(b),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withAlpha(160),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNormCardGrid(BuildContext context, Map<String, dynamic> p, Brightness b) {
    final int num = p['num'] as int;
    final Color color = p['color'] as Color;
    final IconData icon = p['icon'] as IconData;
    final String etiqueta = (p['articulo'] as String?) ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _isRicSelected 
            ? RicData.navegarARic(context, num) 
            : RicData.navegarARptd(context, num),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DesignTokens.getCardBackground(b),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DesignTokens.getBorderColor(b).withAlpha(80),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 10),
              Text(
                etiqueta,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p['titulo'] as String,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: DesignTokens.getTextPrimary(b),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                p['desc'] as String,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(b),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
