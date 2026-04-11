import 'recipe_result.dart';

/// Flutter-side model matching backend /api/plan-week response.
class WeekPlanResponse {
  final String prompt;
  final Map<String, Map<String, WeekPlanMeal>> plan;
  final int durationMs;

  const WeekPlanResponse({
    required this.prompt,
    required this.plan,
    required this.durationMs,
  });

  factory WeekPlanResponse.fromJson(Map<String, dynamic> json) {
    final rawPlan = (json['plan'] as Map?)?.cast<String, dynamic>() ?? {};
    final plan = <String, Map<String, WeekPlanMeal>>{};
    rawPlan.forEach((day, meals) {
      if (meals is Map) {
        final dayMeals = <String, WeekPlanMeal>{};
        meals.forEach((mealType, data) {
          if (data is Map) {
            dayMeals[mealType.toString()] =
                WeekPlanMeal.fromJson(data.cast<String, dynamic>());
          }
        });
        plan[day.toString()] = dayMeals;
      }
    });
    return WeekPlanResponse(
      prompt: json['prompt'] as String? ?? '',
      plan: plan,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }

  /// Flatten into "Mon_Breakfast" → meal name map for MealPlanService.setAll.
  /// Normalizes day keys to our 3-char format (Mon, Tue, ...).
  Map<String, String> toMealPlanMap() {
    const dayAliases = {
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
      'mon': 'Mon',
      'tue': 'Tue',
      'wed': 'Wed',
      'thu': 'Thu',
      'fri': 'Fri',
      'sat': 'Sat',
      'sun': 'Sun',
    };

    final out = <String, String>{};
    plan.forEach((day, meals) {
      final normalizedDay = dayAliases[day.toLowerCase()] ?? day;
      meals.forEach((mealType, meal) {
        if (meal.name.isNotEmpty) {
          out['${normalizedDay}_$mealType'] = meal.name;
        }
      });
    });
    return out;
  }

  int get mealCount {
    var count = 0;
    for (final day in plan.values) {
      for (final meal in day.values) {
        if (meal.name.isNotEmpty) count++;
      }
    }
    return count;
  }
}

class WeekPlanMeal {
  final String name;
  final RecipeResult? recipe;

  const WeekPlanMeal({required this.name, required this.recipe});

  factory WeekPlanMeal.fromJson(Map<String, dynamic> json) {
    final recipeData = json['recipe'];
    return WeekPlanMeal(
      name: json['name'] as String? ?? '',
      recipe: (recipeData is Map)
          ? RecipeResult.fromJson(recipeData.cast<String, dynamic>())
          : null,
    );
  }
}
