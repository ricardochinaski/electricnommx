import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nom_electrica_mx/theme.dart';

/// Un panel estandarizado de botones para todas las calculadoras técnicas.
/// Incluye las acciones de Calcular, Limpiar, Compartir y Exportar PDF.
class CalculatorButtonsPanel extends StatelessWidget {
  final VoidCallback onCalculate;
  final VoidCallback onReset;
  final VoidCallback? onShare;
  final VoidCallback? onExportPdf;
  final bool showResults;
  final Color mainColor;
  final String calculateLabel;

  const CalculatorButtonsPanel({
    super.key,
    required this.onCalculate,
    required this.onReset,
    this.onShare,
    this.onExportPdf,
    required this.showResults,
    this.mainColor = const Color(0xFF00E5FF),
    this.calculateLabel = 'CALCULAR',
  });

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    
    return Column(
      children: [
        // Fila Principal: Calcular y Restablecer
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: mainColor.withAlpha(60),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Feedback háptico: confirmación táctil en terreno (guantes)
                    HapticFeedback.mediumImpact();
                    onCalculate();
                  },
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: Text(
                    calculateLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: Icon(Icons.restart_alt_rounded, 
                    size: 16, color: DesignTokens.getTextSecondary(b)),
                label: Text(
                  'LIMPIAR',
                  style: TextStyle(
                    color: DesignTokens.getTextSecondary(b),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: DesignTokens.getBorderColor(b)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Acciones de Reporte (Solo si hay resultados)
        if (showResults) ...[
          const SizedBox(height: 20),
          Column(
            children: [
              if (onShare != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text(
                      'COMPARTIR REPORTE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13, 
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1), // Indigo premium
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              if (onShare != null && onExportPdf != null) const SizedBox(height: 12),
              if (onExportPdf != null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onExportPdf,
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                    label: const Text(
                      'EXPORTAR A PDF',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 13, 
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: mainColor,
                      side: BorderSide(color: mainColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
