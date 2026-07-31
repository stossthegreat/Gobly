import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'paywall_screen.dart';

/// Two beautiful "free-trial" intro screens that funnel into the paywall.
///
/// Flow:  [_TrialStartScreen]  →  [_TrialTimelineScreen]  →  [PaywallScreen]
///
/// Each screen uses `pushReplacement` so that only one screen sits above the
/// app at a time — closing anywhere (or closing the paywall) returns the user
/// straight to the app, never back through the funnel.
///
/// Colours/buttons intentionally mirror [PaywallScreen] (dark #0A1A0D base,
/// green primary CTA, white text) so the whole flow feels like one product.
void showPaywallFlow(BuildContext context, {String? triggerText}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      pageBuilder: (_, __, ___) => _TrialStartScreen(triggerText: triggerText),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 350),
    ),
  );
}

// Shared palette — matches the paywall.
const Color _bg = Color(0xFF0A1A0D);

/// Screen 1 — the bell, the 7-day trial, the $0.00 CTA.
class _TrialStartScreen extends StatelessWidget {
  final String? triggerText;

  const _TrialStartScreen({this.triggerText});

  void _next(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            _TrialTimelineScreen(triggerText: triggerText),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _CloseButton(onTap: () => Navigator.pop(context)),
              ),
              const Spacer(flex: 2),
              // Headline
              Text(
                'Start your\n7-day free trial',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Unlimited AI recipe search, the AI week planner, '
                'and web recipe capture.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(flex: 2),
              // Glowing bell with a notification badge
              const _GlowingBell(),
              const Spacer(flex: 3),
              // No payment reassurance
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded,
                      color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No payment due now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryCta(
                label: '\$0.00 today — Try 7 days free',
                onTap: () => _next(context),
              ),
              const SizedBox(height: 12),
              const _LegalRow(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 2 — the "we'll remind you" timeline (Day 4, Day 6).
class _TrialTimelineScreen extends StatelessWidget {
  final String? triggerText;

  const _TrialTimelineScreen({this.triggerText});

  void _toPaywall(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => PaywallScreen(triggerText: triggerText),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: _CloseButton(onTap: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 12),
              Text(
                'How your free\ntrial works',
                style: TextStyle(
                  fontSize: 32,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We\'ll remind you before you\'re ever charged.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              // Timeline
              const _TimelineStep(
                icon: Icons.lock_open_rounded,
                accent: true,
                title: 'Today',
                subtitle: 'Unlock everything instantly. \$0.00 due now.',
                isFirst: true,
              ),
              const _TimelineStep(
                icon: Icons.notifications_active_rounded,
                title: 'Day 4',
                subtitle: 'We\'ll remind you your trial is ending soon.',
              ),
              const _TimelineStep(
                icon: Icons.notifications_active_rounded,
                title: 'Day 6',
                subtitle: 'A final reminder — one day left before billing.',
              ),
              const _TimelineStep(
                icon: Icons.star_rounded,
                title: 'Day 7',
                subtitle:
                    'Your subscription begins, unless you\'ve cancelled.',
                isLast: true,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_rounded,
                      color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No payment due now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _PrimaryCta(
                label: 'Continue for free',
                onTap: () => _toPaywall(context),
              ),
              const SizedBox(height: 12),
              const _LegalRow(),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared pieces
// ---------------------------------------------------------------------------

class _GlowingBell extends StatelessWidget {
  const _GlowingBell();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 200,
        height: 200,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 60,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_rounded,
                size: 84,
                color: AppColors.primaryLight,
              ),
            ),
            // Notification badge
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 4),
                ),
                child: const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool accent;
  final bool isFirst;
  final bool isLast;

  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = false,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = accent ? AppColors.primary : Colors.white.withValues(alpha: 0.12);
    final iconColor = accent ? Colors.white : AppColors.primaryLight;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail (connector line + node)
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.12),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accent
                        ? AppColors.primary
                        : Colors.white.withValues(alpha: 0.12),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Text
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PrimaryCta({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.45),
            blurRadius: 28,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Cancel anytime · No commitment',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }
}
