import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({super.key});

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedSchool;
  List<String> _schools = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSchools() async {
    try {
      final data = await Supabase.instance.client
          .from('schools')
          .select('name')
          .order('name', ascending: true);

      final names = (data as List).map((e) => e['name'] as String).toList();

      if (mounted) {
        setState(() {
          _schools = names;
          _selectedSchool = names.isNotEmpty ? names.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load schools: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  List<String> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _schools;
    return _schools.where((s) => s.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirmSchool() async {
    if (_selectedSchool == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId != null) {
        // Logged in — save to DB then navigate
        await Supabase.instance.client
            .from('profiles')
            .upsert({'id': userId, 'school': _selectedSchool})
            .select('id');

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/student-dashboard');
          });
        }
      } else {
        // Not logged in — pop back to login screen with school name
        if (mounted) Navigator.pop(context, _selectedSchool);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => context.pop(),
                alignment: Alignment.centerLeft,
              ),
              const SizedBox(height: 6),
              const Text(
                'Select Your School',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the university or school you belong to',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search school name',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _schools.isEmpty
                      ? const Center(
                          child: Text(
                            'No schools found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              Divider(color: Colors.grey.shade200),
                          itemBuilder: (context, i) {
                            final s = _filtered[i];
                            final selected = s == _selectedSchool;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                s,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              trailing: selected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                    )
                                  : const Icon(
                                      Icons.circle_outlined,
                                      color: Colors.grey,
                                    ),
                              onTap: () => setState(() => _selectedSchool = s),
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (_selectedSchool != null && !_isSaving)
                      ? _confirmSchool
                      : null,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Confirm School',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
