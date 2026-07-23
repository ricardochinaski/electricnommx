import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:nom_electrica_mx/theme.dart';
import 'package:nom_electrica_mx/providers/premium_provider.dart';
import 'package:nom_electrica_mx/widgets/ad_banner_widget.dart';

const _kNavyBlue = Color(0xFF1E40AF);
const _kIndustrialGrey = Color(0xFF475569);
const _kReserveAmber = Color(0xFFF59E0B);
const _kSuccessGreen = Color(0xFF10B981);

// Tipos de Gabinetes en el mercado chileno
enum _TipoGabinete {
  metalicoSobrepuesto,
  metalicoEmbutido,
  resinaTermoplastica,
  poliesterReforzado,
}

extension _TipoGabineteExt on _TipoGabinete {
  String get label {
    switch (this) {
      case _TipoGabinete.metalicoSobrepuesto: return 'Gabinete Metálico Sobrepuesto';
      case _TipoGabinete.metalicoEmbutido:    return 'Gabinete Metálico Embutido';
      case _TipoGabinete.resinaTermoplastica: return 'Tablero de Resina Termoplástica';
      case _TipoGabinete.poliesterReforzado:  return 'Gabinete de Poliéster Reforzado';
    }
  }
}

// Tipos de componentes DIN y sus módulos DIN que ocupan en Chile
enum _TipoComponente {
  disyuntorCurvaB,          // 1 módulo
  disyuntorCurvaC,          // 1 módulo
  disyuntorCurvaD,          // 1 módulo
  disyuntorTrifaCurvaC,     // 3 módulos
  disyuntorTrifaCurvaD,     // 3 módulos
  diferencialClaseAC,       // 2 módulos
  diferencialClaseASuper,   // 2 módulos
  diferencialTrifaAC,       // 4 módulos
  diferencialTrifaSuper,    // 4 módulos
  dpsMonofasico,            // 1 módulo
  dpsTrifasico,             // 4 módulos
  luzPilotoMono,            // 1 módulo
  luzPilotoTrifa,           // 3 módulos
  voltimetroDIN,            // 1 módulo
  amperimetroDIN,           // 1 módulo
}

extension _TipoComponenteExt on _TipoComponente {
  String get label {
    switch (this) {
      case _TipoComponente.disyuntorCurvaB:        return 'Disyuntor Curva B (1P)';
      case _TipoComponente.disyuntorCurvaC:        return 'Disyuntor Curva C (1P)';
      case _TipoComponente.disyuntorCurvaD:        return 'Disyuntor Curva D (1P)';
      case _TipoComponente.disyuntorTrifaCurvaC:   return 'Disyuntor Trifásico Curva C (3P)';
      case _TipoComponente.disyuntorTrifaCurvaD:   return 'Disyuntor Trifásico Curva D (3P)';
      case _TipoComponente.diferencialClaseAC:     return 'Diferencial Clase AC (2P)';
      case _TipoComponente.diferencialClaseASuper: return 'Diferencial Clase A Superinmunizado (2P)';
      case _TipoComponente.diferencialTrifaAC:     return 'Diferencial Trifásico Clase AC (4P)';
      case _TipoComponente.diferencialTrifaSuper:  return 'Diferencial Trifásico Clase A Superinmunizado (4P)';
      case _TipoComponente.dpsMonofasico:          return 'Protector Sobretensión DPS Monofásico (1P)';
      case _TipoComponente.dpsTrifasico:           return 'Protector Sobretensión DPS Trifásico (4P)';
      case _TipoComponente.luzPilotoMono:          return 'Luz Piloto Monofásica (1P)';
      case _TipoComponente.luzPilotoTrifa:         return 'Luz Piloto Trifásica (3P)';
      case _TipoComponente.voltimetroDIN:          return 'Voltímetro DIN (1P)';
      case _TipoComponente.amperimetroDIN:         return 'Amperímetro DIN (1P)';
    }
  }

  int get modulosDin {
    switch (this) {
      case _TipoComponente.disyuntorCurvaB:
      case _TipoComponente.disyuntorCurvaC:
      case _TipoComponente.disyuntorCurvaD:
      case _TipoComponente.dpsMonofasico:
      case _TipoComponente.luzPilotoMono:
      case _TipoComponente.voltimetroDIN:
      case _TipoComponente.amperimetroDIN:         return 1;
      case _TipoComponente.diferencialClaseAC:
      case _TipoComponente.diferencialClaseASuper: return 2;
      case _TipoComponente.disyuntorTrifaCurvaC:
      case _TipoComponente.disyuntorTrifaCurvaD:
      case _TipoComponente.luzPilotoTrifa:         return 3;
      case _TipoComponente.diferencialTrifaAC:
      case _TipoComponente.diferencialTrifaSuper:
      case _TipoComponente.dpsTrifasico:           return 4;
    }
  }

  IconData get icon {
    switch (this) {
      case _TipoComponente.disyuntorCurvaB:
      case _TipoComponente.disyuntorCurvaC:
      case _TipoComponente.disyuntorCurvaD:        return Icons.electrical_services_rounded;
      case _TipoComponente.disyuntorTrifaCurvaC:
      case _TipoComponente.disyuntorTrifaCurvaD:   return Icons.electric_meter_rounded;
      case _TipoComponente.diferencialClaseAC:
      case _TipoComponente.diferencialClaseASuper: return Icons.security_rounded;
      case _TipoComponente.diferencialTrifaAC:
      case _TipoComponente.diferencialTrifaSuper:  return Icons.shield_rounded;
      case _TipoComponente.dpsMonofasico:
      case _TipoComponente.dpsTrifasico:           return Icons.bolt_rounded;
      case _TipoComponente.luzPilotoMono:
      case _TipoComponente.luzPilotoTrifa:         return Icons.lightbulb_outline_rounded;
      case _TipoComponente.voltimetroDIN:
      case _TipoComponente.amperimetroDIN:         return Icons.speed_rounded;
    }
  }
}

class _ComponenteItem {
  _TipoComponente tipo;
  int cantidad;

  _ComponenteItem({
    required this.tipo,
    required this.cantidad,
  });

  int get totalModulos => tipo.modulosDin * cantidad;
}

class CubicadorTablerosScreen extends StatefulWidget {
  const CubicadorTablerosScreen({super.key});

  @override
  State<CubicadorTablerosScreen> createState() => _CubicadorTablerosScreenState();
}

class _CubicadorTablerosScreenState extends State<CubicadorTablerosScreen> {
  // Tamaños comerciales de tableros en Chile (módulos DIN)
  static const List<int> _tamanosComerciales = [6, 12, 18, 24, 36, 48, 72, 96];

  _TipoGabinete _selectedGabinete = _TipoGabinete.metalicoSobrepuesto;

  final List<_ComponenteItem> _componentes = [
    _ComponenteItem(tipo: _TipoComponente.disyuntorCurvaC, cantidad: 4),
    _ComponenteItem(tipo: _TipoComponente.diferencialClaseAC, cantidad: 1),
  ];

  // Cálculos resultantes
  int get _modulosUtiles =>
      _componentes.fold(0, (sum, c) => sum + c.totalModulos);

  double get _modulosTotalesConReserva => _modulosUtiles / 0.75;

  int get _modulosNecesarios => _modulosTotalesConReserva.ceil();

  /// True si ni el mayor gabinete comercial (96 DIN) alcanza para los
  /// componentes + la reserva obligatoria del 25% (RIC N°02).
  bool get _excedeTamanoComercial => _modulosNecesarios > _tamanosComerciales.last;

  int get _gabineteComercial {
    for (final t in _tamanosComerciales) {
      if (t >= _modulosNecesarios) return t;
    }
    return _tamanosComerciales.last;
  }

  // Validación de Reserva según RIC N°02 (Mínimo 25% libre)
  double get _porcentajeReservaReal =>
      _gabineteComercial > 0 ? ((_gabineteComercial - _modulosUtiles) / _gabineteComercial) * 100 : 0;

  bool get _cumpleReservaObligatoria => _porcentajeReservaReal >= 25.0;

  void _agregarComponente() {
    setState(() {
      _componentes.add(
        _ComponenteItem(tipo: _TipoComponente.disyuntorCurvaC, cantidad: 1),
      );
    });
  }

  void _eliminarComponente(int index) {
    setState(() {
      _componentes.removeAt(index);
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
            const Icon(Icons.grid_view_rounded, color: _kNavyBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CUBICADOR DE TABLEROS',
                    style: DesignTokens.getDisplay(b, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Módulos DIN + 25% Reserva (RIC N°02)',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarComponente,
        backgroundColor: _kNavyBlue,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'AGREGAR',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
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
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoBox(b),
                    const SizedBox(height: 16),
                    _buildGabineteSelector(b),
                    const SizedBox(height: 20),
                    _buildResultsCard(b),
                    const SizedBox(height: 20),
                    _buildComponentesSection(b),
                    const SizedBox(height: 16),
                  ],
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
        const Icon(Icons.info_outline_rounded, color: _kNavyBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Según RIC N°02 (Sec. 6.1.1.5), todo tablero eléctrico debe mantener al menos un 25% del total de módulos DIN como espacio de reserva activo obligatorio.',
            style: TextStyle(
              fontSize: 11,
              color: DesignTokens.getTextPrimary(b).withAlpha(200),
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );



  String _getNombreComercial(int modulos) {
    final rows = (modulos / 12).ceil();
    return '${_selectedGabinete.label} de $modulos módulos DIN ($rows fila${rows > 1 ? 's' : ''})';
  }

  Widget _buildGabineteSelector(Brightness b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(b),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.getBorderColor(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_rounded, color: _kNavyBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'TIPO DE GABINETE / TABLERO',
                style: TextStyle(
                  color: DesignTokens.getTextPrimary(b),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: DesignTokens.getBackground(b),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DesignTokens.getBorderColor(b)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_TipoGabinete>(
                value: _selectedGabinete,
                isExpanded: true,
                dropdownColor: DesignTokens.getSurface(b),
                style: TextStyle(
                  color: DesignTokens.getTextPrimary(b),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: _TipoGabinete.values.map((g) => DropdownMenuItem(
                  value: g,
                  child: Text(g.label),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _selectedGabinete = v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard(Brightness b) {
    if (_componentes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DesignTokens.getCardBackground(b),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: DesignTokens.getBorderColor(b)),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.dashboard_customize_rounded, color: DesignTokens.getTextSecondary(b).withAlpha(80), size: 48),
              const SizedBox(height: 12),
              Text(
                'Agrega componentes para calcular',
                style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final libreDin = _gabineteComercial - _modulosUtiles;

    return Column(
      children: [
        // Gabinete recomendado – tarjeta principal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _excedeTamanoComercial
                  ? [Colors.red.withAlpha(30), Colors.red.withAlpha(10)]
                  : [_kNavyBlue.withAlpha(30), _kNavyBlue.withAlpha(10)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _excedeTamanoComercial ? Colors.red.withAlpha(80) : _kNavyBlue.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: _excedeTamanoComercial
              ? Column(
                  children: [
                    const Icon(Icons.warning_rounded, color: Colors.red, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'EXCEDE EL MAYOR GABINETE COMERCIAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_modulosNecesarios',
                      style: GoogleFonts.outfit(
                        color: Colors.red,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Módulos DIN requeridos (incluye reserva 25%)',
                      style: TextStyle(
                        color: Colors.red.withAlpha(180),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ningún gabinete comercial (máx. ${_tamanosComerciales.last} DIN) puede alojar esta configuración cumpliendo la reserva obligatoria del 25%. Divide la instalación en 2 o más tableros.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(b),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Text(
                      'GABINETE COMERCIAL MÍNIMO SUGERIDO',
                      style: TextStyle(
                        color: _kNavyBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_gabineteComercial',
                      style: GoogleFonts.outfit(
                        color: _kNavyBlue,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    Text(
                      'Módulos DIN',
                      style: TextStyle(
                        color: _kNavyBlue.withAlpha(180),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getNombreComercial(_gabineteComercial),
                      style: TextStyle(
                        color: DesignTokens.getTextSecondary(b),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 12),

        // Fila de 3 tarjetas de detalle
        Row(
          children: [
            Expanded(child: _miniCard(
              b,
              icon: Icons.electrical_services_rounded,
              color: _kNavyBlue,
              label: 'Módulos\nOcupados',
              value: '$_modulosUtiles',
            )),
            const SizedBox(width: 10),
            Expanded(child: _miniCard(
              b,
              icon: Icons.lock_open_rounded,
              color: _kReserveAmber,
              label: 'Módulos\nLibres',
              value: '+$libreDin',
            )),
            const SizedBox(width: 10),
            Expanded(child: _miniCard(
              b,
              icon: Icons.bar_chart_rounded,
              color: _kSuccessGreen,
              label: 'Reserva\nDisponible',
              value: '${_porcentajeReservaReal.toStringAsFixed(0)}%',
            )),
          ],
        ),

        const SizedBox(height: 12),

        // Barra de ocupación
        _buildOccupancyBar(b),

        const SizedBox(height: 12),

        // Validador de Espacio de Reserva (RIC N°02)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _cumpleReservaObligatoria ? _kSuccessGreen.withAlpha(15) : Colors.red.withAlpha(15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _cumpleReservaObligatoria ? _kSuccessGreen.withAlpha(60) : Colors.red.withAlpha(60),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _cumpleReservaObligatoria ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: _cumpleReservaObligatoria ? _kSuccessGreen : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _cumpleReservaObligatoria 
                          ? 'Validación RIC N°02: CUMPLE' 
                          : 'Validación RIC N°02: NO CUMPLE',
                      style: TextStyle(
                        color: _cumpleReservaObligatoria ? _kSuccessGreen : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _cumpleReservaObligatoria
                          ? 'El tablero cuenta con un ${_porcentajeReservaReal.toStringAsFixed(0)}% de espacio libre para futuras ampliaciones, cumpliendo el mínimo obligatorio del 25%.'
                          : 'El tablero tiene un ${_porcentajeReservaReal.toStringAsFixed(0)}% de espacio de reserva, lo cual es inferior al 25% obligatorio exigido por el RIC N°02 Sec. 6.1.1.5.',
                      style: TextStyle(
                        color: DesignTokens.getTextPrimary(b).withAlpha(180),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniCard(Brightness b, {required IconData icon, required Color color, required String label, required String value}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    decoration: BoxDecoration(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withAlpha(60)),
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: DesignTokens.getTextSecondary(b),
            fontSize: 10,
            height: 1.3,
          ),
        ),
      ],
    ),
  );

  Widget _buildOccupancyBar(Brightness b) {
    final occupiedPct = min(1.0, _modulosUtiles / _gabineteComercial);
    final Color barColor = occupiedPct > 0.75 ? Colors.red : (occupiedPct > 0.60 ? _kReserveAmber : _kSuccessGreen);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DesignTokens.getCardBackground(b),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DesignTokens.getBorderColor(b)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ocupación del tablero',
                style: TextStyle(
                  color: DesignTokens.getTextSecondary(b),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$_modulosUtiles / $_gabineteComercial DIN',
                style: TextStyle(
                  color: barColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: occupiedPct,
              minHeight: 12,
              backgroundColor: DesignTokens.getBackground(b),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0%', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)),
              _verticalMark('75% máx.', _kReserveAmber),
              Text('100%', style: TextStyle(color: DesignTokens.getTextSecondary(b), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verticalMark(String label, Color color) => Row(
    children: [
      Container(width: 1, height: 10, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildComponentesSection(Brightness b) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('LISTA DE COMPONENTES'),
      const SizedBox(height: 12),
      ..._componentes.asMap().entries.map((entry) {
        final idx = entry.key;
        final comp = entry.value;
        return _buildComponenteRow(b, idx, comp);
      }),
    ],
  );

  Widget _buildComponenteRow(Brightness b, int idx, _ComponenteItem comp) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: DesignTokens.getCardBackground(b),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DesignTokens.getBorderColor(b)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _kNavyBlue.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(comp.tipo.icon, color: _kNavyBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton<_TipoComponente>(
                  value: comp.tipo,
                  isExpanded: true,
                  isDense: true,
                  dropdownColor: DesignTokens.getSurface(b),
                  style: TextStyle(
                    color: DesignTokens.getTextPrimary(b),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  items: _TipoComponente.values.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.label, style: TextStyle(
                      color: DesignTokens.getTextPrimary(b),
                      fontSize: 12,
                    )),
                  )).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => comp.tipo = v);
                    }
                  },
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${comp.tipo.modulosDin} módulo${comp.tipo.modulosDin > 1 ? 's' : ''} DIN por unidad  ·  Total: ${comp.totalModulos} DIN',
                style: TextStyle(color: _kNavyBlue, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Selector de cantidad
        _cantidadSelector(b, comp, idx),

        const SizedBox(width: 6),

        // Botón eliminar
        GestureDetector(
          onTap: () => _eliminarComponente(idx),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 16),
          ),
        ),
      ],
    ),
  );

  Widget _cantidadSelector(Brightness b, _ComponenteItem comp, int idx) => Container(
    decoration: BoxDecoration(
      color: DesignTokens.getBackground(b),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: DesignTokens.getBorderColor(b)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (comp.cantidad > 1) setState(() => comp.cantidad--);
          },
          child: Container(
            width: 28,
            height: 32,
            alignment: Alignment.center,
            child: Icon(Icons.remove_rounded, color: _kIndustrialGrey, size: 16),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${comp.cantidad}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: DesignTokens.getTextPrimary(b),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            // Tope razonable: evita degradar la UI con cantidades absurdas
            if (comp.cantidad < 99) setState(() => comp.cantidad++);
          },
          child: Container(
            width: 28,
            height: 32,
            alignment: Alignment.center,
            child: Icon(Icons.add_rounded, color: _kNavyBlue, size: 16),
          ),
        ),
      ],
    ),
  );

  Widget _sectionLabel(String label) => Row(
    children: [
      Container(
        width: 4,
        height: 14,
        decoration: BoxDecoration(
          color: _kNavyBlue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
          color: _kNavyBlue,
        ),
      ),
    ],
  );
}

