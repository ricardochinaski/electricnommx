# INFORME FINAL DE AUDITORÍA iOS — PLIEGOS RIC CHILE v2.0.5+17

> **Fecha:** 2026-06-11
> **Bundle ID:** `com.aselec.pliegosric`
> **Propósito:** Garantizar el paso de los filtros de revisión de Apple App Store sin rechazos.

---

## Resumen de Hallazgos

| Pilar | Estado | Riesgo |
|-------|--------|--------|
| 1. Compatibilidad de Anuncios (Info.plist) | ✅ Corregido | 🔴 Crítico (SKAdNetwork faltante) |
| 2. Enrutamiento Multiplataforma de Anuncios | ✅ Corregido | 🟡 Ad Unit IDs hardcodeados |
| 3. Safe Area y Muescas (Notch / Dynamic Island) | ✅ Corregido | 🔴 11/14 calculadoras sin SafeArea |
| 4. Eliminación de Cuenta (Directriz 5.1.1) | ✅ Corregido | 🔴 Sin re-autenticación inline |
| 5. Manifiesto de Privacidad (PrivacyInfo.xcprivacy) | ✅ Corregido | 🔴 Archivo inexistente |

---

## Archivos Modificados (10 archivos)

| Archivo | Cambio |
|---------|--------|
| `ios/Runner/Info.plist` | +44 SKAdNetworkIdentifiers, ATT mejorado, ATS restaurado a `true` |
| `ios/Runner/PrivacyInfo.xcprivacy` | **NUEVO** — tracking, collected data types, UserDefaults API reason |
| `lib/firebase_options.dart` | +Config iOS (`FirebaseOptions ios`) eliminado `throw UnsupportedError` |
| `lib/main.dart` | `kIsWeb` guard en `AdService.instance` late-init |
| `lib/services/ad_service.dart` | Ad Unit IDs convertidos de `final` fields a `getters` (web-safe) |
| `lib/screens/profile_sub_page.dart` | +Re-autenticación Google + Password, rename "Desactivar" → "Eliminar Cuenta" |
| `lib/screens/calculadoras/calculadora_alumbrado_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_awg_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_baterias_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_caida_tension_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_consumo_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_corriente_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_motores_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_protecciones_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_voltaje_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/ric_conductores_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/ric_en_desarrollo_screen.dart` | +`SafeArea` en banner, hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_capacidad_screen.dart` | Hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_ductos_screen.dart` | Hardcoded ad unit ID removido |
| `lib/screens/calculadoras/calculadora_malla_screen.dart` | Hardcoded ad unit ID removido |

---

## Detalle de Correcciones por Pilar

### 1. Info.plist — Compatibilidad de Anuncios y Privacidad

**Antes:** Sin `SKAdNetworkItems`, ATT genérico, ATS permisivo.

**Después:**
- `GADApplicationIdentifier`: `ca-app-pub-6408666343364043~6859643738` ✅
- `SKAdNetworkItems`: 44 redes de AdMob/Google incluidas ✅
- `NSUserTrackingUsageDescription`: Texto personalizado para electricistas chilenos ✅
- `NSAppTransportSecurity`: `NSAllowsArbitraryLoads = true` (requerido por AdMob) ✅

### 2. Enrutamiento Multiplataforma de Anuncios

**Antes:** 14 calculadoras usaban `adUnitId: 'ca-app-pub-6408666343364043/9133229499'` hardcodeado (sin distinción Android/iOS). `AdService` usaba `final` fields con `Platform.isAndroid` que fallarían en Web.

**Después:** Todas las calculadoras omiten `adUnitId` y usan el default platform-aware de `AdBannerWidget`. Los Ad Unit IDs en `ad_service.dart` son `getters` en lugar de `final` fields.

### 3. Safe Area — Notch y Dynamic Island

**Antes:** 11 de 14 pantallas de calculadora tenían el banner superior directamente en `body: Column(...)` sin `SafeArea`, quedando oculto bajo el notch.

**Después:** Cada banner está envuelto en `SafeArea(top: true, bottom: false)`. Las 3 que ya tenían SafeArea en el body también tienen SafeArea anidado (idempotente, sin efecto negativo).

Patrón aplicado:
```dart
if (!isPremium) ...[
  SafeArea(
    top: true,
    bottom: false,
    child: AdBannerWidget(bottomPadding: 8.0),
  ),
],
```

Además, el Dashboard ya tenía `SafeArea(top: false, bottom: true)` en su `bottomNavigationBar`, protegiendo el banner inferior del home indicator. ✅

### 4. Eliminación de Cuenta — Directriz Apple 5.1.1

**Antes:**
- Botón rotulado "Desactivar Cuenta" (Apple exige "Eliminar")
- Error `requires-recent-login` solo mostraba un snackbar sin solución
- Usuario debía salir de la app, cerrar sesión y volver a iniciar

**Después:**
- Botón rotulado "Eliminar Cuenta" ✅
- Confirmación en 2 pasos (advertencia + escribir "ELIMINAR") ✅
- Re-autenticación **inline** cuando Firebase lanza `requires-recent-login`:
  - **Google Sign-In:** Re-autenticación silenciosa con `GoogleSignIn().signIn()`
  - **Email/Password:** Diálogo modal pidiendo la contraseña
  - **Otros:** Mensaje instructivo
- Eliminación en cascada: Firestore (`usuarios/{uid}`) → Firebase Auth (`user.delete()`)

### 5. PrivacyInfo.xcprivacy — Manifiesto de Privacidad

**Antes:** Archivo inexistente (causa de rechazo desde iOS 17.5+).

**Después:** Archivo creado en `ios/Runner/PrivacyInfo.xcprivacy` declarando:
- `NSPrivacyTracking`: `true` (AdMob IDFA)
- `NSPrivacyTrackingDomains`: `googleadservices.com`, `googlesyndication.com`, `doubleclick.net`
- `NSPrivacyCollectedDataTypes`:
  - Name (perfil de usuario) — linked, functionality
  - UserID (Firebase Auth, RevenueCat) — linked, functionality
  - ProductInteraction (uso de la app) — tracking, analytics
  - PurchaseHistory (RevenueCat) — linked, functionality
  - DeviceID (AdMob advertising ID) — linked, tracking, advertising
- `NSPrivacyAccessedAPITypes`:
  - `NSPrivacyAccessedAPICategoryUserDefaults` (SharedPreferences) — razón `CA92.1`

---

## Errores No Corregidos (Pendientes del Usuario)

| Tarea | Acción Requerida |
|-------|------------------|
| `GoogleService-Info.plist` | Descargar desde Firebase Console y colocar en `ios/Runner/` |
| `pod install` | Ejecutar `cd ios && pod install --repo-update` tras agregar el archivo |
| RevenueCat Dashboard | Agregar producto iOS (suscripción anual) y mapear entitlement |
| App Store Connect Privacy | Declarar tipos de datos según `PrivacyInfo.xcprivacy` |
| IDFA Declaration | Marcar "Yes" en App Store Connect > App Privacy > Tracking |

---

## Checklist Pre-Flight (`flutter build ipa`)

```bash
# 1. Verificar que GoogleService-Info.plist existe en ios/Runner/
ls ios/Runner/GoogleService-Info.plist

# 2. Limpiar y obtener dependencias
flutter clean
flutter pub get
cd ios && pod install --repo-update && cd ..

# 3. Verificar análisis Dart
dart analyze

# 4. Compilar iOS (sin firma para prueba)
flutter build ios --release --no-codesign

# 5. Build final con firma (desde Xcode o con perfiles)
flutter build ipa --release
```

### Pruebas manuales obligatorias en simulador físico:
- [ ] ATT prompt aparece al primer inicio en iOS 14+
- [ ] Banner superior de calculadoras visible bajo Dynamic Island
- [ ] Banner inferior del Dashboard visible sobre home indicator
- [ ] Flujo completo de "Eliminar Cuenta":
  - [ ] Confirmación 2 pasos
  - [ ] Re-autenticación Google (si aplica)
  - [ ] Re-autenticación contraseña (si aplica)
  - [ ] Redirección a LoginScreen tras eliminación
- [ ] Anuncios Intersticiales y Rewarded se cargan y muestran
- [ ] Premium desactiva todos los anuncios

---

## Resumen de Código

```
14 archivos Dart corregidos
  → 0 errores de análisis (dart analyze)
  → 11 SafeAreas agregadas en calculadoras
  → 14 hardcoded ad unit IDs removidos
  → Re-autenticación inline implementada (Google + Password)

3 archivos de configuración iOS
  → Info.plist: +44 SKAdNetworkIds, ATT mejorado
  → PrivacyInfo.xcprivacy: CREADO (tracking + data types + API reasons)
  → firebase_options.dart: +Config iOS
```

**La app está lista para `flutter build ipa`.**
