import 'recipe_result.dart';

/// A meal slot in the weekly planner. Always has a name; optionally
/// has a full recipe attached (from the AI agent). When a recipe is
/// present, tapping the meal opens the full detail view with image,
/// ingredients, instructions, and source attribution.
class PlannedMeal {
  final String name;
  final RecipeResult? recipe;

  const PlannedMeal({required this.name, this.recipe});

  bool get hasRecipe => recipe != null;

  PlannedMeal copyWith({String? name, RecipeResult? recipe}) {
    return PlannedMeal(
      name: name ?? this.name,
      recipe: recipe ?? this.recipe,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        if (recipe != null) 'recipe': recipe!.toJson(),
      };

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    final recipeData = json['recipe'];
    return PlannedMeal(
      name: json['name'] as String? ?? '',
      recipe: recipeData is Map
          ? RecipeResult.fromJson(recipeData.cast<String, dynamic>())
          : null,
    );
  }

  /// Backward-compatible parse: the old storage format stored plain
  /// strings, the new format stores JSON objects. Handle both so
  /// existing user data keeps working.
  factory PlannedMeal.fromStored(dynamic data) {
    if (data is String) return PlannedMeal(name: data);
    if (data is Map) return PlannedMeal.fromJson(data.cast<String, dynamic>());
    return const PlannedMeal(name: '');
  }
}
