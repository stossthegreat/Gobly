import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/recipe_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late AnimationController _pulseController;

  // Mock trending data - will be replaced with real API data
  final List<Map<String, dynamic>> _trendingRecipes = [
    {
      'title': 'Creamy Garlic Tuscan Salmon',
      'source': 'TikTok - @cookingwithshereen',
      'time': '25 min',
      'emoji': '\u{1F969}',
      'rating': 4.9,
      'category': 'Trending',
    },
    {
      'title': 'Birria Tacos',
      'source': 'Instagram - @mexicanfoodjournal',
      'time': '45 min',
      'emoji': '\u{1F32E}',
      'rating': 4.8,
      'category': 'Viral',
    },
    {
      'title': 'Dubai Chocolate Bar',
      'source': 'TikTok - @fixdessert',
      'time': '30 min',
      'emoji': '\u{1F36B}',
      'rating': 4.7,
      'category': 'Trending',
    },
    {
      'title': 'Baked Feta Pasta',
      'source': 'TikTok - @feelgoodfoodie',
      'time': '35 min',
      'emoji': '\u{1F35D}',
      'rating': 4.9,
      'category': 'Classic',
    },
    {
      'title': 'Korean Corn Cheese',
      'source': 'Instagram - @maangchi',
      'time': '15 min',
      'emoji': '\u{1F33D}',
      'rating': 4.6,
      'category': 'Viral',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Green header
          _buildHeader(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Quick action buttons
                  _buildQuickActions(),
                  const SizedBox(height: 28),
                  // Trending section
                  _buildSectionHeader(
                    'Trending Today',
                    Icons.local_fire_department_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildTrendingCards(),
                  const SizedBox(height: 28),
                  // Recently saved
                  _buildSectionHeader(
                    'Your Recipes',
                    Icons.bookmark_rounded,
                  ),
                  const SizedBox(height: 14),
                  _buildEmptyState(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom input bar
      bottomSheet: _buildInputBar(context),
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
              // Logo & title
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recimo',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'What are we cooking today?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Settings
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

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionChip(
            Icons.search_rounded,
            'Search Web',
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            Icons.image_rounded,
            'From Image',
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _buildActionChip(
            Icons.link_rounded,
            'Paste Link',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip(IconData icon, String label, {VoidCallback? onTap}) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
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
                Icon(icon, color: AppColors.primary, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          Text(
            'See all',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingCards() {
    return SizedBox(
      height: 215,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _trendingRecipes.length,
        itemBuilder: (context, index) {
          final recipe = _trendingRecipes[index];
          return RecipeCard(
            title: recipe['title'],
            source: recipe['source'],
            time: recipe['time'],
            imageEmoji: recipe['emoji'],
            rating: recipe['rating'],
            category: recipe['category'],
            onTap: () {},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No recipes yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ask me what to cook or save a recipe\nto get started',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          focusNode: _searchFocus,
                          decoration: const InputDecoration(
                            hintText: '"I want mac and cheese..."',
                            hintStyle: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          onSubmitted: (value) {
                            // TODO: AI search
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Mic button
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF2E7D32),
                          Color(0xFF43A047),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // TODO: Voice input
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
