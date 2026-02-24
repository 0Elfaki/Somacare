import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/app_theme.dart';
import 'core/routing/app_router.dart';

void main() {
  runApp(const ProviderScope(child: TelemedicineApp()));
}

class TelemedicineApp extends ConsumerWidget {
  const TelemedicineApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Telemedicine101',
      theme: buildAppTheme(),
      routerConfig: appRouter,
    );
  }
}
