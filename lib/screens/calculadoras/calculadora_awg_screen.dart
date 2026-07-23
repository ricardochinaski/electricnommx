import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kElectric = Color(0xFF00E5FF);

class CalculadoraAWGScreen extends StatefulWidget {
  const CalculadoraAWGScreen({super.key});

  @override
  State<CalculadoraAWGScreen> createState() => _CalculadoraAWGScreenState();
}

class _CalculadoraAWGScreenState extends State<CalculadoraAWGScreen> {
  bool _isAwgToMm = true;
  bool _hasShownAd = false;  // Intersticial se muestra solo una vez por sesión
  String _selectedAWG = '14 AWG';
  String _selectedMetric = '2.5 mm²';

  final Map<String, Map<String, String>> _awgData = {
    '18 AWG': {'mm2': '0.82', 'diametro': '1.02', 'amp': '7'},
    '16 AWG': {'mm2': '1.31', 'diametro': '1.29', 'amp': '10'},
    '14 AWG': {'mm2': '2.08', 'diametro': '1.63', 'amp': '15'},
    '12 AWG': {'mm2': '3.31', 'diametro': '2.05', 'amp': '20'},
    '10 AWG': {'mm2': '5.26', 'diametro': '2.59', 'amp': '30'},
    '8 AWG': {'mm2': '8.37', 'diametro': '3.26', 'amp': '40'},
    '6 AWG': {'mm2': '13.30', 'diametro': '4.11', 'amp': '55'},
    '4 AWG': {'mm2': '21.20', 'diametro': '5.19', 'amp': '70'},
    '2 AWG': {'mm2': '33.60', 'diametro': '6.54', 'amp': '95'},
    '1 AWG': {'mm2': '42.40', 'diametro': '7.35', 'amp': '110'},
    '1/0 AWG': {'mm2': '53.50', 'diametro': '8.25', 'amp': '125'},
    '2/0 AWG': {'mm2': '67.40', 'diametro': '9.27', 'amp': '145'},
    '3/0 AWG': {'mm2': '85.00', 'diametro': '10.40', 'amp': '165'},
    '4/0 AWG': {'mm2': '107.00', 'diametro': '11.68', 'amp': '195'},
    '250 MCM': {'mm2': '127.00', 'diametro': '14.61', 'amp': '215'},
    '350 MCM': {'mm2': '177.00', 'diametro': '17.30', 'amp': '260'},
    '500 MCM': {'mm2': '253.00', 'diametro': '20.65', 'amp': '320'},
  };

  final Map<String, String> _metricToAwg = {
    '1.5 mm²': '16 AWG',
    '2.5 mm²': '14 AWG',
    '4.0 mm²': '12 AWG',
    '6.0 mm²': '10 AWG',
    '10.0 mm²': '8 AWG',
    '16.0 mm²': '6 AWG',
    '25.0 mm²': '4 AWG',
    '35.0 mm²': '2 AWG',
    '50.0 mm²': '1/0 AWG',
    '70.0 mm²': '2/0 AWG',
    '95.0 mm²': '3/0 AWG',
    '120.0 mm²': '4/0 AWG',
  };

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;
    
    String displayResult;
    String resultUnit;
    String labelText;
    String subTitle;
    Map<String, String> details;
    String shareText;

    if (_isAwgToMm) {
      details = _awgData[_selectedAWG]!;
      displayResult = details['mm2']!;
      resultUnit = 'mm²';
      labelText = 'CALIBRE AMERICANO SELECCIONADO';
      subTitle = 'SECCIÓN MÉTRICA EQUIVALENTE';
      shareText = '📌 *Equivalencia AWG*\n$_selectedAWG = $displayResult mm²\nDiámetro: ${details['diametro']} mm\n_App NOM Eléctrica MX_';
    } else {
      final awg = _metricToAwg[_selectedMetric]!;
      details = _awgData[awg]!;
      displayResult = awg;
      resultUnit = '';
      labelText = 'SECCIÓN MÉTRICA SELECCIONADA';
      subTitle = 'CALIBRE AWG EQUIVALENTE';
      shareText = '📌 *Equivalencia Métrica*\n$_selectedMetric ≈ $displayResult\nDiámetro: ${details['diametro']} mm\n_App NOM Eléctrica MX_';
    }

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b), elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(children: [
          const Icon(Icons.cable_rounded, color: _kElectric, size: 22), const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CONVERSOR AWG / MM²', style: DesignTokens.getDisplay(b, fontSize: 16)),
            Text('Conversión bidireccional de conductores', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11)),
          ]),
        ]),
      ),
      body: Column(
        children: [
          if (!isPremium) ...[  
            SafeArea(
              top: true,
              bottom: false,
              child: AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
            ),
          ],
          Expanded(
            child: Container(
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [DesignTokens.getSurface(b), DesignTokens.getBackground(b)])),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Switch de dirección
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(12), border: Border.all(color: DesignTokens.getBorderColor(b))),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _directionOption('AWG ➔ mm²', _isAwgToMm, () => setState(() => _isAwgToMm = true), b),
                  _directionOption('mm² ➔ AWG', !_isAwgToMm, () => setState(() => _isAwgToMm = false), b),
                ]),
              ),
            ),
            const SizedBox(height: 32),
            Row(children: [
              Text(labelText, style: TextStyle(color: _kElectric, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const Spacer(),
              GestureDetector(
                onTap: () => _showHelpDialog(context, labelText, _isAwgToMm 
                  ? 'El calibre AWG (American Wire Gauge) es un estándar de sección de conductores. A menor número AWG, mayor es el grosor del cable.' 
                  : 'En México el estándar para dimensionar conductores es el calibre AWG/kcmil (NOM-001-SEDE); la sección métrica (mm²) es su equivalencia IEC.'),
                child: Icon(Icons.info_outline_rounded, color: _kElectric.withAlpha(150), size: 16),
              ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(16), border: Border.all(color: DesignTokens.getBorderColor(b))),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _isAwgToMm ? _selectedAWG : _selectedMetric, 
                  isExpanded: true,
                  dropdownColor: DesignTokens.getSurface(b),
                  icon: const Icon(Icons.unfold_more_rounded, color: _kElectric),
                  items: (_isAwgToMm ? _awgData.keys.toList() : _metricToAwg.keys.toList()).map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold)))).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        if (_isAwgToMm) {
                          _selectedAWG = v;
                        } else {
                          _selectedMetric = v;
                        }
                      });
                      // Mostrar intersticial solo la primera vez (usuarios gratuitos)
                      if (!_hasShownAd) {
                        _hasShownAd = true;
                        AdService.instance.showInterstitial(context);
                      }
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildMainResult(displayResult, resultUnit, subTitle, b),
            const SizedBox(height: 24),
            _buildDetailsTable(details, b),
            const SizedBox(height: 40),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  SharePlus.instance.share(ShareParams(text: shareText));
                },
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('COMPARTIR EQUIVALENCIA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kElectric, side: const BorderSide(color: _kElectric),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildTechnicalCard(b),
            const SizedBox(height: 32),
          ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: DesignTokens.getSurface(Theme.of(context).brightness),
        title: Row(children: [
          const Icon(Icons.info_outline_rounded, color: _kElectric),
          const SizedBox(width: 10),
          Text('Ayuda Técnica', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Text(message, style: TextStyle(color: DesignTokens.getTextPrimary(Theme.of(context).brightness).withAlpha(200), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ENTENDIDO', style: TextStyle(color: _kElectric, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _directionOption(String label, bool active, VoidCallback onTap, Brightness b) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: active ? _kElectric : Colors.transparent, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: active ? Colors.black : DesignTokens.getTextSecondary(b), fontWeight: FontWeight.bold, fontSize: 12)),
    ),
  );

  Widget _buildMainResult(String val, String unit, String sub, Brightness b) => Container(
    width: double.infinity, padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(color: _kElectric.withAlpha(15), borderRadius: BorderRadius.circular(24), border: Border.all(color: _kElectric.withAlpha(80)), boxShadow: [BoxShadow(color: _kElectric.withAlpha(20), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Column(children: [
      Text(sub, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
        Text(val, style: GoogleFonts.outfit(fontSize: val.length > 5 ? 42 : 56, fontWeight: FontWeight.w900, color: _kElectric)),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(unit, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kElectric.withAlpha(180))),
        ],
      ]),
    ]),
  );

  Widget _buildDetailsTable(Map<String, String> data, Brightness b) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(20), border: Border.all(color: DesignTokens.getBorderColor(b))),
    child: Column(children: [
      _detailRow(Icons.circle_outlined, 'Diámetro del Conductor', '${data['diametro']} mm', b),
      Divider(height: 24, color: DesignTokens.getBorderColor(b)),
      _detailRow(Icons.bolt_rounded, 'Ampacidad Estimada (60°C)', '${data['amp']} A', b),
      Divider(height: 24, color: DesignTokens.getBorderColor(b)),
      _detailRow(Icons.info_outline_rounded, 'Referencia', 'Tabla AWG / NEC', b),
    ]),
  );

  Widget _detailRow(IconData icon, String label, String val, Brightness b) => Row(children: [
    Icon(icon, color: DesignTokens.getTextSecondary(b), size: 18),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13))),
    Text(val, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 14)),
  ]);

  Widget _buildTechnicalCard(Brightness b) {
    const kFormula = Color(0xFF818CF8);
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: DesignTokens.getCardBackground(b), borderRadius: BorderRadius.circular(18), border: Border.all(color: kFormula.withAlpha(60))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.functions_rounded, color: kFormula, size: 18), const SizedBox(width: 8),
          const Text('BASE TÉCNICA AWG', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: kFormula.withAlpha(25), borderRadius: BorderRadius.circular(8)), child: const Text('ASTM B258', style: TextStyle(color: kFormula, fontSize: 11, fontWeight: FontWeight.bold))),
        ]),
        const SizedBox(height: 16),
        Center(child: FittedBox(child: Text('d_n = 0.127 · 92 ^ [(36-n)/39]', style: GoogleFonts.firaCode(fontSize: 15, fontWeight: FontWeight.bold, color: kFormula)))),
        const SizedBox(height: 16),
        Divider(color: DesignTokens.getBorderColor(b)),
        const SizedBox(height: 10),
        _legendRow('d_n', 'Diámetro del calibre n', 'mm', kFormula, b),
        _legendRow('n', 'Número de calibre AWG', '#', kFormula, b),
        const SizedBox(height: 8),
        Text('La escala AWG es una progresión geométrica donde el calibre 36 es 0.005 pulgadas y el 0000 (4/0) es 0.46 pulgadas.', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _legendRow(String s, String d, String u, Color color, Brightness b) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(children: [
      SizedBox(width: 65, child: Text(s, style: GoogleFonts.firaCode(fontSize: 12, color: color, fontWeight: FontWeight.bold))),
      Expanded(child: Text(d, style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 12))),
      Text(u, style: TextStyle(color: DesignTokens.getTextPrimary(b), fontSize: 11, fontWeight: FontWeight.bold)),
    ]),
  );
}

