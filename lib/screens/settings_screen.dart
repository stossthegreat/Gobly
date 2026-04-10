import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _draft;
  final _nameController = TextEditingController();

  // Common options for chip selectors
  static const _commonAllergies = [
    'Gluten', 'Dairy', 'Nuts', 'Peanuts', 'Shellfish',
    'Eggs', 'Soy', 'Fish', 'Sesame',
  ];

  static const _dietOptions = [
    {'value': 'none', 'label': 'No restriction', 'icon': Icons.restaurant_rounded},
    {'value': 'vegetarian', 'label': 'Vegetarian', 'icon': Icons.eco_rounded},
    {'value': 'vegan', 'label': 'Vegan', 'icon': Icons.grass_rounded},
    {'value': 'pescatarian', 'label': 'Pescatarian', 'icon': Icons.set_meal_rounded},
    {'value': 'keto', 'label': 'Keto', 'icon': Icons.local_fire_department_rounded},
    {'value': 'paleo', 'label': 'Paleo', 'icon': Icons.hiking_rounded},
    {'value': 'gluten-free', 'label': 'Gluten-free', 'icon': Icons.no_food_rounded},
  ];

  static const _cuisines = [
    'Italian', 'Mexican', 'Japanese', 'Chinese', 'Thai',
    'Indian', 'Mediterranean', 'French', 'American', 'Korean',
    'Middle Eastern', 'Greek', 'Spanish', 'Vietnamese', 'Caribbean',
  ];

  static const _cookingSkills = [
    {'value': 'beginner', 'label': 'Beginner'},
    {'value': 'intermediate', 'label': 'Intermediate'},
    {'value': 'advanced', 'label': 'Advanced'},
  ];

  static const _timePrefs = [
    {'value': 'quick', 'label': 'Quick (<30 min)'},
    {'value': 'balanced', 'label': 'Balanced (30-60 min)'},
    {'value': 'any', 'label': 'Any length'},
  ];

  static const _budgetPrefs = [
    {'value': 'budget', 'label': 'Budget'},
    {'value': 'balanced', 'label': 'Balanced'},
    {'value': 'premium', 'label': 'Premium'},
  ];

  @override
  void initState() {
    super.initState();
    _draft = UserProfileService.instance.profile;
    _nameController.text = _draft.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await UserProfileService.instance.update(
      _draft.copyWith(name: _nameController.text.trim()),
    );
    if (!mounted) return;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Profile saved'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildIntroCard(),
                  const SizedBox(height: 24),
                  _buildSection(
                    'Your Name',
                    Icons.person_rounded,
                    _buildNameField(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Allergies',
                    Icons.warning_rounded,
                    _buildChipGrid(
                      options: _commonAllergies,
                      selected: _draft.allergies,
                      onToggle: (item) {
                        setState(() {
                          final list = List<String>.from(_draft.allergies);
                          if (list.contains(item)) {
                            list.remove(item);
                          } else {
                            list.add(item);
                          }
                          _draft = _draft.copyWith(allergies: list);
                        });
                        HapticFeedback.selectionClick();
                      },
                      color: AppColors.error,
                    ),
                    subtitle: 'We will never suggest recipes with these',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Dislikes',
                    Icons.thumb_down_rounded,
                    _buildDislikesInput(),
                    subtitle: 'Foods you\'d rather not eat',
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Diet',
                    Icons.restaurant_menu_rounded,
                    _buildDietSelector(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Favorite Cuisines',
                    Icons.public_rounded,
                    _buildChipGrid(
                      options: _cuisines,
                      selected: _draft.favoriteCuisines,
                      onToggle: (item) {
                        setState(() {
                          final list = List<String>.from(_draft.favoriteCuisines);
                          if (list.contains(item)) {
                            list.remove(item);
                          } else {
                            list.add(item);
                          }
                          _draft = _draft.copyWith(favoriteCuisines: list);
                        });
                        HapticFeedback.selectionClick();
                      },
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Household Size',
                    Icons.group_rounded,
                    _buildHouseholdSize(),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Cooking Skill',
                    Icons.local_dining_rounded,
                    _buildSegmentedSelector(
                      options: _cookingSkills,
                      selected: _draft.cookingSkill,
                      onSelect: (v) {
                        setState(() => _draft = _draft.copyWith(cookingSkill: v));
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Time Preference',
                    Icons.access_time_rounded,
                    _buildSegmentedSelector(
                      options: _timePrefs,
                      selected: _draft.timePreference,
                      onSelect: (v) {
                        setState(() => _draft = _draft.copyWith(timePreference: v));
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    'Budget',
                    Icons.payments_rounded,
                    _buildSegmentedSelector(
                      options: _budgetPrefs,
                      selected: _draft.budgetPreference,
                      onSelect: (v) {
                        setState(() => _draft = _draft.copyWith(budgetPreference: v));
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primarySoft,
              AppColors.primarySoft.withValues(alpha: 0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primaryMuted.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
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
                    'Teach me about you',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'The more I know, the better I cook for you.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget child, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        hintText: 'What should I call you?',
        hintStyle: TextStyle(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildChipGrid({
    required List<String> options,
    required List<String> selected,
    required Function(String) onToggle,
    Color? color,
  }) {
    final c = color ?? AppColors.primary;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () => onToggle(option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? c.withValues(alpha: 0.12) : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? c.withValues(alpha: 0.5) : AppColors.borderLight,
                width: isSelected ? 1.3 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_rounded, size: 14, color: c),
                  const SizedBox(width: 4),
                ],
                Text(
                  option,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? c : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDislikesInput() {
    final controller = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Type and press enter (e.g. "cilantro")',
            hintStyle: TextStyle(color: AppColors.textHint),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: () {
                final text = controller.text.trim();
                if (text.isNotEmpty && !_draft.dislikes.contains(text)) {
                  setState(() {
                    _draft = _draft.copyWith(
                      dislikes: [..._draft.dislikes, text],
                    );
                  });
                  controller.clear();
                  HapticFeedback.lightImpact();
                }
              },
            ),
          ),
          onSubmitted: (text) {
            final trimmed = text.trim();
            if (trimmed.isNotEmpty && !_draft.dislikes.contains(trimmed)) {
              setState(() {
                _draft = _draft.copyWith(
                  dislikes: [..._draft.dislikes, trimmed],
                );
              });
              controller.clear();
              HapticFeedback.lightImpact();
            }
          },
        ),
        if (_draft.dislikes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _draft.dislikes.map((item) {
              return Container(
                padding: const EdgeInsets.only(left: 12, right: 6, top: 7, bottom: 7),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _draft = _draft.copyWith(
                            dislikes: _draft.dislikes.where((d) => d != item).toList(),
                          );
                        });
                        HapticFeedback.lightImpact();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildDietSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dietOptions.map((opt) {
        final value = opt['value'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _draft.dietaryPreference == value;
        return GestureDetector(
          onTap: () {
            setState(() => _draft = _draft.copyWith(dietaryPreference: value));
            HapticFeedback.selectionClick();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.borderLight,
                width: isSelected ? 1.3 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHouseholdSize() {
    return Row(
      children: [
        _buildCountButton(
          Icons.remove_rounded,
          () {
            if (_draft.householdSize > 1) {
              setState(() =>
                  _draft = _draft.copyWith(householdSize: _draft.householdSize - 1));
              HapticFeedback.lightImpact();
            }
          },
        ),
        Expanded(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                '${_draft.householdSize}',
                key: ValueKey(_draft.householdSize),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
        _buildCountButton(
          Icons.add_rounded,
          () {
            if (_draft.householdSize < 12) {
              setState(() =>
                  _draft = _draft.copyWith(householdSize: _draft.householdSize + 1));
              HapticFeedback.lightImpact();
            }
          },
        ),
      ],
    );
  }

  Widget _buildCountButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
      ),
    );
  }

  Widget _buildSegmentedSelector({
    required List<Map<String, String>> options,
    required String selected,
    required Function(String) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((opt) {
          final value = opt['value']!;
          final label = opt['label']!;
          final isSelected = selected == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
