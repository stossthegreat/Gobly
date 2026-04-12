import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/recipe_result.dart';
import '../services/saved_recipes_service.dart';
import '../services/share_service.dart';
import '../services/usage_service.dart';
import '../screens/paywall_screen.dart';

/// Shows a full-screen recipe detail bottom sheet with hero image,
/// ingredients, numbered instructions, and Save / Close actions.
/// Reused across search results, planner, and week plan screens.
void showRecipeDetailSheet(
  BuildContext context,
  RecipeResult recipe, {
  bool canSave = true,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RecipeDetailSheet(recipe: recipe, canSave: canSave),
  );
}

class _RecipeDetailSheet extends StatefulWidget {
  final RecipeResult recipe;
  final bool canSave;

  const _RecipeDetailSheet({required this.recipe, required this.canSave});

  @override
  State<_RecipeDetailSheet> createState() => _RecipeDetailSheetState();
}

class _RecipeDetailSheetState extends State<_RecipeDetailSheet> {
  late int _servings;
  late int _originalServings;

  RecipeResult get recipe => widget.recipe;
  bool get canSave => widget.canSave;

  @override
  void initState() {
    super.initState();
    _originalServings = recipe.servings ?? 4;
    _servings = _originalServings;
  }

  double get _scaleFactor =>
      _originalServings > 0 ? _servings / _originalServings : 1.0;

  /// Scale an ingredient string by adjusting leading numbers.
  /// "2 cups flour" at 2x → "4 cups flour"
  /// "1/2 tsp salt" at 2x → "1 tsp salt"
  String _scaleIngredient(String ingredient) {
    if (_scaleFactor == 1.0) return ingredient;
    // Match leading number patterns: "2", "1.5", "1/2", "1 1/2"
    final match = RegExp(r'^(\d+(?:\.\d+)?(?:\s*/\s*\d+)?(?:\s+\d+/\d+)?)\s')
        .firstMatch(ingredient);
    if (match == null) return ingredient;
    final numStr = match.group(1)!;
    final rest = ingredient.substring(match.end);
    final value = _parseNumber(numStr);
    if (value == null) return ingredient;
    final scaled = value * _scaleFactor;
    return '${_formatNumber(scaled)} $rest';
  }

  double? _parseNumber(String s) {
    final cleaned = s.trim();
    // "1 1/2" pattern
    final mixed = RegExp(r'^(\d+)\s+(\d+)/(\d+)$').firstMatch(cleaned);
    if (mixed != null) {
      return int.parse(mixed.group(1)!) +
          int.parse(mixed.group(2)!) / int.parse(mixed.group(3)!);
    }
    // "1/2" fraction
    final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(cleaned);
    if (frac != null) {
      return int.parse(frac.group(1)!) / int.parse(frac.group(2)!);
    }
    return double.tryParse(cleaned);
  }

  String _formatNumber(double n) {
    if (n == n.roundToDouble() && n < 1000) return n.toInt().toString();
    // Show one decimal place, drop trailing zero
    final s = n.toStringAsFixed(1);
    return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.55,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Hero image
                  if (recipe.image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Image.network(
                          recipe.image,
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.primarySoft,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(AppColors.primary),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primarySoft,
                            child: const Center(
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: AppColors.primary,
                          size: 48,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Source + stats row
                  Row(
                    children: [
                      if (recipe.rating.value > 0) ...[
                        _chip(
                          Icons.star_rounded,
                          '${recipe.rating.value.toStringAsFixed(1)}${recipe.rating.count > 0 ? ' · ${_fmt(recipe.rating.count)}' : ''}',
                          AppColors.star,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (recipe.time.display.isNotEmpty) ...[
                        _chip(
                          Icons.access_time_rounded,
                          recipe.time.display,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (recipe.servings != null)
                        _chip(
                          Icons.person_rounded,
                          '${recipe.servings}',
                          AppColors.textSecondary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.public_rounded,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          recipe.source.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (recipe.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      recipe.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Ingredients with scaler
                  Row(
                    children: [
                      const _SectionTitle('Ingredients'),
                      const Spacer(),
                      _buildServingsScaler(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: recipe.ingredients.isEmpty
                          ? [
                              Text(
                                'No ingredients available',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textHint,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ]
                          : recipe.ingredients.asMap().entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: entry.key < recipe.ingredients.length - 1
                                      ? 10
                                      : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 7),
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _scaleIngredient(entry.value),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Instructions
                  const _SectionTitle('Instructions'),
                  const SizedBox(height: 12),
                  if (recipe.instructions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'No instructions available',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...recipe.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  // Action buttons — Share always, Save when applicable
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      // Share button — always visible
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              HapticFeedback.lightImpact();
                              await ShareService.shareRecipe(context, recipe);
                            },
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text(
                              'Share',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.4),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (canSave) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await SavedRecipesService.instance.add({
                                  'title': recipe.title,
                                  'source': recipe.source.name,
                                  'sourceUrl': recipe.source.url,
                                  'time': recipe.time.display,
                                  'emoji': '\u{1F372}',
                                  'image': recipe.image,
                                  'rating': recipe.rating.value,
                                  'ingredients': recipe.ingredients,
                                  'steps': recipe.instructions,
                                  'category': 'Saved',
                                });
                                if (!context.mounted) return;
                                HapticFeedback.lightImpact();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${recipe.title} saved!'),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.bookmark_add_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingsScaler() {
    final isPro = UsageService.instance.isPro;
    return GestureDetector(
      onTap: isPro
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PaywallScreen(
                    triggerText: 'Ingredient scaling is a Pro feature',
                  ),
                ),
              );
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isPro
              ? AppColors.primarySoft
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPro
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPro) ...[
              Icon(
                Icons.lock_rounded,
                size: 12,
                color: AppColors.textHint,
              ),
              const SizedBox(width: 4),
            ],
            _buildScalerButton(
              Icons.remove_rounded,
              isPro && _servings > 1
                  ? () => setState(() => _servings--)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$_servings',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isPro ? AppColors.primary : AppColors.textHint,
                ),
              ),
            ),
            _buildScalerButton(
              Icons.add_rounded,
              isPro && _servings < 20
                  ? () => setState(() => _servings++)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScalerButton(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          onTap();
          HapticFeedback.selectionClick();
        }
      },
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap != null
              ? AppColors.primarySoft
              : AppColors.borderLight,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null ? AppColors.primary : AppColors.textHint,
        ),
      ),
    );
  }

  String _fmt(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    );
  }
}
