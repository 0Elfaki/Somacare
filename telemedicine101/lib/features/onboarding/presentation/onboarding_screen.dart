import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      subtitle: 'Book and join consultations quickly when you need help.',
      imagePath: 'assets/images/onboarding_video_call.svg',
    ),
    _Slide(
      title: 'AI Symptom Check',
      subtitle: 'Answer a few questions and get a risk level with next steps.',
      imagePath: 'assets/images/onboarding_ai.svg',
    ),
    _Slide(
      title: 'Medical History Tracking',
      subtitle: 'Keep your visits, notes, and prescriptions organized.',
      imagePath: 'assets/images/onboarding_history.svg',
    ),
    _Slide(
      title: 'Emergency Support',
      subtitle: 'Quick emergency access when symptoms are serious.',
      imagePath: 'assets/images/onboarding_emergency.svg',
    ),
    _Slide(
      title: 'Medication Reminders',
      subtitle: 'Stay on track with your medications and schedules.',
      imagePath: 'assets/images/onboarding_medication.svg',
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
      context.go('/role-selection'); // ✅ fixed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              // ── Skip button ───────────────────────────
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/role-selection'), // ✅ fixed
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // ── Slides ────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageCtrl,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(s.imagePath, width: 140, height: 140),
                        const SizedBox(height: 22),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.35,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Dots ──────────────────────────────────
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: active ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),

              // ── Next / Get Started ────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextOrFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _index == _slides.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              // ✅ "I already have an account" REMOVED
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide {
  final String title;
  final String subtitle;
  final String imagePath;
  const _Slide({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

// To use your custom illustrations:
// 1. Place your image files in: assets/images/
// 2. Name them as: onboarding_video_call.svg, onboarding_ai.svg, onboarding_history.svg, onboarding_emergency.svg, onboarding_medication.svg
// 3. Run: flutter pub get
// 4. Restart the app to load the new assets
