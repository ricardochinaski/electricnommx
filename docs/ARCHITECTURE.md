# Arquitectura de Electric NOM México

## 1. Estado actual

El repositorio implementa actualmente una **aplicación web estática de una sola página**. No existe un framework de frontend, backend ni proceso de build versionado.

La arquitectura observable es:

```text
Navegador
  └── index.html
      ├── HTML y contenido
      ├── Tailwind CSS cargado desde CDN
      ├── Lucide Icons cargado desde CDN
      └── JavaScript vanilla
          ├── navegación entre secciones
          ├── menú móvil
          ├── demostrador de caída de tensión
          └── confirmación local del formulario de soporte
```

## 2. Responsabilidades actuales

### `index.html`

Concentra hoy cinco responsabilidades:

1. estructura y contenido de la landing;
2. configuración visual de Tailwind;
3. navegación de la interfaz;
4. lógica del demostrador de cálculo;
5. contenido legal y de soporte.

Esta concentración es aceptable durante la fase de prototipo, pero no debería mantenerse si el sitio aumenta en funcionalidad o comienza a integrarse con servicios reales.

## 3. Funcionalidad verificable desde este repositorio

Se puede verificar directamente:

- renderizado de la landing;
- navegación entre secciones sin recarga;
- menú responsive;
- cálculo demostrativo de caída de tensión;
- presentación de contenido de privacidad y términos;
- simulación de envío del formulario mediante una alerta del navegador.

No se puede verificar desde este repositorio:

- aplicación móvil Android/iOS;
- autenticación;
- almacenamiento local estructurado;
- sincronización en la nube;
- RevenueCat o compras in-app;
- RAG o asistente IA;
- backend de soporte;
- publicación efectiva en Google Play o App Store.

## 4. Riesgos técnicos actuales

### Archivo monolítico

Cambios pequeños en estilos, contenido o lógica requieren modificar el mismo archivo de más de 40 KB. Esto aumenta el riesgo de regresiones y dificulta pruebas y revisión.

### Dependencias por CDN sin versión fijada

La landing consume Tailwind y Lucide desde servicios externos. Para producción conviene fijar versiones y definir una estrategia de dependencias reproducibles.

### Cálculo técnico embebido en UI

La lógica del demostrador usa una tabla de resistencias aproximadas y determina cumplimiento a partir de un umbral. Esa lógica debe separarse de la interfaz y cubrirse con pruebas antes de considerarse una calculadora técnica de producción.

### Contenido legal mezclado con marketing

Privacidad y términos viven dentro de la misma página. Cuando exista una implementación real de cuentas, sincronización, pagos o IA, estos documentos deberán derivarse de los flujos de datos reales y mantenerse versionados de forma explícita.

## 5. Arquitectura objetivo de corto plazo

Sin introducir todavía un framework, el sitio puede evolucionar a:

```text
/
├── index.html
├── assets/
│   ├── css/
│   │   └── styles.css
│   └── js/
│       ├── app.js
│       └── calculators.js
├── docs/
│   ├── ARCHITECTURE.md
│   └── ROADMAP.md
└── .github/
```

Objetivos:

- separar presentación de lógica;
- aislar cálculos técnicos;
- facilitar pruebas;
- permitir CSP y dependencias más controladas;
- mantener despliegue estático simple.

## 6. Arquitectura futura del producto

Si Electric NOM México se convierte en una aplicación completa, conviene separar explícitamente:

```text
Cliente web / móvil
        │
        ├── cálculo local y consulta offline
        │
        └── API autenticada
              ├── cuentas y sincronización
              ├── soporte
              ├── suscripciones/entitlements
              └── IA/RAG
```

Las claves privadas de IA, administración o servicios de terceros no deben distribuirse en clientes web o móviles.

## 7. Decisiones pendientes

Antes de evolucionar el producto deben definirse:

- si este repositorio seguirá siendo solo la web pública o contendrá también una aplicación;
- ubicación del código móvil, si ya existe;
- estrategia de hosting;
- fuente oficial y versión normativa utilizada por cálculos y contenido;
- modelo de backend y autenticación;
- política real de datos y privacidad;
- estrategia de pruebas para cálculos eléctricos.
