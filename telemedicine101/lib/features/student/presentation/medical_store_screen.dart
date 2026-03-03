import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MedicalStoreScreen extends StatelessWidget {
  const MedicalStoreScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Medical Store'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    ),
    body: const Center(child: Text('Coming soon')),
  );
}
