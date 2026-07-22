import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'theme/app_theme.dart';

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
      // assumes a ~360-430px wide viewport). On wide browser windows
      // (web/desktop) that stretches grids and tiles into huge, broken
      // shapes. Constrain the whole app to a phone-like column and fill
      // the rest of the window with the page background, same as how a
      // phone app looks when viewed on desktop (e.g. web.whatsapp.com).
      builder: (context, child) {
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

