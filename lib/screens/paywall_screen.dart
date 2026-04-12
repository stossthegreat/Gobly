import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
// import '../services/usage_service.dart'; // restore when RevenueCat is wired

/// Full-screen dark paywall. No scroll, single viewport.
/// Shown when a free-tier limit is hit.
///
/// Design based on highest-converting patterns from Cal AI, Fastic, Noom:
/// - Dark background, vibrant green CTA
/// - 3 benefit bullets (not features)
/// - Annual pre-selected with per-day framing
/// - Monthly as price anchor
/// - Close button top-right with 2s delay
/// - "Cancel anytime" below CTA
class PaywallScreen extends StatefulWidget {
  /// Context text shown above the headline, e.g. "You've used 3/3 AI searches"
  final String? triggerText;

  const PaywallScreen({super.key, this.triggerText});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  bool _showClose = false;

  @override
  void initState() {
    super.initState();
    // Delay close button by 2 seconds — proven to increase conversion
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showClose = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A12),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button (delayed)
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
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 1),
              // Icon
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 20),
              // Trigger context
              if (widget.triggerText != null) ...[
                Text(
                  widget.triggerText!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              // Headline
              const Text(
                'Unlock Gobly Pro',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your AI-powered kitchen, unlimited.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 28),
              // 3 benefit bullets
              _buildBullet(
                Icons.auto_awesome_rounded,
                'Unlimited AI search & weekly plans',
                'Find the highest-rated recipes and plan your week in seconds, as many times as you want.',
              ),
              const SizedBox(height: 16),
              _buildBullet(
                Icons.tune_rounded,
                'Ingredient scaling',
                'Adjust any recipe from 1 to 20 servings with a tap. Grocery list updates automatically.',
              ),
              const SizedBox(height: 16),
              _buildBullet(
                Icons.menu_book_rounded,
                'Unlimited cookbooks',
                'Organise your recipes into as many collections as you like.',
              ),
              const Spacer(flex: 2),
              // Pro coming soon — pricing removed until RevenueCat is wired
              // so Apple/Google don't reject for fake subscription UI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.rocket_launch_rounded,
                      color: AppColors.primaryLight,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pro is launching soon',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Unlimited AI search, meal plans,\ningredient scaling & more.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // CTA — continue with free tier for now
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
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
                    'Got it',
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
                  'You can still use all manual features for free.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primaryLight, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // _buildPriceTile removed — will be restored when RevenueCat
  // is integrated and real IAP is wired up. Keeping the paywall
  // as a "Pro coming soon" teaser prevents App Store rejection
  // for displaying subscription prices without StoreKit.
}
