import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/planned_meal.dart';
import '../models/recipe_result.dart';

/// Persists the 7-day meal plan across tabs and app restarts.
/// Keys use format: "Mon_Breakfast", "Tue_Lunch", etc.
/// Values are PlannedMeal objects so we can attach full recipe data
/// when the AI agent returns it.
class MealPlanService extends ChangeNotifier {
  MealPlanService._();
  static final MealPlanService _instance = MealPlanService._();
  static MealPlanService get instance => _instance;

  static const _storageKey = 'recimo_meal_plan_v2';
  // v1 used plain strings — fall back to it if v2 doesn't exist
  static const _legacyStorageKey = 'recimo_meal_plan_v1';

  Map<String, PlannedMeal> _meals = {};
  Map<String, PlannedMeal> get meals => Map.unmodifiable(_meals);

  bool _loaded = false;
  bool get loaded => _loaded;

  int get count => _meals.length;

  PlannedMeal? get(String key) => _meals[key];
  String? getName(String key) => _meals[key]?.name;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Try v2 first
      final v2 = prefs.getString(_storageKey);
      if (v2 != null && v2.isNotEmpty) {
        final map = jsonDecode(v2) as Map<String, dynamic>;
        _meals = map.map((k, v) => MapEntry(k, PlannedMeal.fromStored(v)));
      } else {
        // Migrate v1 (plain strings) if present
        final v1 = prefs.getString(_legacyStorageKey);
        if (v1 != null && v1.isNotEmpty) {
          final map = jsonDecode(v1) as Map<String, dynamic>;
          _meals = map.map(
            (k, v) => MapEntry(k, PlannedMeal(name: v as String)),
          );
          // Save forward to v2 format
          await _save();
        }
      }
    } catch (_) {
      _meals = {};
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMeal(String key, String name, {RecipeResult? recipe}) async {
    _meals[key] = PlannedMeal(name: name, recipe: recipe);
    notifyListeners();
    await _save();
  }

  /// Replace the whole week atomically. Used by the AI week planner
  /// so all 21 meals appear at once instead of 21 separate updates.
  Future<void> setAll(Map<String, PlannedMeal> meals) async {
    _meals = Map<String, PlannedMeal>.from(meals);
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
      final jsonMap = _meals.map((k, v) => MapEntry(k, v.toJson()));
      await prefs.setString(_storageKey, jsonEncode(jsonMap));
    } catch (_) {}
  }
}
