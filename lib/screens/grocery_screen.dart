import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GroceryScreen extends StatefulWidget {
  const GroceryScreen({super.key});

  @override
  State<GroceryScreen> createState() => _GroceryScreenState();
}

class _GroceryScreenState extends State<GroceryScreen> {
  // Mock grocery categories
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Produce',
      'icon': Icons.eco_rounded,
      'color': const Color(0xFF4CAF50),
      'items': <Map<String, dynamic>>[],
    },
    {
      'name': 'Protein',
      'icon': Icons.set_meal_rounded,
      'color': const Color(0xFFE57373),
      'items': <Map<String, dynamic>>[],
    },
    {
      'name': 'Dairy',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF64B5F6),
      'items': <Map<String, dynamic>>[],
    },
    {
      'name': 'Pantry',
      'icon': Icons.kitchen_rounded,
      'color': const Color(0xFFFFB74D),
      'items': <Map<String, dynamic>>[],
    },
    {
      'name': 'Other',
      'icon': Icons.shopping_basket_rounded,
      'color': const Color(0xFF9575CD),
      'items': <Map<String, dynamic>>[],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: GlassDecoration.header(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Groceries',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Your shopping list',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.settings_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final hasItems = _categories.any(
      (c) => (c['items'] as List).isNotEmpty,
    );

    if (!hasItems) {
      return _buildEmptyState();
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final items = category['items'] as List<Map<String, dynamic>>;
        if (items.isEmpty) return const SizedBox.shrink();
        return _buildCategorySection(category);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.shopping_cart_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No groceries yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Plan your meals and your grocery\nlist will auto-generate here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Generate from plan button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Generate from meal plan
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Generate from meal plan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Add manually
            TextButton(
              onPressed: () {
                // TODO: Add item manually
              },
              child: Text(
                'or add items manually',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final items = category['items'] as List<Map<String, dynamic>>;
    final color = category['color'] as Color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderLight, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Category header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    category['name'] as String,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),
            // Items
            ...items.map((item) => _buildGroceryItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildGroceryItem(Map<String, dynamic> item) {
    final checked = item['checked'] as bool? ?? false;
    return InkWell(
      onTap: () {
        setState(() {
          item['checked'] = !checked;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: checked ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: checked ? AppColors.primary : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item['name'] as String,
                style: TextStyle(
                  fontSize: 14,
                  color: checked ? AppColors.textHint : AppColors.textPrimary,
                  decoration: checked ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            if (item['quantity'] != null)
              Text(
                item['quantity'] as String,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
