import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _specializationCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _workingHoursCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specializationCtrl.dispose();
    _licenseCtrl.dispose();
    _workingHoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profile = data;
          _nameCtrl.text = (data?['full_name'] as String?) ?? '';
          _specializationCtrl.text = (data?['specialization'] as String?) ?? '';
          _licenseCtrl.text = (data?['license_number'] as String?) ?? '';
          _workingHoursCtrl.text =
              (data?['working_hours'] as String?) ?? '09:00 - 17:00';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': _nameCtrl.text.trim(),
            'specialization': _specializationCtrl.text.trim(),
            'license_number': _licenseCtrl.text.trim(),
            'working_hours': _workingHoursCtrl.text.trim(),
          })
          .eq('id', userId);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _profile = {
            ...?_profile,
            'full_name': _nameCtrl.text.trim(),
            'specialization': _specializationCtrl.text.trim(),
            'license_number': _licenseCtrl.text.trim(),
            'working_hours': _workingHoursCtrl.text.trim(),
          };
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    final fullName = (_profile?['full_name'] as String?) ?? 'Doctor';
    final specialization =
        (_profile?['specialization'] as String?) ?? 'General Practice';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = true),
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            TextButton(
              onPressed: () {
                setState(() => _isEditing = false);
                _loadProfile(); // discard changes
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF059669),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF059669)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar + Name ─────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF059669), Color(0xFF0891B2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Dr. $fullName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          specialization,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF059669),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Profile Fields ────────────────────
                  _SectionCard(
                    title: 'Professional Info',
                    child: Column(
                      children: [
                        _ProfileField(
                          label: 'Full Name',
                          controller: _nameCtrl,
                          isEditing: _isEditing,
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          label: 'Specialization',
                          controller: _specializationCtrl,
                          isEditing: _isEditing,
                          icon: Icons.medical_services_outlined,
                          hint: 'e.g. General Practice',
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          label: 'License Number',
                          controller: _licenseCtrl,
                          isEditing: _isEditing,
                          icon: Icons.badge_outlined,
                          hint: 'e.g. LIC-001',
                        ),
                        const SizedBox(height: 14),
                        _ProfileField(
                          label: 'Working Hours',
                          controller: _workingHoursCtrl,
                          isEditing: _isEditing,
                          icon: Icons.access_time_outlined,
                          hint: 'e.g. 09:00 - 17:00',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Account ───────────────────────────
                  _SectionCard(
                    title: 'Account',
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: email,
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.shield_outlined,
                          label: 'Role',
                          value: 'Doctor',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Logout ────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDC2626)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ── Section Card ──────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ── Profile Field ─────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isEditing;
  final IconData icon;
  final String? hint;

  const _ProfileField({
    required this.label,
    required this.controller,
    required this.isEditing,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (isEditing)
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 13,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF059669)),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                Text(
                  controller.text.isEmpty
                      ? (hint ?? 'Not set')
                      : controller.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: controller.text.isEmpty
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
