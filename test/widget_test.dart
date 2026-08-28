import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somacare/theme/app_theme.dart';
import 'package:somacare/widgets/app_ui.dart';

/// These tests cover the design system rather than the screens, because the
/// screens all require a live Supabase session. They are cheap, they run in
/// CI without a backend, and they lock in the three things that were actually
/// broken before: the theme's declared brightness, the legibility floor of the
/// type scale, and the contrast of the text colours.

// WCAG 2.1 relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

Widget _host(Widget child) =>
    MaterialApp(theme: buildAppTheme(), home: Scaffold(body: child));

void main() {
  group('theme', () {
    test('declares the brightness it actually is', () {
      final theme = buildAppTheme();
      // The old theme was Brightness.dark with light colours, which made
      // Material widgets pick dark defaults on a white page.
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.pageBg);
    });

    test('no body or label style is below the 11px legibility floor', () {
      final t = buildAppTheme().textTheme;
      final sizes = <String, double?>{
        'bodyLarge': t.bodyLarge?.fontSize,
        'bodyMedium': t.bodyMedium?.fontSize,
        'bodySmall': t.bodySmall?.fontSize,
        'labelLarge': t.labelLarge?.fontSize,
        'labelMedium': t.labelMedium?.fontSize,
        'labelSmall': t.labelSmall?.fontSize,
      };
      sizes.forEach((name, size) {
        expect(size, isNotNull, reason: '$name has no size');
        expect(size, greaterThanOrEqualTo(11.0), reason: '$name is $size px');
      });
    });

    test('primary body text meets WCAG AA on the card surface', () {
      expect(
        _contrast(AppColors.textPrimary, AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.textSecondary, AppColors.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(AppColors.onPrimary, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('status colours are distinguishable on the inverse surface', () {
      for (final c in [
        AppColors.successOnDark,
        AppColors.warningOnDark,
        AppColors.errorOnDark,
        AppColors.infoOnDark,
      ]) {
        expect(
          _contrast(c, AppColors.surfaceInverse),
          greaterThanOrEqualTo(3.0),
        );
      }
    });

    test('buttons are at least the minimum touch target tall', () {
      final theme = buildAppTheme();
      final size = theme.elevatedButtonTheme.style?.minimumSize
          ?.resolve(<WidgetState>{});
      expect(size?.height, greaterThanOrEqualTo(AppTouch.minTarget));
    });
  });

  group('status chips', () {
    test('map database statuses onto the shared tones', () {
      expect(appStatusTone('confirmed'), AppStatusTone.success);
      expect(appStatusTone('COMPLETED'), AppStatusTone.success);
      expect(appStatusTone('pending'), AppStatusTone.warning);
      expect(appStatusTone('cancelled'), AppStatusTone.danger);
      expect(appStatusTone('emergency'), AppStatusTone.danger);
      expect(appStatusTone(null), AppStatusTone.neutral);
      expect(appStatusTone('something-else'), AppStatusTone.neutral);
    });

    testWidgets('render a human-readable label', (tester) async {
      await tester.pumpWidget(
        _host(AppStatusChip.fromStatus('in_progress')),
      );
      expect(find.text('In Progress'), findsOneWidget);
    });
  });

  group('bottom navigation', () {
    testWidgets('labels every destination and reports the selected tab',
        (tester) async {
      var tapped = -1;
      await tester.pumpWidget(
        _host(
          AppBottomNav(
            currentIndex: 0,
            destinations: [
              for (var i = 0; i < 3; i++)
                AppNavDestination(
                  icon: Icons.circle_outlined,
                  activeIcon: Icons.circle,
                  label: 'Tab $i',
                  onTap: () => tapped = i,
                ),
            ],
          ),
        ),
      );

      expect(find.text('Tab 0'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);

      await tester.tap(find.text('Tab 1'));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });
  });

  group('empty state', () {
    testWidgets('explains itself and offers the next step', (tester) async {
      var pressed = false;
      await tester.pumpWidget(
        _host(
          AppEmptyState(
            icon: Icons.event_available_outlined,
            title: 'Nothing booked today',
            message: 'Bookings will show up here.',
            actionLabel: 'Book a visit',
            onAction: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Nothing booked today'), findsOneWidget);
      expect(find.text('Bookings will show up here.'), findsOneWidget);

      await tester.tap(find.text('Book a visit'));
      await tester.pumpAndSettle();
      expect(pressed, isTrue);
    });
  });

  group('stat cards', () {
    testWidgets('do not overflow at 360px with three cards', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _host(
          const Padding(
            padding: EdgeInsets.all(AppSpacing.gutter),
            child: AppStatRow(
              cards: [
                AppStatCard(
                  icon: Icons.event_available_rounded,
                  value: '12',
                  label: "Today's\nappointments",
                  color: AppColors.primary,
                ),
                AppStatCard(
                  icon: Icons.emergency_outlined,
                  value: '3',
                  label: 'Open\nemergencies',
                  color: AppColors.error,
                ),
                AppStatCard(
                  icon: Icons.check_circle_outline_rounded,
                  value: '9',
                  label: 'Completed\ntoday',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('12'), findsOneWidget);
    });
  });
}
