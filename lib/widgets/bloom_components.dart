import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// BLOOM COMPONENT LIBRARY
// Shared widgets that implement the SomaCare Bloom design system.
// ═══════════════════════════════════════════════════════════════════════════════

// ─── BloomCard ────────────────────────────────────────────────────────────────

class BloomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final double radius;
  final VoidCallback? onTap;

  const BloomCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.border,
    this.radius = AppRadius.card,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.darkSurface;
    final br = border ??
        Border.all(color: AppColors.darkBorder, width: 1);

    Widget card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: br,
      ),
      padding: padding ?? const EdgeInsets.all(15),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

// ─── BloomButton ──────────────────────────────────────────────────────────────

enum BloomButtonVariant { primary, ghost, emergency, danger, lime }

class BloomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final BloomButtonVariant variant;
  final bool isLoading;
  final double height;
  final Widget? icon;

  const BloomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = BloomButtonVariant.primary,
    this.isLoading = false,
    this.height = 42,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? borderSide;

    switch (variant) {
      case BloomButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
      case BloomButtonVariant.ghost:
        bg = AppColors.darkGhost;
        fg = Colors.white;
      case BloomButtonVariant.emergency:
        bg = AppColors.error;
        fg = Colors.white;
      case BloomButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
      case BloomButtonVariant.lime:
        bg = AppColors.lime;
        fg = AppColors.darkPageBg;
    }

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          color: onPressed == null && !isLoading
              ? bg.withValues(alpha: 0.4)
              : bg,
          borderRadius: BorderRadius.circular(999),
          border: borderSide,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              )
            else ...[
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── BloomStatusBadge ─────────────────────────────────────────────────────────

enum BloomBadgeStatus { active, pending, danger, info, neutral }

class BloomStatusBadge extends StatelessWidget {
  final String label;
  final BloomBadgeStatus status;

  const BloomStatusBadge({
    super.key,
    required this.label,
    this.status = BloomBadgeStatus.active,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case BloomBadgeStatus.active:
        bg = const Color(0x28D8FF4A); // 16% lime
        fg = AppColors.lime;
      case BloomBadgeStatus.pending:
        bg = const Color(0x28FFC15C); // 16% warn
        fg = AppColors.warning;
      case BloomBadgeStatus.danger:
        bg = const Color(0x28FF5C72); // 16% red
        fg = AppColors.error;
      case BloomBadgeStatus.info:
        bg = const Color(0x287C49E6); // 16% purple
        fg = AppColors.primaryLight;
      case BloomBadgeStatus.neutral:
        bg = const Color(0x14FFFFFF);
        fg = const Color(0x99FFFFFF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontFamily: 'Inter', 
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.04,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple text-only badge (no dot)
class BloomTextBadge extends StatelessWidget {
  final String label;
  final BloomBadgeStatus status;

  const BloomTextBadge({
    super.key,
    required this.label,
    this.status = BloomBadgeStatus.active,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (status) {
      case BloomBadgeStatus.active:
        bg = const Color(0x28D8FF4A);
        fg = AppColors.lime;
      case BloomBadgeStatus.pending:
        bg = const Color(0x28FFC15C);
        fg = AppColors.warning;
      case BloomBadgeStatus.danger:
        bg = AppColors.error;
        fg = Colors.white;
      case BloomBadgeStatus.info:
        bg = const Color(0x287C49E6);
        fg = AppColors.primaryLight;
      case BloomBadgeStatus.neutral:
        bg = const Color(0x14FFFFFF);
        fg = const Color(0x99FFFFFF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontFamily: 'Inter', 
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ─── BloomSectionTitle ────────────────────────────────────────────────────────

class BloomSectionTitle extends StatelessWidget {
  final String title;
  final EdgeInsetsGeometry? margin;

  const BloomSectionTitle(this.title, {super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? const EdgeInsets.only(top: 16, bottom: 9),
      child: Text(
        title,
        style: TextStyle(fontFamily: 'Fraunces', 
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: AppColors.darkTextPrimary,
        ),
      ),
    );
  }
}

// ─── BloomScreenHeader ────────────────────────────────────────────────────────

class BloomScreenHeader extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget>? trailing;
  final VoidCallback? onBack;

  const BloomScreenHeader({
    super.key,
    required this.title,
    this.showBack = true,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          if (showBack) ...[
            GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBorder, width: 1),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 13, color: AppColors.darkTextPrimary),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.darkTextPrimary,
              ),
            ),
          ),
          if (trailing != null) ...trailing!,
        ],
      ),
    );
  }
}

// ─── BloomProgressBar ─────────────────────────────────────────────────────────

class BloomProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color? color;
  final double height;

  const BloomProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        backgroundColor: const Color(0x1AFFFFFF),
        color: color ?? AppColors.lime,
        minHeight: height,
      ),
    );
  }
}

// ─── BloomToggle ─────────────────────────────────────────────────────────────

class BloomToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const BloomToggle({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final track = activeColor ?? AppColors.primary;
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: value ? track : AppColors.darkGhost,
          borderRadius: BorderRadius.circular(999),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

// ─── BloomSearchField ─────────────────────────────────────────────────────────

class BloomSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const BloomSearchField({
    super.key,
    this.hint = 'Search…',
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          const Icon(Icons.search, size: 16, color: AppColors.darkTextMuted),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 12, color: AppColors.darkTextPrimary),
              decoration: InputDecoration.collapsed(
                hintText: hint,
                hintStyle: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12, color: AppColors.darkTextMuted),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BloomFilterChips ─────────────────────────────────────────────────────────

class BloomFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const BloomFilterChips({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isSelected = opt == selected;
          return GestureDetector(
            onTap: () => onSelect(opt),
            child: Container(
              margin: const EdgeInsets.only(right: 7),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(999),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.darkBorder, width: 1),
              ),
              child: Text(
                opt,
                style: TextStyle(fontFamily: 'Inter', 
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : const Color(0x99FFFFFF),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── BloomSegmentedControl ────────────────────────────────────────────────────

class BloomSegmentedControl extends StatelessWidget {
  final List<String> tabs;
  final int selected;
  final ValueChanged<int> onSelect;

  const BloomSegmentedControl({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? AppColors.darkGhost : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? Colors.white
                        : const Color(0x80FFFFFF),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── BloomQuickActionTile ─────────────────────────────────────────────────────

class BloomQuickActionTile extends StatelessWidget {
  final String category;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isEmergency;

  const BloomQuickActionTile({
    super.key,
    required this.category,
    required this.label,
    this.icon,
    this.onTap,
    this.isEmergency = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: isEmergency ? AppColors.error : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(AppRadius.tile),
          border: isEmergency
              ? null
              : const Border(
                  left: BorderSide(color: AppColors.primary, width: 3),
                  top: BorderSide(color: AppColors.darkBorder, width: 1),
                  right: BorderSide(color: AppColors.darkBorder, width: 1),
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05,
                    color: isEmergency
                        ? Colors.white.withValues(alpha: 0.8)
                        : const Color(0x80FFFFFF),
                  ),
                ),
                if (icon != null) ...[
                  const Spacer(),
                  Icon(
                    icon,
                    size: 15,
                    color: isEmergency
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppColors.primaryLight,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── BloomTimelineItem ────────────────────────────────────────────────────────

class BloomTimelineItem extends StatelessWidget {
  final Widget card;
  final bool isLast;

  const BloomTimelineItem({
    super.key,
    required this.card,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.darkScreenBg, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      color: const Color(0x1FFFFFFF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 0),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: card,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BloomDivider ─────────────────────────────────────────────────────────────

class BloomDivider extends StatelessWidget {
  const BloomDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.darkBorder,
    );
  }
}

// ─── BloomMonoText ────────────────────────────────────────────────────────────

class BloomMonoText extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  final FontWeight weight;

  const BloomMonoText(
    this.text, {
    super.key,
    this.size = 12,
    this.color,
    this.weight = FontWeight.w500,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontFamily: 'IBM Plex Mono', 
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.darkTextPrimary,
      ),
    );
  }
}

// ─── BloomAvatar ─────────────────────────────────────────────────────────────

class BloomAvatar extends StatelessWidget {
  final double size;
  final List<Color>? gradient;
  final String? initials;
  final bool isSquare;

  const BloomAvatar({
    super.key,
    this.size = 36,
    this.gradient,
    this.initials,
    this.isSquare = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradient ??
        [AppColors.primary, AppColors.primaryLight];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: isSquare
            ? BorderRadius.circular(size * 0.3)
            : BorderRadius.circular(size / 2),
      ),
      alignment: Alignment.center,
      child: initials != null
          ? Text(
              initials!,
              style: TextStyle(fontFamily: 'Inter', 
                  fontSize: size * 0.38,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            )
          : null,
    );
  }
}

// ─── BloomListItem ────────────────────────────────────────────────────────────

class BloomListItem extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showBorder;

  const BloomListItem({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: showBorder
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: AppColors.darkBorder, width: 1),
                ),
              )
            : null,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkTextPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(subtitle!,
                        style: TextStyle(fontFamily: 'Inter', 
                            fontSize: 10.5,
                            color: AppColors.darkTextMuted)),
                  ],
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

// Simple grid map that doesn't use ImageProvider
class BloomMapPlaceholder extends StatelessWidget {
  final double height;
  final bool showAmbulance;

  const BloomMapPlaceholder({
    super.key,
    this.height = 140,
    this.showAmbulance = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A3037),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: CustomPaint(
        painter: _GridPainter(),
        child: Stack(
          children: [
            if (showAmbulance)
              Positioned(
                left: height * 0.4,
                top: height * 0.6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Positioned(
              right: height * 0.25,
              top: height * 0.3,
              child: Transform.rotate(
                angle: -0.785,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                      bottomLeft: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withValues(alpha: 0.4),
                        blurRadius: 5,
                      )
                    ],
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── BloomBottomNav ───────────────────────────────────────────────────────────

class BloomStudentBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Home', 'AI Check', 'Book', 'Visits', 'Profile'];
  static const _icons = [
    Icons.home_outlined,
    Icons.psychology_outlined,
    Icons.calendar_today_outlined,
    Icons.event_note_outlined,
    Icons.person_outline,
  ];

  const BloomStudentBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Container(
                          width: 20,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(height: 7),
                      Icon(
                        _icons[i],
                        size: 18,
                        color: active
                            ? AppColors.lime
                            : const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 8.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
                          color: active
                              ? AppColors.lime
                              : const Color(0x66FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class BloomDoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _labels = ['Dashboard', 'Schedule', 'Patients', 'Profile'];
  static const _icons = [
    Icons.grid_view_outlined,
    Icons.calendar_month_outlined,
    Icons.people_outline,
    Icons.person_outline,
  ];

  const BloomDoctorBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_labels.length, (i) {
              final active = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (active)
                        Container(
                          width: 20,
                          height: 3,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        )
                      else
                        const SizedBox(height: 7),
                      Icon(
                        _icons[i],
                        size: 18,
                        color: active
                            ? AppColors.lime
                            : const Color(0x66FFFFFF),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: TextStyle(fontFamily: 'Inter', 
                          fontSize: 8.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w600,
                          color: active
                              ? AppColors.lime
                              : const Color(0x66FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─── BloomInputField ─────────────────────────────────────────────────────────

class BloomInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final int? maxLines;

  const BloomInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.darkTextMuted,
            letterSpacing: 0.04,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.darkBorder, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  keyboardType: keyboardType,
                  maxLines: obscureText ? 1 : maxLines,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12,
                    color: AppColors.darkTextPrimary,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: hint,
                    hintStyle: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      color: AppColors.darkTextMuted,
                    ),
                  ),
                ),
              ),
              ?suffix,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── BloomPaymentMethodTile ───────────────────────────────────────────────────

class BloomPaymentMethodTile extends StatelessWidget {
  final Color iconColor;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBorder;

  const BloomPaymentMethodTile({
    super.key,
    required this.iconColor,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: showBorder
            ? const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.darkBorder, width: 1),
                ),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 12, color: AppColors.darkTextPrimary),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(color: AppColors.primary, width: 5)
                    : Border.all(
                        color: const Color(0x33FFFFFF), width: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
