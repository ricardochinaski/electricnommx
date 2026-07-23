import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kNavyBlue = Color(0xFF1E40AF);
const _kIndustrialGrey = Color(0xFF475569);

class MemoriaPrete1Screen extends StatefulWidget {
  const MemoriaPrete1Screen({super.key});

  @override
  State<MemoriaPrete1Screen> createState() => _MemoriaPrete1ScreenState();
}

class _MemoriaPrete1ScreenState extends State<MemoriaPrete1Screen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores y estados
  final _nombreProyectoCtrl = TextEditingController(text: 'Instalación Domiciliaria');
  String _tipoInstalacion = 'Residencial'; // Residencial, Comercial, Industrial
  final _potenciaCtrl = TextEditingController(text: '6.0');
  String _tipoEmpalme = 'Monofásico (A9 / A6)'; // Monofásico (A9 / A6), Trifásico (B9 / B6), Otro
  final _capacidadEmpalmeCtrl = TextEditingController(text: '25');
  int _cantidadCircuitos = 3;
  String _tipoCanalizacion = 'Conduit PVC'; // Conduit PVC, Bandeja Metálica, Embutido, Sobrepuesto
  String _sistemaTierra = 'Barra Cooperweld'; // Barra Cooperweld, Malla de Tierra, Delta de Barras

  String? _memoriaGenerada;

  void _generarMemoria() {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreProyectoCtrl.text.trim();
    final tipo = _tipoInstalacion;
    final potencia = _potenciaCtrl.text.trim();
    final empalme = _tipoEmpalme;
    final capacidad = _capacidadEmpalmeCtrl.text.trim();
    final circuitos = _cantidadCircuitos;
    final canalizacion = _tipoCanalizacion;
    final tierra = _sistemaTierra;

    final texto = '''
MEMORIA EXPLICATIVA SIMPLIFICADA (PRE-TE1)

Proyecto: $nombre
Instalación: $tipo

Por medio de la presente se describe la instalación eléctrica cuya potencia total instalada corresponde a $potencia kW, alimentada mediante un empalme de tipo $empalme con una protección general de $capacidad A. La distribución consta de un total de $circuitos circuitos protegidos mediante disyuntores magnetotérmicos y protectores diferenciales correspondientes. Las canalizaciones principales se ejecutaron de forma $canalizacion, asegurando la continuidad y aislamiento bajo la norma vigente. El sistema de puesta a tierra implementado consiste en $tierra, garantizando tensiones de paso y contacto seguras bajo los límites del RIC N°06.
''';

    setState(() {
      _memoriaGenerada = texto;
    });

    FocusScope.of(context).unfocus();
  }

  void _copiarAlPortapapeles() {
    if (_memoriaGenerada == null) return;
    Clipboard.setData(ClipboardData(text: _memoriaGenerada!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Memoria explicativa copiada al portapapeles.'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _limpiar() {
    setState(() {
      _memoriaGenerada = null;
      _nombreProyectoCtrl.text = 'Instalación Domiciliaria';
      _tipoInstalacion = 'Residencial';
      _potenciaCtrl.text = '6.0';
      _tipoEmpalme = 'Monofásico (A9 / A6)';
      _capacidadEmpalmeCtrl.text = '25';
      _cantidadCircuitos = 3;
      _tipoCanalizacion = 'Conduit PVC';
      _sistemaTierra = 'Barra Cooperweld';
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final isPremium = context.watch<PremiumProvider>().isPremium;

    return Scaffold(
      backgroundColor: DesignTokens.getBackground(b),
      appBar: AppBar(
        backgroundColor: DesignTokens.getSurface(b),
        elevation: 0,
        iconTheme: IconThemeData(color: DesignTokens.getTextPrimary(b)),
        title: Row(
          children: [
            const Icon(Icons.description_rounded, color: _kNavyBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIMULADOR DE MEMORIA (TE1)',
                    style: DesignTokens.getDisplay(b, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Esquema Simplificado Obligatorio SEC',
                    style: TextStyle(
                      color: DesignTokens.getTextSecondary(b),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!isPremium) ...[
              AdBannerWidget(adUnitId: AdBannerWidget.bannerCalcuAdUnitId, bottomPadding: 8.0),
            ],
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 80),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoBox(b),
                      const SizedBox(height: 20),
                      _buildFormCard(b),
                      const SizedBox(height: 24),
                      _buildActionButtons(b),
                      const SizedBox(height: 24),
                      if (_memoriaGenerada != null) _buildOutputCard(b),
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

  Widget _infoBox(Brightness b) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _kNavyBlue.withAlpha(15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _kNavyBlue.withAlpha(40)),
    ),
    child: Row(
      children: [
        const Icon(Icons.menu_book_rounded, color: _kNavyBlue, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Rellene los datos de obra requeridos por la SEC en Chile para estructurar y redactar la memoria técnica descriptiva preliminar de su proyecto TE1.',
            style: TextStyle(fontSize: 11, color: DesignTokens.getTextPrimary(b).withAlpha(200)),
          ),
        ),
      ],
    ),
  );

  Widget _buildFormCard(Brightness b) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: DesignTokens.getCardBackground(b),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: DesignTokens.getBorderColor(b)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('INFORMACIÓN DEL PROYECTO'),
        const SizedBox(height: 16),

        // Nombre de obra
        _textInputField(
          _nombreProyectoCtrl, 
          'Nombre del Proyecto / Obra', 
          'Ej: Casa Ricardo Chinaski', 
          Icons.apartment_rounded, 
          b
        ),
        const SizedBox(height: 16),

        // Tipo de instalación
        _dropdown(
          'Tipo de Instalación', 
          _tipoInstalacion, 
          ['Residencial', 'Comercial', 'Industrial'], 
          (v) => setState(() => _tipoInstalacion = v!), 
          b
        ),
        const SizedBox(height: 16),

        _sectionLabel('ESPECIFICACIONES TÉCNICAS'),
        const SizedBox(height: 16),

        // Potencia Instalada
        _textInputField(
          _potenciaCtrl, 
          'Potencia Solicitada / Instalada (kW)', 
          'Ej: 6.0', 
          Icons.bolt_rounded, 
          b, 
          isNumeric: true
        ),
        const SizedBox(height: 16),

        // Tipo de Empalme
        _dropdown(
          'Tipo de Empalme', 
          _tipoEmpalme, 
          ['Monofásico (A9 / A6)', 'Trifásico (B9 / B6)', 'Otro'], 
          (v) => setState(() => _tipoEmpalme = v!), 
          b
        ),
        const SizedBox(height: 16),

        // Capacidad Empalme
        _textInputField(
          _capacidadEmpalmeCtrl, 
          'Capacidad / Protección General (Amp)', 
          'Ej: 25', 
          Icons.electric_meter_rounded, 
          b, 
          isNumeric: true
        ),
        const SizedBox(height: 16),

        // Cantidad de Circuitos (con +/- incrementador)
        _buildCircuitsCounter(b),
        const SizedBox(height: 16),

        _sectionLabel('INFRAESTRUCTURA Y SEGURIDAD'),
        const SizedBox(height: 16),

        // Tipo de Canalizaciones
        _dropdown(
          'Tipo de Canalizaciones Principales', 
          _tipoCanalizacion, 
          ['Conduit PVC', 'Bandeja Metálica', 'Embutido', 'Sobrepuesto'], 
          (v) => setState(() => _tipoCanalizacion = v!), 
          b
        ),
        const SizedBox(height: 16),

        // Puesta a Tierra
        _dropdown(
          'Sistema de Puesta a Tierra', 
          _sistemaTierra, 
          ['Barra Cooperweld', 'Malla de Tierra', 'Delta de Barras'], 
          (v) => setState(() => _sistemaTierra = v!), 
          b
        ),
      ],
    ),
  );

  Widget _sectionLabel(String label) => Row(
    children: [
      Container(width: 4, height: 14, decoration: BoxDecoration(color: _kNavyBlue, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(
        label, 
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.2, color: _kNavyBlue)
      ),
    ],
  );

  Widget _textInputField(TextEditingController ctrl, String label, String hint, IconData icon, Brightness b, {bool isNumeric = false}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
      const SizedBox(height: 8),
      TextFormField(
        controller: ctrl,
        keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16, color: _kNavyBlue),
          hintText: hint,
          filled: true,
          fillColor: DesignTokens.getBackground(b),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Requerido';
          if (isNumeric && double.tryParse(v.replaceAll(',', '.')) == null) return 'Inválido';
          return null;
        },
      ),
    ],
  );

  Widget _dropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: DesignTokens.getBackground(b), borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: DesignTokens.getSurface(b),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ],
  );

  Widget _buildCircuitsCounter(Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Cantidad Total de Circuitos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.getTextSecondary(b))),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: DesignTokens.getBackground(b),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$_cantidadCircuitos circuitos',
              style: TextStyle(color: DesignTokens.getTextPrimary(b), fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded, color: _kNavyBlue, size: 24),
                  onPressed: () {
                    if (_cantidadCircuitos > 1) {
                      setState(() => _cantidadCircuitos--);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: _kNavyBlue, size: 24),
                  onPressed: () {
                    setState(() => _cantidadCircuitos++);
                  },
                ),
              ],
            )
          ],
        ),
      ),
    ],
  );

  Widget _buildActionButtons(Brightness b) => Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: _generarMemoria,
          icon: const Icon(Icons.description_rounded, color: Colors.white, size: 18),
          label: const Text('GENERAR MEMORIA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kNavyBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      const SizedBox(width: 12),
      OutlinedButton(
        onPressed: _limpiar,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _kIndustrialGrey),
          foregroundColor: _kIndustrialGrey,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Icon(Icons.refresh_rounded, size: 20),
      ),
    ],
  );

  Widget _buildOutputCard(Brightness b) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _kNavyBlue.withAlpha(10),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _kNavyBlue.withAlpha(50), width: 1.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MEMORIA GENERADA (PRE-TE1)',
              style: GoogleFonts.outfit(
                color: _kNavyBlue,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: _kNavyBlue, size: 20),
              onPressed: _copiarAlPortapapeles,
              tooltip: 'Copiar al portapapeles',
            )
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.getSurface(b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.getBorderColor(b)),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _memoriaGenerada!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  color: DesignTokens.getTextPrimary(b),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: _copiarAlPortapapeles,
            icon: const Icon(Icons.copy_all_rounded, size: 18),
            label: const Text('COPIAR AL PORTAPAPELES', style: TextStyle(fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              foregroundColor: _kNavyBlue,
            ),
          ),
        ),
      ],
    ),
  );
}

