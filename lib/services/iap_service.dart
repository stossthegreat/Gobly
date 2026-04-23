import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:purchases_flutter/purchases_flutter.dart';

import 'usage_service.dart';

/// Wraps RevenueCat for in-app purchases. Source of truth for Pro entitlement.
///
/// Setup checklist (one-time, in RevenueCat dashboard + App Store Connect):
///   1. RevenueCat → Project Settings → API Keys → copy the iOS public key
///      ("appl_xxx") and Android key ("goog_xxx") into the constants below
///      (or pass via --dart-define at build time).
///   2. App Store Connect → create two auto-renewable subscriptions in the
///      same Subscription Group:
///        - Product ID: gobly_pro_monthly  ($4.99 / month, no intro offer)
///        - Product ID: gobly_pro_annual   ($29.99 / year, 7-day free trial)
///   3. RevenueCat → Products → import both products from App Store Connect.
///   4. RevenueCat → Entitlements → create entitlement `pro` and attach BOTH
///      products to it. (Entitlement id MUST match [entitlementId] below.)
///   5. RevenueCat → Offerings → create / use the "default" offering with
///      $rc_monthly and $rc_annual packages pointing to the products above.
class IapService extends ChangeNotifier {
  IapService._();
  static final IapService instance = IapService._();

  // ---------------------------------------------------------------------------
  // CONFIG — fill these in (or pass via --dart-define at build time).
  // ---------------------------------------------------------------------------
  static const String _appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_KEY',
    defaultValue: 'appl_REPLACE_ME',
  );
  static const String _googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_KEY',
    defaultValue: 'goog_REPLACE_ME',
  );

  /// Entitlement identifier configured in RevenueCat. All Pro features check
  /// for this entitlement on the user's [CustomerInfo].
  static const String entitlementId = 'pro';

  // ---------------------------------------------------------------------------

  bool _ready = false;
  bool _isPro = false;
  Offerings? _offerings;
  String? _lastError;

  bool get ready => _ready;
  bool get isPro => _isPro;
  Offerings? get offerings => _offerings;
  Offering? get currentOffering => _offerings?.current;
  String? get lastError => _lastError;

  /// True if a real RevenueCat key is configured. When false, we skip SDK
  /// initialization entirely so dev builds without keys don't crash.
  bool get isConfigured =>
      !_appleApiKey.contains('REPLACE_ME') ||
      !_googleApiKey.contains('REPLACE_ME');

  Future<void> init() async {
    if (_ready) return;
    if (!isConfigured) {
      debugPrint(
        '⚠️ IapService: no RevenueCat key configured — skipping init. '
        'Set REVENUECAT_APPLE_KEY / REVENUECAT_GOOGLE_KEY via --dart-define.',
      );
      return;
    }
    try {
      await Purchases.setLogLevel(
        kReleaseMode ? LogLevel.warn : LogLevel.debug,
      );
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _appleApiKey
          : _googleApiKey;
      await Purchases.configure(PurchasesConfiguration(apiKey));
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfo);

      // Hydrate entitlement + offerings in parallel; tolerate partial failure.
      await Future.wait([
        _refreshCustomerInfo(),
        refreshOfferings(),
      ]);

      _ready = true;
      notifyListeners();
      debugPrint('✅ IapService initialized (pro=$_isPro)');
    } catch (e) {
      _lastError = e.toString();
      debugPrint('⚠️ IapService.init failed: $e');
    }
  }

  Future<void> _refreshCustomerInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _onCustomerInfo(info);
    } catch (e) {
      debugPrint('⚠️ getCustomerInfo failed: $e');
    }
  }

  Future<void> refreshOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ getOfferings failed: $e');
    }
  }

  void _onCustomerInfo(CustomerInfo info) {
    final pro = info.entitlements.active.containsKey(entitlementId);
    // Mirror into UsageService so existing `usage.isPro` checks light up
    // immediately without refactoring every call site. UsageService may hold
    // a stale value from a prior session (e.g. dev toggle), so always sync.
    if (UsageService.instance.isPro != pro) {
      UsageService.instance.setPro(pro);
    }
    if (pro != _isPro) {
      _isPro = pro;
      notifyListeners();
    }
  }

  Future<PurchaseOutcome> purchase(Package package) async {
    if (!isConfigured) {
      return const PurchaseOutcome.failed(
        'In-app purchases are not configured for this build.',
      );
    }
    try {
      final info = await Purchases.purchasePackage(package);
      _onCustomerInfo(info);
      return _isPro
          ? const PurchaseOutcome.success()
          : const PurchaseOutcome.failed(
              'Purchase completed but Pro is not active. Try Restore.',
            );
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return const PurchaseOutcome.cancelled();
      }
      return PurchaseOutcome.failed(_friendlyError(code, e.message));
    } catch (e) {
      return PurchaseOutcome.failed(e.toString());
    }
  }

  /// Returns true if the user is now Pro after restore.
  Future<bool> restore() async {
    if (!isConfigured) return false;
    try {
      final info = await Purchases.restorePurchases();
      _onCustomerInfo(info);
      return _isPro;
    } catch (e) {
      debugPrint('⚠️ restore failed: $e');
      return false;
    }
  }

  String _friendlyError(PurchasesErrorCode code, String? raw) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'Network error. Check your connection and try again.';
      case PurchasesErrorCode.paymentPendingError:
        return 'Payment is pending approval.';
      case PurchasesErrorCode.productNotAvailableForPurchaseError:
        return 'This subscription is not available right now.';
      case PurchasesErrorCode.storeProblemError:
        return 'The App Store is unavailable. Try again in a minute.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'This subscription is already used by another account.';
      case PurchasesErrorCode.invalidCredentialsError:
      case PurchasesErrorCode.configurationError:
        return 'Subscription setup error. Please contact support.';
      case PurchasesErrorCode.ineligibleError:
        return 'You\'re not eligible for this offer.';
      default:
        return raw?.isNotEmpty == true ? raw! : 'Purchase failed. Try again.';
    }
  }
}

class PurchaseOutcome {
  final bool success;
  final bool cancelled;
  final String? error;

  const PurchaseOutcome.success()
      : success = true,
        cancelled = false,
        error = null;
  const PurchaseOutcome.cancelled()
      : success = false,
        cancelled = true,
        error = null;
  const PurchaseOutcome.failed(String message)
      : success = false,
        cancelled = false,
        error = message;
}
