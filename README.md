# Electric NOM México

Sitio web/prototipo para **Electric NOM México**, una propuesta de herramienta digital orientada a profesionales de instalaciones eléctricas en México y al trabajo con la NOM-001-SEDE.

## Estado

**Incubación / prototipo.**

Este repositorio contiene actualmente la **landing web estática y un demostrador de cálculo**. No contiene el código fuente de una aplicación móvil completa, backend, sistema de autenticación, sincronización, pagos ni asistente IA.

La página presenta esas capacidades como parte de la visión del producto, por lo que deben validarse contra la implementación real antes de considerarlas funcionalidades disponibles.

## Qué existe hoy en el repositorio

- landing responsive de Electric NOM México;
- navegación entre Inicio, Funciones, Calculadoras, Soporte, Privacidad y Términos;
- demostrador web de caída de tensión;
- contenido comercial sobre NOM-001-SEDE;
- política de privacidad y términos incluidos en la propia landing;
- interfaz construida con HTML, Tailwind CSS vía CDN, Lucide Icons y JavaScript vanilla.

## Estructura

```text
/
├── index.html
├── README.md
├── docs/
│   ├── ARCHITECTURE.md
│   └── ROADMAP.md
└── .github/
    └── pull_request_template.md
```

Actualmente `index.html` concentra HTML, configuración visual y JavaScript. Una futura refactorización deberá separar estilos, scripts y contenido cuando el producto avance más allá de la fase de prototipo.

## Ejecutar localmente

No requiere proceso de build. Puede abrirse `index.html` directamente en un navegador o servirse con cualquier servidor HTTP estático.

Ejemplo:

```bash
python3 -m http.server 8080
```

Luego abrir `http://localhost:8080`.

## Dependencias web actuales

La landing carga desde CDN:

- Tailwind CSS;
- Lucide Icons.

Para un despliegue de producción conviene fijar versiones o incorporar un proceso de build que permita dependencias reproducibles y una política de seguridad de contenido más estricta.

## Limitaciones conocidas

- los enlaces de Google Play y App Store apuntan actualmente a páginas genéricas de las tiendas;
- el formulario de soporte muestra una confirmación local, pero no envía información a ningún backend;
- las afirmaciones sobre aplicación móvil, cuenta, sincronización, suscripciones, uso offline e IA no pueden verificarse desde este repositorio;
- las fórmulas, referencias y mensajes normativos del demostrador deben someterse a revisión técnica antes de utilizarse como referencia profesional;
- privacidad y términos deben mantenerse alineados con los flujos de datos realmente implementados.

## Documentación

- [Arquitectura](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)

## Flujo de trabajo

1. Registrar el cambio como Issue cuando implique funcionalidad, arquitectura, normativa o seguridad.
2. Crear una rama (`feature/`, `fix/`, `docs/`, `refactor/`, `security/` o `chore/`).
3. Implementar y validar el cambio.
4. Abrir Pull Request contra `main`.
5. Mantener `main` como estado estable del sitio.

## Aviso

Electric NOM México es una herramienta independiente. La información técnica de la web no sustituye la revisión de la normativa oficial vigente ni la responsabilidad profesional sobre una instalación o proyecto eléctrico.
