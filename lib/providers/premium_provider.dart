import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter/services.dart';
import 'package:nom_electrica_mx/services/ad_service.dart';

/// Gestor de estado global para el estado Premium del usuario.
class PremiumProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _listenerAttached = false;

  /// Retorna true si el usuario tiene suscripción activa.
  bool get isPremium => _isPremium;

  /// Inicializa el provider: verifica si el usuario ya pagó anteriormente
  /// y restaura su estado Premium automáticamente al arrancar la app.
  Future<void> init() async {
    try {
      if (!await Purchases.isConfigured) {
        debugPrint('[PremiumProvider] RevenueCat no está configurado; se omite restauración de estado Premium.');
        AdService.instance.updatePremiumStatus(false);
        return;
      }
      if (!_listenerAttached) {
        // Refleja en tiempo real renovaciones, cancelaciones o problemas de
        // cobro (webhooks de la tienda → RevenueCat) sin esperar al próximo
        // arranque en frío. init() puede llamarse más de una vez (restore),
        // por eso el guard.
        Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);
        _listenerAttached = true;
      }
      final customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.all['premium']?.isActive ?? false;
      debugPrint('[PremiumProvider] Estado Premium restaurado: $_isPremium');
      
      // Sincronizar estado con AdService para activar/desactivar flujos
      AdService.instance.updatePremiumStatus(_isPremium);
      
      notifyListeners();
    } catch (e) {
      debugPrint('[PremiumProvider] Error restaurando estado Premium: $e');
      // En caso de error, aseguramos actualizar AdService (asumimos false)
      AdService.instance.updatePremiumStatus(false);
    }
  }

  /// Callback del listener de RevenueCat: actualiza el estado Premium en
  /// caliente cuando cambia la suscripción (renovación, cancelación, etc.).
  void _onCustomerInfoUpdated(CustomerInfo customerInfo) {
    try {
      final isPro = customerInfo.entitlements.all['premium']?.isActive ?? false;
      if (isPro != _isPremium) {
        _isPremium = isPro;
        AdService.instance.updatePremiumStatus(_isPremium);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[PremiumProvider] Error procesando actualización de suscripción: $e');
    }
  }

  /// Compra el paquete utilizando RevenueCat y retorna un error si falla.
  /// Retorna null si la compra fue exitosa, "cancelado" si el usuario canceló,
  /// o un String descriptivo del error en caso contrario.
  Future<String?> purchasePremium(Package package) async {
    try {
      if (!await Purchases.isConfigured) {
        debugPrint('[PremiumProvider] RevenueCat no está configurado; se omite compra.');
        return "Servicio de suscripciones no disponible por ahora.";
      }
      // ignore: deprecated_member_use — purchasePackage aún funciona en v10.0.1
      await Purchases.purchasePackage(package);
      final customerInfo = await Purchases.getCustomerInfo();
      final isPro = customerInfo.entitlements.all['premium']?.isActive ?? false;
      
      if (isPro) {
        _isPremium = true;
        
        // Sincronizar estado con AdService para liberar recursos de inmediato
        AdService.instance.updatePremiumStatus(true);
        
        notifyListeners();
        return null;
      }
      return "No se pudo activar el plan premium.";
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return "cancelado";
      }
      debugPrint('[RevenueCat] Error de compra: ${e.message}');
      return e.message ?? "Error en la compra";
    } catch (e) {
      debugPrint('[RevenueCat] Error inesperado: $e');
      return "Error inesperado: $e";
    }
  }
}
