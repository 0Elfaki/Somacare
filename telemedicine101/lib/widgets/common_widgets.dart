import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable card widget with theme-based styling.
///
/// Features:
/// - Theme-based colors, shadows, and border radius
/// - Optional onTap handler for interactivity
/// - Optional header with title and action widget
/// - Configurable padding
class ModernCard extends StatelessWidget {
  /// The content of the card
  final Widget child;

  /// Optional callback when card is tapped
  final VoidCallback? onTap;

  /// Optional header widget containing title and action
  final Widget? header;

  /// Padding around the card content
  final EdgeInsetsGeometry padding;

  /// Background color of the card
  final Color? backgroundColor;

  /// Whether to apply elevation shadow
  final bool withShadow;

  /// Border radius of the card
  final BorderRadius? borderRadius;

  const ModernCard({
    super.key,
    required this.child,
    this.onTap,
    this.header,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.backgroundColor,
    this.withShadow = true,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: borderRadius ?? AppRadius.mdAll,
        boxShadow: withShadow ? AppShadows.card : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) ...[header!, const Divider(height: 1)],
          Padding(padding: padding, child: child),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: borderRadius ?? AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ?? AppRadius.mdAll,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// A widget that builds a header for the ModernCard
class ModernCardHeader extends StatelessWidget {
  /// The title text
  final String title;

  /// Optional action widget (e.g., icon button, text button)
  final Widget? action;

  /// Optional subtitle text
  final String? subtitle;

  const ModernCardHeader({
    super.key,
    required this.title,
    this.action,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// A responsive grid layout that adapts to screen size.
///
/// Breakpoints:
/// - Mobile (< 600px): single column
/// - Tablet (600-900px): 2 columns
/// - Desktop (> 900px): 3 columns
///
/// Features:
/// - Configurable spacing between items
/// - Configurable child aspect ratio
/// - Responsive column count based on screen width
class ResponsiveGrid extends StatelessWidget {
  /// The list of children to display in the grid
  final List<Widget> children;

  /// Spacing between grid items (both horizontal and vertical)
  final double spacing;

  /// Aspect ratio for each grid item (width / height)
  final double childAspectRatio;

  /// Maximum number of columns (useful for limiting on large screens)
  final int? maxColumns;

  /// Padding around the grid
  final EdgeInsetsGeometry padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.childAspectRatio = 1.0,
    this.maxColumns,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate number of columns based on screen width
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;

          if (screenWidth < 600) {
            crossAxisCount = 1; // Mobile
          } else if (screenWidth < 900) {
            crossAxisCount = 2; // Tablet
          } else {
            crossAxisCount = 3; // Desktop
          }

          // Apply max columns limit if specified
          if (maxColumns != null && crossAxisCount > maxColumns!) {
            crossAxisCount = maxColumns!;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        },
      ),
    );
  }
}

/// A simple responsive grid that wraps children in columns
/// without requiring a fixed number of items.
class ResponsiveGridView extends StatelessWidget {
  /// The list of children to display
  final List<Widget> children;

  /// Spacing between items
  final double spacing;

  /// Aspect ratio for each child
  final double childAspectRatio;

  /// Maximum columns to display
  final int maxColumns;

  /// Padding around the grid
  final EdgeInsetsGeometry padding;

  /// Scroll physics
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = AppSpacing.lg,
    this.childAspectRatio = 1.0,
    this.maxColumns = 3,
    this.padding = EdgeInsets.zero,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          int crossAxisCount;

          if (screenWidth < 600) {
            crossAxisCount = 1;
          } else if (screenWidth < 900) {
            crossAxisCount = 2;
          } else {
            crossAxisCount = maxColumns;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: physics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: children.length,
            itemBuilder: (context, index) => children[index],
          );
        },
      ),
    );
  }
}

/// A section title widget with optional subtitle and action button.
///
/// Features:
/// - Title text with theme-based styling
/// - Optional subtitle for additional context
/// - Optional action button (e.g., "See All")
/// - Theme-based typography
class SectionHeader extends StatelessWidget {
  /// The main title text
  final String title;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional action button text
  final String? actionText;

  /// Optional callback for action button
  final VoidCallback? onActionTap;

  /// Optional icon for action button
  final IconData? actionIcon;

  /// Vertical spacing after the header
  final double bottomSpacing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onActionTap,
    this.actionIcon,
    this.bottomSpacing = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionText != null || actionIcon != null)
            TextButton.icon(
              onPressed: onActionTap,
              icon: actionIcon != null
                  ? Icon(actionIcon, size: 18)
                  : const SizedBox.shrink(),
              label: Text(actionText ?? ''),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A widget to display when a list is empty.
///
/// Features:
/// - Icon to represent the empty state
/// - Title and message text
/// - Optional action button
/// - Theme-based styling
class EmptyStateWidget extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Message/description text
  final String message;

  /// Optional action button text
  final String? actionText;

  /// Optional callback for action button
  final VoidCallback? onActionTap;

  /// Optional icon color
  final Color? iconColor;

  /// Icon size
  final double iconSize;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionText,
    this.onActionTap,
    this.iconColor,
    this.iconSize = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onActionTap != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(onPressed: onActionTap, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A loading indicator overlay with semi-transparent background.
///
/// Features:
/// - Semi-transparent dark background
/// - Circular progress indicator
/// - Optional loading message
/// - Centered content
class LoadingOverlay extends StatelessWidget {
  /// Whether to show the loading overlay
  final bool isLoading;

  /// Optional message to display below the spinner
  final String? message;

  /// The child widget to display behind the overlay
  final Widget child;

  /// Background color opacity (0.0 - 1.0)
  final double opacity;

  /// Color of the progress indicator
  final Color? progressColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    this.message,
    required this.child,
    this.opacity = 0.5,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: opacity),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: progressColor ?? AppColors.primary,
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A simple loading indicator widget (non-overlay version).
class LoadingIndicator extends StatelessWidget {
  /// Optional message to display
  final String? message;

  /// Size of the progress indicator
  final double size;

  /// Color of the progress indicator
  final Color? color;

  const LoadingIndicator({super.key, this.message, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// A widget that shows a shimmer loading effect for skeleton loading states.
class ShimmerLoading extends StatefulWidget {
  /// The width of the shimmer element
  final double? width;

  /// The height of the shimmer element
  final double height;

  /// Border radius of the shimmer element
  final BorderRadius? borderRadius;

  const ShimmerLoading({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.smAll,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Color(0xFFE2E8F0),
                Color(0xFFF1F5F9),
                Color(0xFFE2E8F0),
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value,
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A simplified section divider widget
class SectionDivider extends StatelessWidget {
  /// Optional vertical spacing
  final double spacing;

  const SectionDivider({super.key, this.spacing = AppSpacing.lg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing),
      child: const Divider(),
    );
  }
}

/// A chip/tag widget for displaying labels or categories
class ModernChip extends StatelessWidget {
  /// The label text
  final String label;

  /// Optional icon to display before the label
  final IconData? icon;

  /// Background color of the chip
  final Color? backgroundColor;

  /// Text color of the chip label
  final Color? textColor;

  /// Whether the chip is selected/active
  final bool isSelected;

  /// Optional callback when chip is tapped
  final VoidCallback? onTap;

  const ModernChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.15)
        : backgroundColor ?? AppColors.surfaceVariant;
    final fgColor =
        textColor ?? (isSelected ? AppColors.primary : AppColors.textSecondary);

    return Material(
      color: bgColor,
      borderRadius: AppRadius.fullAll,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.fullAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fgColor),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: fgColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An avatar widget with fallback for initials
class ModernAvatar extends StatelessWidget {
  /// The image URL or asset path
  final String? imageUrl;

  /// The fallback initials to display
  final String? initials;

  /// Size of the avatar
  final double size;

  /// Background color
  final Color? backgroundColor;

  /// Text color
  final Color? textColor;

  const ModernAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = 48,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryLight.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: imageUrl != null
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildInitials(context),
              ),
            )
          : _buildInitials(context),
    );
  }

  Widget _buildInitials(BuildContext context) {
    return Center(
      child: Text(
        initials ?? '',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: textColor ?? AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A status badge widget
class StatusBadge extends StatelessWidget {
  /// The status text to display
  final String status;

  /// The type of status (determines color)
  final StatusBadgeType type;

  /// Optional icon
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.status,
    this.type = StatusBadgeType.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: type.backgroundColor,
        borderRadius: AppRadius.fullAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: type.textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            status,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: type.textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Enum for status badge types
enum StatusBadgeType {
  success,
  warning,
  error,
  info,
  neutral;

  Color get backgroundColor {
    switch (this) {
      case StatusBadgeType.success:
        return AppColors.successLight;
      case StatusBadgeType.warning:
        return AppColors.warningLight;
      case StatusBadgeType.error:
        return AppColors.errorLight;
      case StatusBadgeType.info:
        return AppColors.infoLight;
      case StatusBadgeType.neutral:
        return AppColors.surfaceVariant;
    }
  }

  Color get textColor {
    switch (this) {
      case StatusBadgeType.success:
        return AppColors.success;
      case StatusBadgeType.warning:
        return AppColors.warning;
      case StatusBadgeType.error:
        return AppColors.error;
      case StatusBadgeType.info:
        return AppColors.info;
      case StatusBadgeType.neutral:
        return AppColors.textSecondary;
    }
  }
}
