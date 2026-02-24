import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../theme/app_theme.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  final _schoolController = TextEditingController();
  String? _selectedSchool;
  final List<String> _schools = [
    'Al Salam International School',
    'British International School Riyadh',
    'Dar Al Fikr Schools',
    'International Schools Group',
    'King Abdulaziz University Prep School',
    'Modern International School',
    'Rabigh Schools',
    'Saudi Aramco Expat Schools',
    'Thamer International School',
    'Western International School',
  ];

  void _onSchoolSelected(String school) {
    setState(() => _selectedSchool = school);
  }

  @override
  void dispose() {
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Select Your School',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your school to access approved doctors and services.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              // Search field
              TextField(
                controller: _schoolController,
                decoration: InputDecoration(
                  labelText: 'Search schools...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _schoolController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _schoolController.clear();
                            setState(() => _selectedSchool = null);
                          },
                        )
                      : null,
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Schools list
              Expanded(
                child: ListView.builder(
                  itemCount: _schools.length,
                  itemBuilder: (context, index) {
                    final school = _schools[index];
                    final matchesSearch = school.toLowerCase().contains(
                      _schoolController.text.toLowerCase(),
                    );

                    if (!matchesSearch) return const SizedBox.shrink();

                    final isSelected = _selectedSchool == school;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      leading: isSelected
                          ? const Icon(
                              Icons.radio_button_checked,
                              color: AppColors.primary,
                            )
                          : const Icon(Icons.radio_button_unchecked),
                      title: Text(
                        school,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      onTap: () => _onSchoolSelected(school),
                    );
                  },
                ),
              ),

              // Continue button
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _selectedSchool != null
                    ? () => context.pushNamed(
                        'studentLogin',
                        extra: _selectedSchool!,
                      )
                    : null,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
