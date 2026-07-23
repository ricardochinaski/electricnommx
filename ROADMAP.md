# Roadmap — NOM Eléctrica MX

App para electricistas de México basada en NOM-001-SEDE y normativa CFE.
Fork del código de Pliegos RIC Chile (commit `be2c1d9`). Ver `../BLUEPRINT.md`
para la documentación completa de la arquitectura heredada y la guía de
adaptación país por país.

> Nombre de trabajo: **NOM Eléctrica MX** (`nom_electrica_mx`). Provisional —
> validar nombre comercial y disponibilidad en las tiendas antes del lanzamiento.

## Fase 0 — Scaffold ✅ (hecho al crear este repo)

- [x] Copia del código chileno excluyendo: PDFs RIC/RPTD, `rag` reutilizado como placeholder, `google-services.json` / `GoogleService-Info.plist` (Firebase chileno) y `.env` real.
- [x] Paquete Dart renombrado: `pliegos_ric_chile` → `nom_electrica_mx` (imports + pubspec).
- [x] Versión reiniciada a `0.1.0+1`.
- [x] `.env` placeholder sin claves + `.env.example`.

## Fase 1 — Infraestructura propia (bloqueante para correr la app)

- [ ] Crear proyecto **Firebase** nuevo (México) → `google-services.json` + `GoogleService-Info.plist` + `firebase_options.dart` (`flutterfire configure`).
- [ ] Elegir **applicationId/bundle id** definitivos (hoy sigue `com.chinaski.pliegosric` — cambiar en `android/app/build.gradle.kts`, paquete Kotlin, y proyecto iOS).
- [ ] Crear app en **RevenueCat** (nueva, entitlement `premium`) y producto de suscripción en MXN.
- [ ] Crear app y bloques en **AdMob México** (banner ×2, interstitial, rewarded ×2) y reemplazar IDs en `ad_service.dart` / `ad_banner_widget.dart` / manifests.
- [ ] Rellenar `.env` con claves nuevas (Gemini + RevenueCat). **Eliminar el fallback chileno embebido** `kRevenueCatIosKeyFallback` en `main.dart`.
- [ ] Keystore Android nuevo + workflows Codemagic apuntando a la app nueva.

## Fase 2 — Contenido normativo NOM (el corazón del trabajo)

- [x] PDF de la **NOM-001-SEDE-2012** (DOF, 780 páginas) en `assets/pdfs/nom001sede2012.pdf`.
- [x] Regenerado `assets/rag/rag_chunks.json` desde la NOM: **2078 chunks** vía `test/extract_chunks_test.dart` (extractor reescrito para catálogo de normas mexicanas, con limpieza del header DOF repetido por página).
- [x] System prompt de Gemini actualizado: NOM-001-SEDE como única fuente, vocabulario mexicano, prohibido citar NEC/RIC/normas derogadas, etiqueta `[VIEW: NOM 001]`.
- [x] Parser del chat acepta `[VIEW: NOM 001]` y abre el PDF de la NOM (tolera etiquetas RIC heredadas en historiales viejos, las oculta).
- [x] `models/ric_data.dart` rehecho: **17 artículos clave NOM** (100, 110, 210, 215-220, 230, 240, 250, 300, 310, 408, 430, 440, 450, 500s, 680, 690, 700s) con deep-link a la página real del PDF (verificadas contra el índice RAG); segunda pestaña = norma completa. Pantallas Inicio/Pliegos actualizadas.
- [x] 10 consejos de seguridad del carrusel de Inicio reescritos citando artículos NOM reales (GFCI 210-8, 25 ohms 250-56, colores 200-6/250-119, etc.).
- [ ] `data/seguridad_data.dart` (dataset extendido de 30 tips) aún es chileno — reescribir.

## Fase 3 — Parámetros eléctricos mexicanos (tabla 7.2 del blueprint)

- [x] Nueva fuente única `data/nom310_ampacidad_data.dart`: **Tabla 310-15(b)(16)** cobre en AWG/kcmil (60/75/90°C, 14 AWG a 500 kcmil con áreas mm²), factores 310-15(b)(2)(a) y 310-15(b)(3)(a). ⚠️ Validar valores contra el DOF antes del release.
- [x] `circuit_sizer.dart` reescrito para NOM: calibres AWG, 127 V (1Φ) / 220 V (3Φ), límite seleccionable 3% derivado / 5% alimentador — 20 tests unitarios verdes con casos calculados a mano.
- [x] Dimensionador de Circuito: UI mexicanizada (botones 127V/220V, derivado/alimentador, aislamientos TW/THW/THHN, conductores portadores, resultado en AWG + mm²).
- [x] Caída de Tensión: 127/220 V y límite 3% de circuito derivado (Art. 210-19).
- [x] Consumo: moneda **MXN** (es_MX, 2 decimales), tarifa por defecto $1.50/kWh con ayuda de tarifas CFE.
- [x] Calculadora de Ampacidad migrada a `nom310_ampacidad_data.dart` (AWG, aislamientos 60/75/90, sin métodos IEC). `ric04_ampacidad_data.dart` eliminado junto con las pantallas legacy `ric_conductores/ric_en_desarrollo`.
- [x] Tabla de Corrientes rediseñada al formato real de la Tabla 310-15(b)(16): filas AWG/kcmil con área mm², columnas 60/75/90°C, corrección en vivo por temperatura, nota sobre terminales a 75°C (Art. 110-14(c)).
- [x] Protecciones: pastillas estándar del Art. 240-6 (15-200A), GFCI típicos, default 127V.
- [x] Motores: default 220V 3Φ, referencias Art. 430 y Tablas 430-248/250.
- [x] Malla de tierra: umbral 25 Ω (Art. 250-56), alerta UVIE en vez de TE1/SEC.
- [x] Ductos: rotulado NOM Capítulo 10 Tabla 1 (los % 53/31/40 coinciden).
- [x] Alumbrado: referencias NOM-007-ENER / NOM-025-STPS.
- [x] Código de colores: neutro blanco/gris (200-6), tierra verde/desnudo (250-119), fases libres (práctica negro/rojo/azul).
- [x] Capacidad de ruptura: reencuadrada al Art. 110-9 (corriente disponible) con práctica comercial mexicana (10/14-25/25-65 kA).
- [x] Consumo: etiqueta CONUEE (kWh/año), aparatos mexicanos (foco, microondas, calentador).
- [x] Barrido de marca: cero menciones "Pliegos RIC Chile" en pantallas y reportes.
- [ ] Selector de tarifas CFE con precios reales (1, 1A-1F, DAC, PDBT…).
- [ ] Motores: reemplazar cálculo por fórmula con las Tablas 430-248/250 oficiales (corriente a plena carga tabulada, como hace CalcEle).
- [ ] Ductos: validar diámetros interiores de conduit comercial mexicano (los actuales son de catálogo chileno).
- [ ] Memoria Pre-TE1 → **formato trámite UVIE / contrato CFE** (pantalla aún chilena).
- [ ] Cubicador de tableros DIN → **cubicador de centros de carga** (QO/atornillable, por espacios/polos — rediseño completo, aún chileno).
- [ ] Etiqueta CONUEE: evaluar quitar clases A+++-G (formato UE) y usar % de ahorro como la etiqueta amarilla real.

## Fase 4 — Marca y textos

- [ ] Nombre comercial definitivo, ícono, colores de marca.
- [ ] Vocabulario mexicano: empalme→acometida, disyuntor→pastilla/termomagnético, ducto→tubería conduit, tablero→centro de carga.
- [ ] Enlaces oficiales: sec.cl → gob.mx/sener, CFE, DOF.
- [ ] Política de privacidad y páginas legales propias (nuevo dominio o ruta).

## Fase 5 — QA y lanzamiento

- [ ] Actualizar suite de tests con datos NOM esperados.
- [ ] Validación de tablas normativas por un electricista mexicano (equivalente al rol que cumple Ricardo con el RIC).
- [ ] Play Console + App Store Connect: apps nuevas, `app-ads.txt`, fichas.

## Reglas heredadas del proyecto chileno (no repetir errores)

1. Ningún valor normativo sin test unitario (`test/`): el bug de la fórmula de Laurent y los datos duplicados de ampacidad se detectaron tarde en Chile.
2. Una sola fuente de verdad para datos normativos (`lib/data/`), nunca copias locales en pantallas.
3. `Purchases.isConfigured` guards y fallbacks de `.env` ya vienen en el código — mantenerlos.
4. Los IDs de AdMob son por plataforma Y por app: no reutilizar los chilenos ni mezclarlos (causó "Serv. anuncios limit." en iOS Chile).
