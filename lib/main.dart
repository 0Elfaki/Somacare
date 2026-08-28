import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'theme/app_theme.dart';

/// True when running in a browser or as a desktop app (Windows/macOS/Linux),
/// where the window can be arbitrarily wide. False on native Android/iOS —
/// including tablets — where the app should always fill the real screen.
bool get _isWideWindowPlatform =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://eyycsflzqrueqnllgrvk.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV5eWNzZmx6cXJ1ZXFubGxncnZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIzODYxNDQsImV4cCI6MjA4Nzk2MjE0NH0.ayH7lXE7Kh-H2KHxM2WFSTPjNhC3wcktEg0zHjGHbR4',
  );

  runApp(const ProviderScope(child: SOMACAREApp()));
}

class SOMACAREApp extends StatelessWidget {
  const SOMACAREApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SOMACARE',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: buildDarkTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.dark,
      // SomaCare is a phone-only design (every screen, grid, and layout
      // assumes a ~360-430px wide viewport). On wide *browser or desktop*
      // windows that stretches grids and tiles into huge, broken shapes, so
      // we constrain the app to a phone-like column there and fill the rest
      // of the window with the page background — same as how a phone app
      // looks when viewed on desktop (e.g. web.whatsapp.com).
      //
      // On native Android/iOS builds — phones AND tablets — the app should
      // simply fill the real screen instead, so this constraint is skipped
      // there entirely.
      builder: (context, child) {
        if (!_isWideWindowPlatform) return child ?? const SizedBox.shrink();
        return ColoredBox(
          color: AppColors.darkPageBg,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

