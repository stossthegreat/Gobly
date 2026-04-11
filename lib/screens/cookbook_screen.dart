import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/cookbook.dart';
import '../models/recipe_result.dart';
import '../services/cookbooks_service.dart';
import '../services/saved_recipes_service.dart';
import '../widgets/recipe_detail_sheet.dart';

/// Single cookbook detail screen — shows the recipes in this cookbook,
/// with options to add more from saved recipes or remove existing ones.
class CookbookScreen extends StatefulWidget {
  final String cookbookId;

  const CookbookScreen({super.key, required this.cookbookId});

  @override
  State<CookbookScreen> createState() => _CookbookScreenState();
}

class _CookbookScreenState extends State<CookbookScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CookbooksService.instance,
      builder: (context, _) {
        final cookbook = CookbooksService.instance.getById(widget.cookbookId);
        if (cookbook == null) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: const Center(child: Text('Cookbook not found')),
          );
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(cookbook),
              Expanded(child: _buildBody(cookbook)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddRecipeSheet(cookbook),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Add recipe',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Cookbook cookbook) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Row(
            children: [
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                cookbook.emoji,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cookbook.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${cookbook.count} recipes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameSheet(cookbook);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(cookbook);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(Cookbook cookbook) {
    if (cookbook.recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Empty cookbook',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add recipes from your saved list\nto build out this cookbook',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: cookbook.recipes.length,
      itemBuilder: (context, index) {
        final recipe = cookbook.recipes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key('cb_${cookbook.id}_$index'),
            direction: DismissDirection.endToStart,
            onDismissed: (_) async {
              await CookbooksService.instance.removeRecipe(cookbook.id, index);
              if (!context.mounted) return;
              HapticFeedback.lightImpact();
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.delete_rounded, color: AppColors.error),
            ),
            child: _buildRecipeTile(recipe),
          ),
        );
      },
    );
  }

  Widget _buildRecipeTile(Map<String, dynamic> recipe) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openRecipeDetail(recipe),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _buildThumbnail(recipe),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['title'] ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      recipe['source'] ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(Map<String, dynamic> recipe) {
    final image = (recipe['image'] ?? '').toString();
    if (image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _emojiThumb(recipe),
        ),
      );
    }
    return _emojiThumb(recipe);
  }

  Widget _emojiThumb(Map<String, dynamic> recipe) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          recipe['emoji'] ?? '\u{1F372}',
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }

  void _openRecipeDetail(Map<String, dynamic> recipe) {
    // Convert the stored map back into a RecipeResult for the detail sheet
    final result = RecipeResult(
      id: recipe['id'] as String? ?? '',
      title: recipe['title'] as String? ?? '',
      description: recipe['description'] as String? ?? '',
      image: recipe['image'] as String? ?? '',
      source: RecipeSource(
        domain: '',
        name: recipe['source'] as String? ?? '',
        url: recipe['sourceUrl'] as String? ?? '',
      ),
      rating: RecipeRating(
        value: (recipe['rating'] as num?)?.toDouble() ?? 0.0,
        count: 0,
      ),
      time: RecipeTime(
        prep: null,
        cook: null,
        total: null,
        display: recipe['time'] as String? ?? '',
      ),
      servings: null,
      ingredients:
          ((recipe['ingredients'] as List?) ?? const []).cast<String>(),
      instructions: ((recipe['steps'] as List?) ?? const []).cast<String>(),
      score: 0,
    );
    showRecipeDetailSheet(context, result, canSave: false);
  }

  void _showAddRecipeSheet(Cookbook cookbook) {
    final saved = SavedRecipesService.instance.recipes;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add from saved recipes',
                    style: TextStyle(
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
                            final alreadyIn = cookbook.recipes.any(
                              (r) =>
                                  (r['title']?.toString() ?? '') ==
                                  (recipe['title']?.toString() ?? ''),
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: alreadyIn
                                      ? null
                                      : () async {
                                          await CookbooksService.instance
                                              .addRecipe(cookbook.id, recipe);
                                          if (!context.mounted) return;
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
                                        _buildThumbnail(recipe),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            recipe['title'] ?? 'Untitled',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: alreadyIn
                                                  ? AppColors.textHint
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          alreadyIn
                                              ? Icons.check_circle_rounded
                                              : Icons.add_circle_outline_rounded,
                                          color: alreadyIn
                                              ? AppColors.primary
                                              : AppColors.textHint,
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

  void _showRenameSheet(Cookbook cookbook) {
    final controller = TextEditingController(text: cookbook.name);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
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
              const Text(
                'Rename cookbook',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'Cookbook name',
                  hintStyle: TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      await CookbooksService.instance.rename(cookbook.id, name);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Cookbook cookbook) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete cookbook?'),
        content: Text(
          '"${cookbook.name}" and its ${cookbook.count} recipe references will be removed. Your saved recipes are not affected.',
        ),
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
              await CookbooksService.instance.delete(cookbook.id);
              if (!context.mounted) return;
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // close cookbook screen
              HapticFeedback.mediumImpact();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
