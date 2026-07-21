import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkScreenBg,
      body: SafeArea(
        child: Column(
          children: [
            const BloomScreenHeader(title: 'My Records'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  BloomCard(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        BloomListItem(
                          leading: const Icon(Icons.folder_open_outlined,
                              color: AppColors.warning, size: 20),
                          title: 'Medical History',
                          subtitle: 'Conditions, allergies, immunizations',
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.darkTextMuted, size: 18),
                          onTap: () => context.push('/medical-history'),
                        ),
                        BloomListItem(
                          leading: const Icon(Icons.science_outlined,
                              color: AppColors.primaryLight, size: 20),
                          title: 'Lab Results',
                          subtitle: 'Test results and trends',
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.darkTextMuted, size: 18),
                          onTap: () => context.push('/lab-results'),
                        ),
                        BloomListItem(
                          leading: const Icon(Icons.description_outlined,
                              color: AppColors.lime, size: 20),
                          title: 'Prescriptions',
                          subtitle: 'Active and past prescriptions',
                          trailing: const Icon(Icons.chevron_right,
                              color: AppColors.darkTextMuted, size: 18),
                          onTap: () => context.push('/prescriptions'),
                          showBorder: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
