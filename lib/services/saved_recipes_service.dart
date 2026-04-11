import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-saved recipes across tabs and app restarts.
class SavedRecipesService extends ChangeNotifier {
  SavedRecipesService._();
  static final SavedRecipesService _instance = SavedRecipesService._();
  static SavedRecipesService get instance => _instance;

  static const _storageKey = 'gobly_saved_recipes_v1';

  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> get recipes => List.unmodifiable(_recipes);

  int get count => _recipes.length;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        _recipes = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (_) {
      _recipes = [];
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(Map<String, dynamic> recipe) async {
    _recipes.insert(0, recipe);
    notifyListeners();
    await _save();
  }

  Future<void> insertAt(int index, Map<String, dynamic> recipe) async {
    final i = index.clamp(0, _recipes.length);
    _recipes.insert(i, recipe);
    notifyListeners();
    await _save();
  }

  Future<void> removeAt(int index) async {
    if (index >= 0 && index < _recipes.length) {
      _recipes.removeAt(index);
      notifyListeners();
      await _save();
    }
  }

  Future<void> clear() async {
    _recipes.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_recipes));
    } catch (_) {}
  }
}
