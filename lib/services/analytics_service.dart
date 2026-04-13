import 'package:firebase_analytics/firebase_analytics.dart';

/// Centralized analytics tracking. Wraps Firebase Analytics.
/// Call these methods throughout the app to track user behavior.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Firebase observer for auto screen tracking in MaterialApp
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================================
  // CORE EVENTS
  // ============================================================

  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(name: 'onboarding_complete');
  }

  // ============================================================
  // SEARCH EVENTS
  // ============================================================

  Future<void> logSearch(String query, {bool isVoice = false}) async {
    await _analytics.logSearch(searchTerm: query);
    await _analytics.logEvent(
      name: 'recipe_search',
      parameters: {
        'query': query,
        'input_type': isVoice ? 'voice' : 'text',
      },
    );
  }

  Future<void> logSearchResults(String query, int resultCount, int durationMs) async {
    await _analytics.logEvent(
      name: 'search_results',
      parameters: {
        'query': query,
        'result_count': resultCount,
        'duration_ms': durationMs,
      },
    );
  }

  // ============================================================
  // RECIPE EVENTS
  // ============================================================

  Future<void> logRecipeSave(String title, String source) async {
    await _analytics.logEvent(
      name: 'recipe_save',
      parameters: {'title': title, 'source': source},
    );
  }

  Future<void> logRecipeView(String title) async {
    await _analytics.logEvent(
      name: 'recipe_view',
      parameters: {'title': title},
    );
  }

  Future<void> logRecipeShare(String title) async {
    await _analytics.logShare(
      contentType: 'recipe',
      itemId: title,
      method: 'share_card',
    );
  }

  Future<void> logRecipeCreateManual() async {
    await _analytics.logEvent(name: 'recipe_create_manual');
  }

  Future<void> logRecipeFromUrl(String url, bool success) async {
    await _analytics.logEvent(
      name: 'recipe_from_url',
      parameters: {'success': success.toString()},
    );
  }

  // ============================================================
  // MEAL PLAN EVENTS
  // ============================================================

  Future<void> logMealPlanGenerate(String prompt, int days) async {
    await _analytics.logEvent(
      name: 'meal_plan_generate',
      parameters: {'prompt': prompt, 'days': days},
    );
  }

  Future<void> logMealPlanComplete(int mealCount, int durationMs) async {
    await _analytics.logEvent(
      name: 'meal_plan_complete',
      parameters: {
        'meal_count': mealCount,
        'duration_ms': durationMs,
      },
    );
  }

  Future<void> logMealAdd(String mealType, bool fromSaved) async {
    await _analytics.logEvent(
      name: 'meal_add',
      parameters: {
        'meal_type': mealType,
        'from_saved': fromSaved.toString(),
      },
    );
  }

  // ============================================================
  // COOKBOOK EVENTS
  // ============================================================

  Future<void> logCookbookCreate(String name) async {
    await _analytics.logEvent(
      name: 'cookbook_create',
      parameters: {'name': name},
    );
  }

  // ============================================================
  // GROCERY EVENTS
  // ============================================================

  Future<void> logGroceryAutoGenerate(int itemCount) async {
    await _analytics.logEvent(
      name: 'grocery_auto_generate',
      parameters: {'item_count': itemCount},
    );
  }

  // ============================================================
  // PAYWALL EVENTS
  // ============================================================

  Future<void> logPaywallView(String trigger) async {
    await _analytics.logEvent(
      name: 'paywall_view',
      parameters: {'trigger': trigger},
    );
  }

  Future<void> logPaywallSubscribeAttempt(bool annual) async {
    await _analytics.logEvent(
      name: 'paywall_subscribe_attempt',
      parameters: {'plan': annual ? 'annual' : 'monthly'},
    );
  }

  // ============================================================
  // BROWSER EVENTS
  // ============================================================

  Future<void> logBrowserOpen(String query) async {
    await _analytics.logEvent(
      name: 'browser_open',
      parameters: {'query': query},
    );
  }

  Future<void> logBrowserSave(String url, bool success) async {
    await _analytics.logEvent(
      name: 'browser_save',
      parameters: {
        'success': success.toString(),
      },
    );
  }

  // ============================================================
  // RATING EVENTS
  // ============================================================

  Future<void> logRatingShown() async {
    await _analytics.logEvent(name: 'rating_dialog_shown');
  }

  Future<void> logRatingSubmit(int stars) async {
    await _analytics.logEvent(
      name: 'rating_submit',
      parameters: {'stars': stars},
    );
  }

  // ============================================================
  // VOICE EVENTS
  // ============================================================

  Future<void> logVoiceStart() async {
    await _analytics.logEvent(name: 'voice_start');
  }

  Future<void> logVoiceComplete(String text) async {
    await _analytics.logEvent(
      name: 'voice_complete',
      parameters: {'text_length': text.length},
    );
  }

  // ============================================================
  // SETTINGS EVENTS
  // ============================================================

  Future<void> logProfileSave() async {
    await _analytics.logEvent(name: 'profile_save');
  }

  Future<void> logDataClear() async {
    await _analytics.logEvent(name: 'data_clear');
  }
}
