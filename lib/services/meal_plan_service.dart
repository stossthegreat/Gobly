import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the 7-day meal plan across tabs and app restarts.
/// Keys use format: "Mon_Breakfast", "Tue_Lunch", etc.
class MealPlanService extends ChangeNotifier {
  MealPlanService._();
  static final MealPlanService _instance = MealPlanService._();
  static MealPlanService get instance => _instance;

  static const _storageKey = 'recimo_meal_plan_v1';

  Map<String, String> _meals = {};
  Map<String, String> get meals => Map.unmodifiable(_meals);

  bool _loaded = false;
  bool get loaded => _loaded;

  int get count => _meals.length;

  String? get(String key) => _meals[key];

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        _meals = map.map((k, v) => MapEntry(k, v as String));
      }
    } catch (_) {
      _meals = {};
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMeal(String key, String name) async {
    _meals[key] = name;
    notifyListeners();
    await _save();
  }

  /// Replace the whole week atomically. Used by the AI week planner
  /// so all 21 meals appear at once instead of 21 separate updates.
  Future<void> setAll(Map<String, String> meals) async {
    _meals = Map<String, String>.from(meals);
    notifyListeners();
    await _save();
  }

  Future<void> removeMeal(String key) async {
    _meals.remove(key);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _meals.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_meals));
    } catch (_) {}
  }
}
