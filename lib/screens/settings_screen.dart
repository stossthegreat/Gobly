import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/app_settings_service.dart';
import '../services/recipe_search_service.dart';
import '../services/meal_plan_service.dart';
import '../services/saved_recipes_service.dart';
import '../services/cookbooks_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late UserProfile _draft;
  final _nameController = TextEditingController();
  final _backendController = TextEditingController();
  String? _backendStatus;
  bool _backendTesting = false;

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
    _backendController.text = AppSettingsService.instance.backendUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _backendController.dispose();
    super.dispose();
  }

  Future<void> _saveBackendUrl() async {
    await AppSettingsService.instance.setBackendUrl(_backendController.text);
    _backendController.text = AppSettingsService.instance.backendUrl;
    if (!mounted) return;
    setState(() => _backendStatus = null);
    HapticFeedback.lightImpact();
  }

  Future<void> _testBackend() async {
    await _saveBackendUrl();
    if (AppSettingsService.instance.backendUrl.isEmpty) {
      setState(() => _backendStatus = 'Enter a URL first');
      return;
    }
    setState(() {
      _backendTesting = true;
      _backendStatus = null;
    });
    try {
      // Use the deep diagnose endpoint which actually tests the keys
      final result = await RecipeSearchService.instance.diagnose();
      final checks = (result['checks'] as Map?)?.cast<String, dynamic>() ?? {};
      final openai = (checks['openai'] as Map?)?.cast<String, dynamic>() ?? {};
      final serper = (checks['serper'] as Map?)?.cast<String, dynamic>() ?? {};
      final openaiOk = openai['ok'] == true;
      final serperOk = serper['ok'] == true;

      if (openaiOk && serperOk) {
        setState(() => _backendStatus = 'Connected. Agent ready.');
      } else {
        final issues = <String>[];
        if (!openaiOk) {
          issues.add('OpenAI: ${openai['error'] ?? 'failed'}');
        }
        if (!serperOk) {
          issues.add('Serper: ${serper['error'] ?? 'failed'}');
        }
        setState(() => _backendStatus = issues.join('\n'));
      }
    } catch (e) {
      setState(() => _backendStatus = e.toString());
    } finally {
      if (mounted) setState(() => _backendTesting = false);
    }
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
                  const SizedBox(height: 28),
                  _buildSettingsSectionLabel('Account'),
                  const SizedBox(height: 10),
                  _buildLinkRow(
                    icon: Icons.policy_rounded,
                    color: AppColors.textSecondary,
                    title: 'Terms of Service',
                    onTap: () => _showStaticDoc(
                      title: 'Terms of Service',
                      body: _termsText,
                    ),
                  ),
                  _buildLinkRow(
                    icon: Icons.privacy_tip_rounded,
                    color: AppColors.textSecondary,
                    title: 'Privacy Policy',
                    onTap: () => _showStaticDoc(
                      title: 'Privacy Policy',
                      body: _privacyText,
                    ),
                  ),
                  _buildLinkRow(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textSecondary,
                    title: 'About Recimo',
                    trailing: 'v0.1.0',
                    onTap: _showAboutSheet,
                  ),
                  const SizedBox(height: 20),
                  _buildSettingsSectionLabel('Danger Zone'),
                  const SizedBox(height: 10),
                  _buildLinkRow(
                    icon: Icons.cleaning_services_rounded,
                    color: const Color(0xFFFFB300),
                    title: 'Clear all data',
                    subtitle: 'Wipes recipes, plans, profile',
                    onTap: _confirmClearAllData,
                  ),
                  _buildLinkRow(
                    icon: Icons.logout_rounded,
                    color: AppColors.textSecondary,
                    title: 'Sign out',
                    subtitle: 'Local-only — no account yet',
                    onTap: _confirmSignOut,
                  ),
                  _buildLinkRow(
                    icon: Icons.delete_forever_rounded,
                    color: AppColors.error,
                    title: 'Delete account',
                    subtitle: 'Permanently remove all data',
                    onTap: _confirmDeleteAccount,
                    isDanger: true,
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

  // Hidden — kept for future developer mode
  // ignore: unused_element
  Widget _buildBackendCard() {
    final isSuccess = _backendStatus?.startsWith('Connected') ?? false;
    final statusColor = _backendStatus == null
        ? null
        : isSuccess
            ? AppColors.primary
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.cloud_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Backend URL',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your Railway URL — required for AI search',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _backendController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: 'https://your-app.up.railway.app',
                hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13),
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.content_paste_rounded, color: AppColors.textHint),
                  onPressed: () async {
                    final data = await Clipboard.getData(Clipboard.kTextPlain);
                    if (data?.text != null) {
                      _backendController.text = data!.text!;
                    }
                  },
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              onChanged: (_) => setState(() => _backendStatus = null),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _backendTesting ? null : _testBackend,
                      icon: _backendTesting
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        _backendTesting ? 'Testing...' : 'Save & Test',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _backendTesting
                        ? null
                        : () async {
                            await AppSettingsService.instance.resetToDefault();
                            _backendController.text =
                                AppSettingsService.instance.backendUrl;
                            setState(() => _backendStatus = null);
                            HapticFeedback.lightImpact();
                          },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_backendStatus != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: (statusColor ?? AppColors.textSecondary).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (statusColor ?? AppColors.textSecondary).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        _backendStatus!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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

  // ==========================================================================
  // Account & legal section helpers
  // ==========================================================================

  Widget _buildSettingsSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 20, 0),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLinkRow({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDanger
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.borderLight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDanger
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  Text(
                    trailing,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStaticDoc({required String title, required String body}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
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
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Recimo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v0.1.0',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'The fastest way to find the right recipe and plan your week.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Built with care.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmClearAllData() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear all data?'),
        content: const Text(
          'This will remove all saved recipes, meal plans, cookbooks, and your profile. The app will return to a fresh state.',
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
              await SavedRecipesService.instance.clear();
              await MealPlanService.instance.clear();
              await CookbooksService.instance.delete('');
              for (final cb in CookbooksService.instance.cookbooks.toList()) {
                await CookbooksService.instance.delete(cb.id);
              }
              await UserProfileService.instance.reset();
              if (!context.mounted) return;
              Navigator.pop(context);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All data cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text(
              'Clear all',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text(
          'Recimo is local-only right now — there is no cloud account to sign out of. Cloud sign-in is coming soon. For now, this just closes the screen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete account?',
          style: TextStyle(color: AppColors.error),
        ),
        content: const Text(
          'This will permanently delete all your data: profile, recipes, meal plans, cookbooks, and settings. You cannot undo this.\n\nTo confirm, you will need to clear data twice.',
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
              Navigator.pop(context);
              _confirmClearAllData();
            },
            child: const Text(
              'Continue',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  static const _termsText =
      'By using Recimo you agree to use the app for personal recipe '
      'discovery and meal planning. Recipes shown via search are sourced '
      'from third-party publishers and remain the intellectual property '
      'of those publishers. Recimo is provided "as is" without warranty.\n\n'
      'You agree not to misuse the service, attempt to disrupt the '
      'backend, or use the app for any unlawful purpose. We may update '
      'these terms at any time and material changes will be communicated '
      'in-app.\n\n'
      'These terms are placeholder until a formal legal review is complete.';

  static const _privacyText =
      'Recimo stores your profile (name, allergies, diet, preferences), '
      'saved recipes, meal plans, cookbooks, and settings locally on '
      'your device. This data does not leave your device unless you '
      'use a feature that requires the backend (search, week plan, '
      'voice transcription).\n\n'
      'When you use those features, the following is sent over HTTPS '
      'to our backend: your query text or audio, and your profile '
      'context (so the agent respects your allergies and diet). The '
      'backend forwards queries to OpenAI and Serper/Brave Search and '
      'returns the results. We do not store query history server-side '
      'beyond a short cache for repeat queries.\n\n'
      'You can clear all local data at any time from Settings → Clear '
      'all data. This is placeholder text until a formal privacy '
      'review is complete.';
}
