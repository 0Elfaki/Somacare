import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/errors/app_error_messages.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_ui.dart';
import '../../../widgets/bloom_components.dart';

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
      final rawNames = (data as List).map((e) => e['name'] as String).toList();
      // Dedupe defensively (case-insensitive, trimmed) — the schools table
      // can end up with duplicate name rows (e.g. re-seeded data), and a
      // repeated entry in this list is confusing during onboarding.
      final seen = <String>{};
      final names = <String>[];
      for (final raw in rawNames) {
        final trimmed = raw.trim();
        if (seen.add(trimmed.toLowerCase())) names.add(trimmed);
      }
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
        showAppSnack(
          context,
          friendlyErrorMessage(
            e,
            context: 'school_selection.load',
            fallback: 'Unable to load schools right now. Please try again.',
          ),
          tone: AppStatusTone.danger,
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
        if (mounted) Navigator.pop(context, _selectedSchool);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showAppSnack(
          context,
          friendlyErrorMessage(
            e,
            context: 'school_selection.confirm',
            fallback: 'We could not save your school. Please try again.',
          ),
          tone: AppStatusTone.danger,
        );
      }
    }
  }

  static const _avatarColors = [
    AppColors.success,
    AppColors.primaryLight,
    AppColors.primaryDark,
    AppColors.primary,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
          children: [
            // Header
            const BloomScreenHeader(title: 'Select your school'),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: BloomSearchField(
                hint: 'Search schools…',
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
              ),
            ),

            // Section label
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 9),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'All schools',
                  style: BloomTextStyles.inter(
                    size: 16,
                    weight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // School list
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BloomCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 6,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        )
                      : _schools.isEmpty
                      ? Center(
                          child: Text(
                            'No schools found',
                            style: BloomTextStyles.inter(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) {
                            final s = _filtered[i];
                            final selected = s == _selectedSchool;
                            final color =
                                _avatarColors[i % _avatarColors.length];
                            return Semantics(
                              button: true,
                              selected: selected,
                              label: s,
                              excludeSemantics: true,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () =>
                                    setState(() => _selectedSchool = s),
                                child: AnimatedContainer(
                                  duration: AppMotion.fast,
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    // Selected rows get the tint and outline
                                    // rather than only a small check: the row
                                    // itself now reads as chosen.
                                    color: selected
                                        ? AppColors.primarySurface
                                        : Colors.transparent,
                                    borderRadius: AppRadius.mdAll,
                                    border: Border.all(
                                      color: selected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.school_outlined,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // No "Tap to select" subtitle: it was
                                      // repeated under every row and said
                                      // nothing the list does not already
                                      // convey.
                                      Expanded(
                                        child: Text(
                                          s,
                                          style: BloomTextStyles.inter(
                                            size: 14,
                                            weight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (selected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          size: 20,
                                          color: AppColors.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),

            // Continue CTA — sticky, and inside a SafeArea so it clears the
            // Android gesture bar.
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _selectedSchool != null && !_isSaving
                          ? _confirmSchool
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        disabledBackgroundColor: AppColors.borderStrong,
                        disabledForegroundColor: AppColors.surface,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onPrimary,
                              ),
                            )
                          : Text(
                              'Continue',
                              style: BloomTextStyles.inter(
                                size: 15,
                                weight: FontWeight.w700,
                                color: AppColors.onPrimary,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ),
      ),
    );
  }
}
