import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/planned_meal.dart';
import '../models/recipe_result.dart';
import '../services/meal_plan_service.dart';
import '../services/saved_recipes_service.dart';
import '../services/transcribe_service.dart';
import '../widgets/recipe_detail_sheet.dart';
import '../widgets/week_plan_prompt_sheet.dart';
import 'settings_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _fullDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  final List<String> _mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
  final List<IconData> _mealIcons = [
    Icons.wb_sunny_rounded,
    Icons.light_mode_rounded,
    Icons.nights_stay_rounded,
  ];
  final List<Color> _mealColors = [
    const Color(0xFFFFB74D),
    const Color(0xFF4CAF50),
    const Color(0xFF7986CB),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MealPlanService.instance,
      builder: (context, _) {
        final hasAnyMeals = MealPlanService.instance.count > 0;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(context, hasAnyMeals),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildAiPlannerButton(),
                      const SizedBox(height: 20),
                      ..._days.asMap().entries.map((entry) {
                        return _buildDayCard(entry.key, entry.value);
                      }),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool hasAnyMeals) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Meal Plan',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'This week\'s meals',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (hasAnyMeals)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showClearConfirmation,
                    icon: const Icon(
                      Icons.delete_sweep_rounded,
                      color: AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _openSettings(context),
                  icon: const Icon(
                    Icons.settings_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildAiPlannerButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            showWeekPlanPromptSheet(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF388E3C),
                  Color(0xFF43A047),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plan my week with AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '"Mediterranean this week" — done in seconds',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(int index, String day) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _fullDays[index],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            ...List.generate(3, (mealIndex) {
              final mealKey = '${day}_${_mealTypes[mealIndex]}';
              final meal = MealPlanService.instance.get(mealKey);
              final isLast = mealIndex == 2;
              return _buildMealSlot(
                mealKey,
                _mealTypes[mealIndex],
                _mealIcons[mealIndex],
                _mealColors[mealIndex],
                meal,
                isLast,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(
    String mealKey,
    String mealType,
    IconData icon,
    Color color,
    PlannedMeal? meal,
    bool isLast,
  ) {
    final isEmpty = meal == null;
    final hasRecipe = meal?.hasRecipe ?? false;

    return InkWell(
      onTap: () {
        if (isEmpty) {
          _showAddMealSheet(mealKey, mealType);
        } else if (hasRecipe) {
          // Show the full recipe detail sheet — image, ingredients, steps
          showRecipeDetailSheet(context, meal.recipe!);
        } else {
          // Manual meal — show edit/remove options
          _showMealOptions(mealKey, mealType, meal.name);
        }
      },
      onLongPress: () {
        if (!isEmpty) _showMealOptions(mealKey, mealType, meal.name);
      },
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(20))
          : BorderRadius.zero,
      child: Container(
        decoration: BoxDecoration(
          border: !isLast
              ? const Border(
                  bottom: BorderSide(
                    color: AppColors.borderLight,
                    width: 1,
                  ),
                )
              : null,
        ),
        padding: EdgeInsets.fromLTRB(
          hasRecipe ? 14 : 18,
          hasRecipe ? 12 : 14,
          14,
          hasRecipe ? 12 : 14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (hasRecipe)
              _buildRecipeThumbnail(meal!.recipe!.image, color)
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 17, color: color),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealType,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isEmpty)
                    Text(
                      'Tap to add',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else
                    Text(
                      meal.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (hasRecipe) ...[
                    const SizedBox(height: 3),
                    Builder(builder: (_) {
                      final recipe = meal!.recipe!;
                      return Row(
                        children: [
                          if (recipe.rating.value > 0) ...[
                            Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: AppColors.star,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              recipe.rating.value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (recipe.time.display.isNotEmpty) ...[
                            Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              recipe.time.display,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              recipe.source.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isEmpty)
              Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
                color: AppColors.textHint,
              )
            else
              Icon(
                hasRecipe
                    ? Icons.chevron_right_rounded
                    : Icons.more_vert_rounded,
                size: 20,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeThumbnail(String imageUrl, Color tintColor) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: tintColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.restaurant_rounded,
          size: 24,
          color: tintColor,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: tintColor.withValues(alpha: 0.12),
          child: Icon(
            Icons.restaurant_rounded,
            size: 24,
            color: tintColor,
          ),
        ),
      ),
    );
  }

  void _showAddMealSheet(String mealKey, String mealType) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddMealSheet(mealKey: mealKey, mealType: mealType),
    );
  }

  void _showMealOptions(String mealKey, String mealType, String mealName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                mealName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                mealType,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildOptionTile(
                Icons.edit_rounded,
                'Edit meal',
                onTap: () {
                  Navigator.pop(context);
                  _showAddMealSheet(mealKey, mealType);
                },
              ),
              _buildOptionTile(
                Icons.delete_rounded,
                'Remove meal',
                color: AppColors.error,
                onTap: () async {
                  await MealPlanService.instance.removeMeal(mealKey);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    IconData icon,
    String label, {
    VoidCallback? onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.textPrimary;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textHint,
        size: 20,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all meals?'),
        content: const Text('This will remove all planned meals for this week.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              await MealPlanService.instance.clear();
              if (!context.mounted) return;
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding a meal to a planner slot. Three input modes:
/// type, voice (Whisper), or pick from saved recipes.
class _AddMealSheet extends StatefulWidget {
  final String mealKey;
  final String mealType;

  const _AddMealSheet({required this.mealKey, required this.mealType});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  bool _listening = false;
  bool _transcribing = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    if (TranscribeService.instance.isRecording) {
      TranscribeService.instance.cancelRecording();
    }
    super.dispose();
  }

  Future<void> _commit(String name) async {
    if (name.trim().isEmpty) return;
    await MealPlanService.instance.setMeal(widget.mealKey, name.trim());
    if (!mounted) return;
    Navigator.pop(context);
    HapticFeedback.lightImpact();
  }

  Future<void> _toggleVoice() async {
    HapticFeedback.mediumImpact();
    if (_transcribing) return;

    if (_listening) {
      _pulseController.stop();
      setState(() {
        _listening = false;
        _transcribing = true;
      });
      try {
        final text = await TranscribeService.instance.stopAndTranscribe();
        if (!mounted) return;
        setState(() {
          _transcribing = false;
          _controller.text = text;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _transcribing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice failed: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return;
    }

    try {
      final ok = await TranscribeService.instance.startRecording();
      if (!ok) return;
      if (!mounted) return;
      setState(() => _listening = true);
      _pulseController.repeat(reverse: true);
    } catch (_) {}
  }

  void _pickFromSaved() {
    final saved = SavedRecipesService.instance.recipes;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            child: Column(
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pick a saved recipe',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: saved.isEmpty
                      ? Center(
                          child: Text(
                            'No saved recipes yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textHint,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: saved.length,
                          itemBuilder: (context, index) {
                            final recipe = saved[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () async {
                                    final title =
                                        recipe['title']?.toString() ?? '';
                                    if (title.isEmpty) return;
                                    final recipeResult =
                                        _mapToRecipeResult(recipe);
                                    await MealPlanService.instance.setMeal(
                                      widget.mealKey,
                                      title,
                                      recipe: recipeResult,
                                    );
                                    if (!sheetCtx.mounted) return;
                                    Navigator.pop(sheetCtx);
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    HapticFeedback.lightImpact();
                                  },
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: AppColors.borderLight,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        _savedThumb(recipe),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            recipe['title'] ?? 'Untitled',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(
                                          Icons.add_circle_outline_rounded,
                                          color: AppColors.textHint,
                                          size: 22,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Convert a stored saved-recipe map back into a RecipeResult so we can
  /// attach it to a PlannedMeal slot with full ingredients/instructions.
  RecipeResult _mapToRecipeResult(Map<String, dynamic> recipe) {
    return RecipeResult(
      id: recipe['id']?.toString() ?? '',
      title: recipe['title']?.toString() ?? '',
      description: recipe['description']?.toString() ?? '',
      image: recipe['image']?.toString() ?? '',
      source: RecipeSource(
        domain: '',
        name: recipe['source']?.toString() ?? 'My recipe',
        url: recipe['sourceUrl']?.toString() ?? '',
      ),
      rating: RecipeRating(
        value: (recipe['rating'] as num?)?.toDouble() ?? 0.0,
        count: 0,
      ),
      time: RecipeTime(
        prep: null,
        cook: null,
        total: null,
        display: recipe['time']?.toString() ?? '',
      ),
      servings: null,
      ingredients:
          ((recipe['ingredients'] as List?) ?? const []).cast<String>(),
      instructions: ((recipe['steps'] as List?) ?? const []).cast<String>(),
      score: 0,
    );
  }

  Widget _savedThumb(Map<String, dynamic> recipe) {
    final image = (recipe['image'] ?? '').toString();
    if (image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          image,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiThumb(recipe),
        ),
      );
    }
    return _emojiThumb(recipe);
  }

  Widget _emojiThumb(Map<String, dynamic> recipe) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          recipe['emoji'] ?? '\u{1F372}',
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Text(
              'Add ${widget.mealType}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Type, speak, or pick from saved',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),
            // Text + voice row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _listening
                          ? 'Listening...'
                          : _transcribing
                              ? 'Transcribing...'
                              : 'e.g. "Grilled chicken salad"',
                      hintStyle: TextStyle(
                        color: _listening || _transcribing
                            ? AppColors.primary
                            : AppColors.textHint,
                      ),
                      prefixIcon: const Icon(
                        Icons.restaurant_rounded,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onSubmitted: _commit,
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final pulse = _listening ? _pulseController.value : 0.0;
                    final colors = _transcribing
                        ? const [Color(0xFFFFB300), Color(0xFFFFCA28)]
                        : _listening
                            ? const [Color(0xFFE53935), Color(0xFFEF5350)]
                            : const [Color(0xFF2E7D32), Color(0xFF43A047)];
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: colors,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary
                                .withValues(alpha: 0.25 + pulse * 0.3),
                            blurRadius: 10 + pulse * 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _transcribing ? null : _toggleVoice,
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _transcribing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    _listening
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Pick from saved button
            GestureDetector(
              onTap: _pickFromSaved,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pick from saved recipes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'With full ingredients & instructions',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _commit(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add Meal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
