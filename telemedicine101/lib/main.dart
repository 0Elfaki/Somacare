import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: const Color(0xFF3884FF)),
        fontFamily: 'Lexend',
      ),
    );
  }
}

