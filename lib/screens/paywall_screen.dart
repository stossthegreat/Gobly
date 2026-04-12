import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Full-screen dark paywall. Clean, minimal, high-converting.
class PaywallScreen extends StatefulWidget {
  final String? triggerText;

  const PaywallScreen({super.key, this.triggerText});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _showClose = false;
  bool _annual = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showClose = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  opacity: _showClose ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: GestureDetector(
                    onTap: _showClose ? () => Navigator.pop(context) : null,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Logo
              Image.asset('assets/logo.png', width: 72, height: 72),
              const SizedBox(height: 18),
              // Headline
              const Text(
                'Go Pro',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              if (widget.triggerText != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.triggerText!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // 3 features — single line each
              const SizedBox(height: 20),
              _feature(Icons.auto_awesome_rounded,
                  'Unlimited AI searches & meal plans'),
              const SizedBox(height: 14),
              _feature(
                  Icons.tune_rounded, 'Ingredient scaling for any serving size'),
              const SizedBox(height: 14),
              _feature(Icons.menu_book_rounded, 'Unlimited cookbooks'),
              const Spacer(flex: 2),
              // Pricing — equal-size cards
              Row(
                children: [
                  Expanded(
                    child: _priceCard(
                      label: 'Monthly',
                      price: '\$4.99',
                      sub: '/month',
                      isSelected: !_annual,
                      onTap: () => setState(() => _annual = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _priceCard(
                      label: 'Annual',
                      price: '\$29.99',
                      sub: '/year',
                      badge: 'SAVE 50%',
                      perDay: '\$0.08/day',
                      isSelected: _annual,
                      onTap: () => setState(() => _annual = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // CTA
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    // TODO: RevenueCat purchase — user will set up in store
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Start Free Trial',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  '7-day free trial · Cancel anytime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Restore purchases
                  },
                  child: Text(
                    'Restore purchase',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.3),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceCard({
    required String label,
    required String price,
    required String sub,
    String? badge,
    String? perDay,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        onTap();
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? AppColors.primaryLight
                        : Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                if (badge != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    sub,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
            if (perDay != null) ...[
              const SizedBox(height: 4),
              Text(
                perDay,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryLight.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
