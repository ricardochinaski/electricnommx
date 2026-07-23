# Changelog — PLIEGOS RIC CHILE

## [2.0.8+30]

### Pipeline
- Build iOS en Codemagic con `ios_signing` + certificado `.p12` + provisioning profile manual
- `CODE_SIGN_STYLE = Manual` en Release/Profile
- Export forzado con `--export-options-plist`
- `submit_to_testflight: true`

### Firma (Sign In with Apple)
- CSR generado desde Windows con `certreq.exe`
- `.p12` exportado vía .NET `Export-PfxCertificate`
- Certificado Apple Distribution + provisioning profile con Sign In with Apple habilitado

### PaywallScreen
- Botón **Reintentar** cuando falla la carga de ofertas de RevenueCat
- Método `_buildButtonContent()` con lógica clara (sin ternarios anidados)
- Mensaje de error amigable con ícono y sugerencia de conexión
- Debug logging para offerings/packages

### RevenueCat
- Claves separadas `REVENUECAT_API_KEY_IOS` y `REVENUECAT_API_KEY_ANDROID` en `.env`
- Producto `com.aselec.pliegosric.premium_yearly` configurado (pendiente de aprobación en App Store)

### AdMob
- Ad Unit IDs correctos para iOS y Android (banner, interstitial, rewarded, rewarded IA)
- `GADSimulatorID` registrado para pruebas en simulador
- ATT (App Tracking Transparency) solicitado en primer plano
- `SKAdNetworkItems` (44 redes) en Info.plist
- `PrivacyInfo.xcprivacy` con declaraciones AdMob
- Pendiente: `ios/Podfile` no existe → SDK nativo no se instala en Codemagic

### Rechazos Apple resueltos
- Guideline 2.1(a) — error sin retry → corregido
- Bundle version duplicado → bump a 2.0.7+30

### Pendiente
- Crear `ios/Podfile` para SDK nativo de Google Mobile Ads
- Agregar test device IDs reales para iOS
- App Store: enviar `com.aselec.pliegosric.premium_yearly` a revisión junto con la app
- Publicar `app-ads.txt` en dominio web para verificación AdMob
