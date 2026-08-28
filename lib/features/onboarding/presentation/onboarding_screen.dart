import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      title: 'Instant Doctor Access',
      subtitle:
          'Talk to a real doctor from school in minutes — no clinic visit needed.',
      icon: Icons.medical_services_outlined,
    ),
    _Slide(
      title: 'AI Symptom Check',
      subtitle: 'Answer a few questions and get a risk level with next steps.',
      icon: Icons.psychology_outlined,
    ),
    _Slide(
      title: 'Medical History Tracking',
      subtitle: 'Keep your visits, notes, and prescriptions organized.',
      icon: Icons.history_outlined,
    ),
    _Slide(
      title: 'Emergency Support',
      subtitle: 'Quick emergency access and ambulance dispatch when it matters.',
      icon: Icons.emergency_outlined,
    ),
    _Slide(
      title: 'Medication Reminders',
      subtitle: 'Stay on track with your medications and dosage schedules.',
      icon: Icons.medication_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _nextOrFinish() {
    if (_index < _slides.length - 1) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      context.go('/role-selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LegacyDarkColors.screenBg,
      body: Column(
        children: [
          // ── Hero area (gradient) ───────────────────────────────────────────
          Expanded(
            flex: 5,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C49E6), Color(0xFF6434C9)],
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Scale the illustration off the smaller of the two
                      // hero-area dimensions, clamped to sane bounds, so it
                      // stays proportional on phones, tablets, and foldables
                      // instead of looking tiny (stretched screen) or
                      // clipped (cramped screen) at a fixed pixel size.
                      final shortSide = constraints.maxWidth < constraints.maxHeight
                          ? constraints.maxWidth
                          : constraints.maxHeight;
                      final circleSize = (shortSide * 0.62).clamp(160.0, 320.0);
                      final iconBoxSize = (shortSide * 0.30).clamp(88.0, 140.0);
                      final iconSize = iconBoxSize * 0.42;

                      return Stack(
                        children: [
                          // Decorative circle
                          Positioned(
                            right: -circleSize * 0.27,
                            top: -circleSize * 0.27,
                            child: Container(
                              width: circleSize,
                              height: circleSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: LegacyDarkColors.lime
                                    .withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: iconBoxSize,
                              height: iconBoxSize,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(
                                  iconBoxSize * 0.25,
                                ),
                              ),
                              child: Icon(
                                s.icon,
                                size: iconSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: LegacyDarkColors.surface,
            child: Center(
              child: ConstrainedBox(
                // Keeps the text/button row from stretching edge-to-edge on
                // wide screens (tablets), matching the phone-card design
                // this content was written for, without touching the
                // gradient hero area above (which stays full width).
                constraints: const BoxConstraints(maxWidth: 480),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress dots
                      Row(
                        children: List.generate(_slides.length, (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: active ? 20 : 20,
                            height: 4,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: active
                                  ? LegacyDarkColors.lime
                                  : Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 14),

                      // Title
                      Text(
                        _slides[_index].title,
                        style: TextStyle(fontFamily: 'Fraunces', 
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 7),

                      // Subtitle
                      Text(
                        _slides[_index].subtitle,
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _OnboardingButton(
                              label: 'Skip',
                              isGhost: true,
                              onPressed: () => context.go('/role-selection'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: _OnboardingButton(
                              label: _index == _slides.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              onPressed: _nextOrFinish,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Local button matching the frozen legacy onboarding look — deliberately
/// independent of the shared BloomButton/AppColors, which follow the
/// app-wide redesign. Onboarding stays visually untouched regardless of any
/// future palette changes.
class _OnboardingButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isGhost;

  const _OnboardingButton({
    required this.label,
    required this.onPressed,
    this.isGhost = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isGhost ? Colors.white.withValues(alpha: 0.1) : LegacyDarkColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final String title;
  final String subtitle;
  final IconData icon;
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
