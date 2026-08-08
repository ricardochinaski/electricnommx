# Roadmap — Electric NOM México

## Objetivo

Evolucionar el repositorio desde una landing monolítica de demostración hacia una base web verificable, mantenible y coherente con el producto real.

## Fase 0 — Saneamiento del repositorio

Estado: **en curso**.

- [x] identificar el alcance real del repositorio;
- [x] usar `index.html` como entrada web convencional;
- [x] documentar arquitectura actual;
- [x] documentar limitaciones y capacidades verificables;
- [x] establecer flujo Issue → rama → PR → `main`;
- [ ] añadir validación automática mínima para la web estática.

## Fase 1 — Separación de responsabilidades

- [ ] mover JavaScript de navegación a `assets/js/app.js`;
- [ ] mover lógica de cálculo a `assets/js/calculators.js`;
- [ ] extraer estilos/configuración cuando se defina la estrategia de Tailwind;
- [ ] fijar versiones de dependencias externas;
- [ ] mantener `index.html` enfocado en estructura y contenido;
- [ ] añadir pruebas unitarias a las funciones de cálculo.

## Fase 2 — Exactitud técnica y normativa

- [ ] definir qué edición/publicación oficial de NOM-001-SEDE es la fuente de verdad;
- [ ] auditar todas las referencias de artículos y tablas mostradas en la landing;
- [ ] validar fórmulas, resistencias, factores y umbrales del demostrador;
- [ ] distinguir claramente entre requisitos normativos, recomendaciones y valores de referencia;
- [ ] documentar fuentes y fecha de revisión de cada calculadora;
- [ ] impedir que una calculadora no validada se presente como resultado definitivo de cumplimiento.

## Fase 3 — Coherencia comercial

- [ ] sustituir enlaces genéricos de Google Play/App Store por destinos reales cuando existan;
- [ ] definir dominio y correos operativos reales;
- [ ] implementar un canal de soporte real o retirar el formulario simulado;
- [ ] revisar afirmaciones como “90% Offline”, “RAG”, “UVIE Ready”, sincronización y suscripciones contra la aplicación implementada;
- [ ] mantener solo claims verificables en producción.

## Fase 4 — Privacidad y seguridad

- [ ] inventariar datos reales procesados por web y app;
- [ ] alinear Política de Privacidad con autenticación, analítica, pagos, IA y almacenamiento que realmente existan;
- [ ] documentar eliminación de cuenta y retención de datos;
- [ ] evitar secretos o API keys en código cliente;
- [ ] definir CSP y estrategia de dependencias externas para producción.

## Fase 5 — Integración con producto

Cuando exista código de la aplicación móvil:

- [ ] decidir si permanece en un repositorio separado o se adopta monorepo;
- [ ] documentar contratos entre web, app y backend;
- [ ] conectar enlaces de descarga y soporte con servicios reales;
- [ ] establecer CI/CD por plataforma;
- [ ] introducir releases y versionado semántico.

## Criterio para salir de incubación

Electric NOM México podrá pasar de **Incubación** a **Desarrollo activo** cuando:

1. exista una definición clara del producto implementado;
2. las funcionalidades anunciadas correspondan con código verificable;
3. las calculadoras principales tengan pruebas y fuentes documentadas;
4. privacidad/términos reflejen el procesamiento real de datos;
5. exista una estrategia estable de despliegue y soporte.
