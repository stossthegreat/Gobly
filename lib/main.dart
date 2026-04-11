import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/grocery_screen.dart';
import 'services/user_profile_service.dart';
import 'services/meal_plan_service.dart';
import 'services/saved_recipes_service.dart';
import 'services/app_settings_service.dart';
import 'services/cookbooks_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  // Load all services before the app starts so no screens flash empty
  await Future.wait([
    UserProfileService.instance.load(),
    MealPlanService.instance.load(),
    SavedRecipesService.instance.load(),
    AppSettingsService.instance.load(),
    CookbooksService.instance.load(),
  ]);
  runApp(const RecimoApp());
}

class RecimoApp extends StatelessWidget {
  const RecimoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recimo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    PlannerScreen(),
    GroceryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack keeps every tab's state alive when switching
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Plan'),
                _buildNavItem(2, Icons.shopping_cart_rounded, Icons.shopping_cart_outlined, 'Groceries'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        HapticFeedback.selectionClick();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
