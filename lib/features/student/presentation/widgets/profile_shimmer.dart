import 'package:flutter/material.dart';
import '../../../../theme/app_theme.dart';

/// A smooth shimmer / skeleton-loading placeholder for the profile screen.
///
/// Uses a repeating gradient animation instead of a third-party package
/// to keep the dependency tree lean.
class ProfileShimmer extends StatefulWidget {
  const ProfileShimmer({super.key});

  @override
  State<ProfileShimmer> createState() => _ProfileShimmerState();
}

class _ProfileShimmerState extends State<ProfileShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _ctrl,
      builder: (_, _) {
        final p = _ctrl.value;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              _HeaderShimmer(progress: p),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 160, height: 18, progress: p),
                    const SizedBox(height: 16),
                    _ShimmerCard(progress: p, lineCount: 5),
                    const SizedBox(height: 28),
                    ShimmerBox(width: 120, height: 18, progress: p),
                    const SizedBox(height: 16),
                    _ShimmerCard(progress: p, lineCount: 5),
                    const SizedBox(height: 28),
                    ShimmerBox(width: 140, height: 18, progress: p),
                    const SizedBox(height: 16),
                    _ShimmerCard(progress: p, lineCount: 4),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}

// ── Header shimmer ───────────────────────────────────────────────────────────

class _HeaderShimmer extends StatelessWidget {
  final double progress;
  const _HeaderShimmer({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 24,
        20,
        32,
      ),
      decoration: const BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          ShimmerCircle(size: 88, progress: progress),
          const SizedBox(height: 14),
          ShimmerBox(width: 140, height: 20, progress: progress),
          const SizedBox(height: 8),
          ShimmerBox(width: 180, height: 14, progress: progress),
          const SizedBox(height: 8),
          ShimmerBox(
            width: 100,
            height: 24,
            progress: progress,
            borderRadius: 999,
          ),
        ],
      ),
    );
  }
}

// ── Card shimmer ─────────────────────────────────────────────────────────────

class _ShimmerCard extends StatelessWidget {
  final double progress;
  final int lineCount;
  const _ShimmerCard({required this.progress, this.lineCount = 4});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Column(
        children: List.generate(lineCount, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i < lineCount - 1 ? 16 : 0),
            child: Row(
              children: [
                ShimmerCircle(size: 32, progress: progress),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(
                        width: 80 + (i * 10).toDouble(),
                        height: 12,
                        progress: progress,
                      ),
                      const SizedBox(height: 6),
                      ShimmerBox(
                        width: 120 + (i * 8).toDouble(),
                        height: 10,
                        progress: progress,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Primitives ───────────────────────────────────────────────────────────────

class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double progress;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    required this.progress,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * progress, 0),
          end: Alignment(-1.0 + 2.0 * progress + 1.0, 0),
          colors: const [
            AppColors.border,
            AppColors.surfaceMuted,
            AppColors.border,
          ],
        ),
      ),
    );
  }
}

class ShimmerCircle extends StatelessWidget {
  final double size;
  final double progress;
  const ShimmerCircle({super.key, required this.size, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(-1.0 + 2.0 * progress, 0),
          end: Alignment(-1.0 + 2.0 * progress + 1.0, 0),
          colors: const [
            AppColors.border,
            AppColors.surfaceMuted,
            AppColors.border,
          ],
        ),
      ),
    );
  }
}
