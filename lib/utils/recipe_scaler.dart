/// Ingredient-amount scaler shared by save (normalize-to-1) and display (scale-to-household).
///
/// Ingredients are stored as free-text strings like "2 cups flour". The scaler
/// only rewrites the leading numeric portion ("2") and leaves the rest untouched.
/// Strings with no numeric prefix (e.g. "salt to taste") pass through unchanged.
library;

import 'dart:math' as math;

final _leadingNumber =
    RegExp(r'^(\d+(?:\.\d+)?(?:\s*/\s*\d+)?(?:\s+\d+/\d+)?)\s');

double? _parseNumber(String raw) {
  final s = raw.trim();
  final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(s);
  if (mixed != null) {
    return int.parse(mixed.group(1)!) +
        int.parse(mixed.group(2)!) / int.parse(mixed.group(3)!);
  }
  final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(s);
  if (frac != null) {
    return int.parse(frac.group(1)!) / int.parse(frac.group(2)!);
  }
  return double.tryParse(s);
}

String _formatNumber(double n) {
  // Guard against absurd tiny/huge values.
  if (n.isNaN || n.isInfinite) return '0';
  if (n == n.roundToDouble() && n.abs() < 1000) return n.toInt().toString();
  final s = n.toStringAsFixed(2);
  // Strip trailing zeros: "1.50" → "1.5", "2.00" → "2"
  return s
      .replaceAll(RegExp(r'0+$'), '')
      .replaceAll(RegExp(r'\.$'), '');
}

/// Scales a single ingredient string by [factor].
String scaleIngredient(String ingredient, double factor) {
  if (factor == 1.0) return ingredient;
  final match = _leadingNumber.firstMatch(ingredient);
  if (match == null) return ingredient;
  final numStr = match.group(1)!;
  final rest = ingredient.substring(match.end);
  final value = _parseNumber(numStr);
  if (value == null) return ingredient;
  return '${_formatNumber(value * factor)} $rest';
}

/// Scales every ingredient in [ingredients] by [factor].
List<String> scaleIngredients(List<String> ingredients, double factor) {
  return ingredients.map((i) => scaleIngredient(i, factor)).toList();
}

/// Produces a copy of [recipe] normalized to 1 serving.
///
/// - Reads `servings` from the source (defaults to 1 when missing).
/// - Divides every ingredient amount by source servings.
/// - Sets `servings` to 1 on the result so subsequent reads know the base.
/// - Marks `_normalizedToOne: true` so migration skips it next time.
Map<String, dynamic> normalizeRecipeToOneServing(
  Map<String, dynamic> recipe,
) {
  final already = recipe['_normalizedToOne'] == true;
  if (already) return recipe;

  final src = (recipe['servings'] as num?)?.toInt() ?? 1;
  final sourceServings = src <= 0 ? 1 : src;
  final factor = 1.0 / sourceServings;

  final ingredients = (recipe['ingredients'] as List?)?.cast<String>() ?? const [];
  final scaled = scaleIngredients(ingredients, factor);

  return {
    ...recipe,
    'ingredients': scaled,
    'servings': 1,
    '_normalizedToOne': true,
  };
}

/// Returns a shallow copy of [recipe] scaled to [targetServings] people,
/// assuming the recipe is stored at 1-serving base. Safe when [targetServings] <= 0.
Map<String, dynamic> applyServings(
  Map<String, dynamic> recipe,
  int targetServings,
) {
  final target = math.max(1, targetServings);
  final base = (recipe['servings'] as num?)?.toInt() ?? 1;
  final factor = base <= 0 ? target.toDouble() : target / base;
  final ingredients = (recipe['ingredients'] as List?)?.cast<String>() ?? const [];
  return {
    ...recipe,
    'ingredients': scaleIngredients(ingredients, factor),
    'servings': target,
  };
}
