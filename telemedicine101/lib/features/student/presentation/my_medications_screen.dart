import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyMedicationsScreen extends StatelessWidget {
  const MyMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My Medications'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(child: Text('Coming soon')),
  );
}
