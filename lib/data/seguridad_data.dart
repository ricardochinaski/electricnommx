/// Modelo de datos para un consejo de seguridad RIC.
class TipSeguridad {
  final String consejo;
  final String pliego;
  final String articulo;

  const TipSeguridad({
    required this.consejo,
    required this.pliego,
    required this.articulo,
  });
}

/// Lista completa de 30 consejos de seguridad eléctrica basados en los RIC.
const List<TipSeguridad> tipsSeguridad = [
  TipSeguridad(
    consejo:
        'Instala siempre protectores diferenciales. Es obligatorio que todos los circuitos de alumbrado y enchufes cuenten con una protección diferencial de máximo 30 mA.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.9.5.1',
  ),
  TipSeguridad(
    consejo:
        'No satures los diferenciales. No se deben derivar más de 3 circuitos desde una única protección diferencial para evitar disparos intempestivos.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.9.5.3',
  ),
  TipSeguridad(
    consejo:
        'Mantén los espacios de trabajo libres. Los tableros deben tener un espacio libre de 0,90 m a 1,50 m al frente para maniobras seguras.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.8.2.1',
  ),
  TipSeguridad(
    consejo:
        'Usa luces piloto en tableros. Todo tablero debe contar con indicadores visuales de presencia de energía sobre cada fase.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.8.3.2',
  ),
  TipSeguridad(
    consejo:
        'Exige el corte omnipolar. El interruptor general debe cortar todos los conductores activos, incluyendo el neutro en sistemas monofásicos.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.9.1.2',
  ),
  TipSeguridad(
    consejo:
        'Respeta las alturas de montaje. Los dispositivos de comando deben estar instalados a una altura entre 0,45 m y 2,0 m sobre el nivel del piso.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.11.2',
  ),
  TipSeguridad(
    consejo:
        'Prohibido instalar tableros en baños o dormitorios. No se permite la ubicación de tableros en salas de baño, dormitorios ni lugares de difícil acceso.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.8.1.4',
  ),
  TipSeguridad(
    consejo:
        'Señaliza el riesgo eléctrico. Todos los tableros y zonas de peligro deben portar el símbolo normado de riesgo eléctrico según la norma NCh 457.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.8.4.1',
  ),
  TipSeguridad(
    consejo:
        'Usa cables libres de halógenos en lugares públicos. En locales de reunión de personas, es obligatorio el uso de conductores tipo RZ1 (libre de halógenos).',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.4.3.2',
  ),
  TipSeguridad(
    consejo:
        'Evita uniones dentro de los ductos. Todos los conductores deben ser continuos entre cajas. Solo se permiten uniones dentro de cajas de derivación debidamente cubiertas.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.5.1.6',
  ),
  TipSeguridad(
    consejo:
        'Respeta los diámetros de los ductos. No sobrepases el porcentaje de ocupación: 33% para 3 o más cables, y 53% para un solo cable.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.5.2.3',
  ),
  TipSeguridad(
    consejo:
        'Separa la electricidad del gas. Las canalizaciones eléctricas deben estar a una distancia mínima de 0,60 m de tuberías de gas o agua.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.5.1.10',
  ),
  TipSeguridad(
    consejo:
        'Usa terminales adecuados en los cables. Los cables de cualquier sección deben contar con terminales de conexión aprobados para evitar puntos calientes.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.4.6.1',
  ),
  TipSeguridad(
    consejo:
        'Verifica la limpieza de ductos antes de alambrar. Los ductos deben estar secos y libres de residuos de construcción antes de pasar los conductores.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.5.1.4',
  ),
  TipSeguridad(
    consejo:
        'Nunca interrumpas el conductor de tierra. Está terminantemente prohibido colocar fusibles, interruptores u otros dispositivos de desconexión en el conductor de tierra (PE).',
    pliego: 'RIC N° 10',
    articulo: 'Art. 3.2.3',
  ),
  TipSeguridad(
    consejo:
        'Garantiza la continuidad del sistema de tierra. Todas las partes metálicas de la instalación (bandejas, cañerías, gabinetes) deben estar conectadas a la malla de tierra.',
    pliego: 'RIC N° 10',
    articulo: 'Art. 3.3.1',
  ),
  TipSeguridad(
    consejo:
        'Mantén una baja resistencia de tierra. El valor de resistencia de tierra debe ser el mínimo posible para que las protecciones operen rápidamente ante una falla a tierra.',
    pliego: 'RIC N° 10',
    articulo: 'Art. 3.4.2',
  ),
  TipSeguridad(
    consejo:
        'Usa conductores de protección aislados en recintos especiales. En instalaciones de vehículos eléctricos o recintos médicos, el conductor de tierra debe ser de cobre aislado.',
    pliego: 'RIC N° 10',
    articulo: 'Art. 3.2.5',
  ),
  TipSeguridad(
    consejo:
        'Aplica las 5 Reglas de Oro antes de trabajar. Cortar, Bloquear, Verificar ausencia de tensión, Poner a tierra y en cortocircuito, y Delimitar y señalizar la zona.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.9.5.12',
  ),
  TipSeguridad(
    consejo:
        'Bloqueo y Etiquetado (LOTO). Los medios de desconexión deben bloquearse mecánicamente y etiquetarse mientras se realizan trabajos de mantenimiento.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.9.5.14',
  ),
  TipSeguridad(
    consejo:
        'Realiza pruebas de aislamiento periódicas. Mide la resistencia de aislamiento de los conductores para detectar fallas invisibles y prever cortocircuitos.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.10.2',
  ),
  TipSeguridad(
    consejo:
        'Solo personal calificado puede intervenir instalaciones. Solo trabajadores con la certificación correspondiente otorgada por la SEC están habilitados para realizar montaje y mantenimiento.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.3.1',
  ),
  TipSeguridad(
    consejo:
        'Mantén los planos actualizados. Es obligatorio contar con diagramas unilineales, cuadros de carga y planos de planta vigentes como parte del proyecto eléctrico.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.2.4',
  ),
  TipSeguridad(
    consejo:
        'Asegura la iluminación de emergencia. Los equipos autónomos de emergencia deben garantizar una autonomía mínima de 60 minutos (recomendado 120 min en hospitales).',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.14.1',
  ),
  TipSeguridad(
    consejo:
        'Enchufes de seguridad en áreas con niños. En guarderías, colegios y áreas pediátricas, los tomacorrientes deben tener alvéolos con tapas de protección.',
    pliego: 'RIC N° 16',
    articulo: 'Art. 3.5.4',
  ),
  TipSeguridad(
    consejo:
        'Prohibidas las extensiones en áreas críticas. En salas de cirugía, UCI y similares, no se permite bajo ninguna circunstancia el uso de extensiones o alargadores eléctricos.',
    pliego: 'RIC N° 16',
    articulo: 'Art. 3.8.2',
  ),
  TipSeguridad(
    consejo:
        'Protección en zonas húmedas (Baños). Respeta los volúmenes de seguridad: en el Volumen 0 (dentro de la ducha) solo se admite tensión máx. de 12V con protección IPX7.',
    pliego: 'RIC N° 04',
    articulo: 'Art. 3.15.2',
  ),
  TipSeguridad(
    consejo:
        'Cercos eléctricos seguros. Deben ser instalados con energizadores certificados y portar letreros de advertencia normalizados cada 10 metros como mínimo.',
    pliego: 'RIC N° 13',
    articulo: 'Art. 3.4.2',
  ),
  TipSeguridad(
    consejo:
        'Electromovilidad y cargadores. Las estaciones de carga para vehículos eléctricos deben ser resistentes al vandalismo (IK08) y contar con protecciones de corriente continua (DC).',
    pliego: 'RIC N° 19',
    articulo: 'Art. 3.6.1',
  ),
  TipSeguridad(
    consejo:
        'Corte de emergencia en máquinas. Todo equipo o sistema con riesgos mecánicos asociados debe contar con una parada de emergencia visible, accesible y señalizada.',
    pliego: 'RIC N° 11',
    articulo: 'Art. 3.7.4',
  ),
];

