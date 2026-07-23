import 'package:flutter/material.dart';
import 'package:nom_electrica_mx/theme.dart';

class AnimatedElevationCard extends StatefulWidget {
  final BuildContext context;
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFullWidth;

  const AnimatedElevationCard({
    super.key,
    required this.context,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFullWidth = false,
  });

  @override
  State<AnimatedElevationCard> createState() => _AnimatedElevationCardState();
}

class _AnimatedElevationCardState extends State<AnimatedElevationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardBg = DesignTokens.getCardBackground(brightness);
    final borderColor = DesignTokens.getBorderColor(brightness);

    final card = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(vertical: widget.isFullWidth ? 24 : 20),
          constraints: BoxConstraints(minHeight: widget.isFullWidth ? 80 : 100),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed ? widget.color : borderColor,
              width: _isPressed ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(_isPressed ? 40 : 10),
                blurRadius: _isPressed ? 15 : 5,
                offset: Offset(0, _isPressed ? 4 : 2),
              ),
            ],
          ),
        child: widget.isFullWidth
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: DesignTokens.getBody(
                              brightness,
                              fontSize: 18,
                            ).copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Consulta los 19 documentos oficiales",
                            style: TextStyle(
                              color: DesignTokens.getTextSecondary(brightness)
                                  .withAlpha(150),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: DesignTokens.accent.withAlpha(100),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.color,
                    size: 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: DesignTokens.getBody(
                      brightness,
                      fontSize: 11,
                    ).copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
        ),
      ),
    );

    return widget.isFullWidth ? card : Expanded(child: card);
  }
}
