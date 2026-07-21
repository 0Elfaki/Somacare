import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

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
      backgroundColor: AppColors.darkScreenBg,
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
                  child: Stack(
                    children: [
                      // Decorative circle
                      Positioned(
                        right: -60,
                        top: -60,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.lime.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Icon(s.icon,
                              size: 44, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Bottom panel ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            color: AppColors.darkSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                            ? AppColors.lime
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
                      child: BloomButton(
                        label: 'Skip',
                        variant: BloomButtonVariant.ghost,
                        onPressed: () => context.go('/role-selection'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: BloomButton(
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
        ],
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
