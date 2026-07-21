import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _isEditing = false;

  int _height = 170;
  int _weight = 70;
  String _bloodType = 'A+';
  int _systolic = 120;
  int _diastolic = 80;

  // ── Settings state ──
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  String _language = 'English';

  final _allergiesCtrl = TextEditingController();

  static const _bloodTypes = [
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select(
            'full_name,school,height,weight,blood_type,blood_pressure,allergies',
          )
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _profile = data;
          _height = int.tryParse(data?['height']?.toString() ?? '') ?? 170;
          _weight = int.tryParse(data?['weight']?.toString() ?? '') ?? 70;
          _bloodType = data?['blood_type'] as String? ?? 'A+';
          final bp = (data?['blood_pressure'] ?? '120/80').toString();
          final parts = bp.split('/');
          _systolic = int.tryParse(parts.isNotEmpty ? parts[0] : '120') ?? 120;
          _diastolic = int.tryParse(parts.length > 1 ? parts[1] : '80') ?? 80;
          _allergiesCtrl.text = data?['allergies'] as String? ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'height': _height.toString(),
        'weight': _weight.toString(),
        'blood_type': _bloodType,
        'blood_pressure': '$_systolic/$_diastolic',
        'allergies': _allergiesCtrl.text.trim(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated!'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Pickers ───────────────────────────────────────────────────────────────
  void _pickHeight() {
    int temp = _height;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Select Height (cm)',
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
            initialItem: temp - 100,
          ),
          itemExtent: 40,
          onSelectedItemChanged: (i) => temp = i + 100,
          children: List.generate(
            121,
            (i) => Center(
              child: Text(
                '${i + 100} cm',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
        onDone: () => setState(() => _height = temp),
      ),
    );
  }

  void _pickWeight() {
    int temp = _weight;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Select Weight (kg)',
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(initialItem: temp - 30),
          itemExtent: 40,
          onSelectedItemChanged: (i) => temp = i + 30,
          children: List.generate(
            171,
            (i) => Center(
              child: Text('${i + 30} kg', style: const TextStyle(fontSize: 18)),
            ),
          ),
        ),
        onDone: () => setState(() => _weight = temp),
      ),
    );
  }

  void _pickBloodType() {
    String temp = _bloodType;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickerSheet(
        title: 'Select Blood Type',
        child: CupertinoPicker(
          scrollController: FixedExtentScrollController(
            initialItem: _bloodTypes
                .indexOf(_bloodType)
                .clamp(0, _bloodTypes.length - 1),
          ),
          itemExtent: 44,
          onSelectedItemChanged: (i) => temp = _bloodTypes[i],
          children: _bloodTypes
              .map(
                (t) => Center(
                  child: Text(t, style: const TextStyle(fontSize: 20)),
                ),
              )
              .toList(),
        ),
        onDone: () => setState(() => _bloodType = temp),
      ),
    );
  }

  void _pickBP() {
    int tempS = _systolic;
    int tempD = _diastolic;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => SizedBox(
          height: 320,
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Blood Pressure (mmHg)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _systolic = tempS;
                          _diastolic = tempD;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          'Systolic',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Diastolic',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: (tempS - 60).clamp(0, 140),
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) =>
                            setModal(() => tempS = i + 60),
                        children: List.generate(
                          141,
                          (i) => Center(
                            child: Text(
                              '${i + 60}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Text(
                      '/',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        scrollController: FixedExtentScrollController(
                          initialItem: (tempD - 40).clamp(0, 90),
                        ),
                        itemExtent: 40,
                        onSelectedItemChanged: (i) =>
                            setModal(() => tempD = i + 40),
                        children: List.generate(
                          91,
                          (i) => Center(
                            child: Text(
                              '${i + 40}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Payment Sheets ────────────────────────────────────────────────────────
  void _showPaymentSheet(
    BuildContext ctx,
    String title,
    String hint,
    Color color,
  ) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Link $title',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                      content: Text('✅ $title linked!'),
                      backgroundColor: color,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Link Account',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardSheet(BuildContext ctx) {
    final cardCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    final cvvCtrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Card',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardCtrl,
              keyboardType: TextInputType.number,
              decoration: _cardDeco('Card Number', Icons.credit_card),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    decoration: _cardDeco('MM/YY', Icons.date_range),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvvCtrl,
                    obscureText: true,
                    decoration: _cardDeco('CVV', Icons.lock_outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Card added!'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.info,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Add Card',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _cardDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
    filled: true,
    fillColor: AppColors.surfaceVariant,
    border: const OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: AppColors.border),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: AppColors.info, width: 2),
    ),
  );

  // ── Change Password ───────────────────────────────────────────────────────
  void _showChangePasswordSheet(BuildContext ctx) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.mdAll,
                  borderSide: BorderSide(color: AppColors.warning, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await Supabase.instance.client.auth.updateUser(
                      UserAttributes(password: ctrl.text.trim()),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Password updated!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Update Password',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── About SOMA CARE ────────────────────────────────────────────────────────
  void _showAboutSheet(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'SOMA CARE',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Version 2.0.0',
              style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your trusted telemedicine companion for student health and wellness.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2026 SOMACARE',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/onboarding');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final name = _profile?['full_name'] as String? ?? user?.email ?? 'Student';
    final email = user?.email ?? '';
    final school = _profile?['school'] as String? ?? 'University';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final maxContentWidth = isTablet ? 600.0 : double.infinity;

                return CustomScrollView(
                  slivers: [
                    // ── Header ──────────────────────────────
                    SliverToBoxAdapter(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 40 : 20,
                          MediaQuery.of(context).padding.top + 16,
                          isTablet ? 40 : 20,
                          32,
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 52,
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: AppShadows.sm,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                school,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Personal Info Header ─────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          isTablet ? 24 : 16,
                          24,
                          isTablet ? 24 : 16,
                          0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (_isEditing) {
                                  _saveProfile();
                                } else {
                                  setState(() => _isEditing = true);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isEditing
                                      ? AppColors.success
                                      : AppColors.primaryLight.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isEditing ? Icons.check : Icons.edit,
                                      size: 16,
                                      color: _isEditing
                                          ? Colors.white
                                          : AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isEditing ? 'Save' : 'Edit',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _isEditing
                                            ? Colors.white
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Info Fields ──────────────────────────
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _Card(
                            child: Column(
                              children: [
                                _PickerRow(
                                  icon: Icons.height,
                                  label: 'Height',
                                  value: '$_height cm',
                                  editing: _isEditing,
                                  onTap: _pickHeight,
                                ),
                                const _HDivider(),
                                _PickerRow(
                                  icon: Icons.monitor_weight_outlined,
                                  label: 'Weight',
                                  value: '$_weight kg',
                                  editing: _isEditing,
                                  onTap: _pickWeight,
                                ),
                                const _HDivider(),
                                _PickerRow(
                                  icon: Icons.bloodtype_outlined,
                                  label: 'Blood Type',
                                  value: _bloodType,
                                  editing: _isEditing,
                                  onTap: _pickBloodType,
                                ),
                                const _HDivider(),
                                _PickerRow(
                                  icon: Icons.favorite_outline,
                                  label: 'Blood Pressure',
                                  value: '$_systolic / $_diastolic mmHg',
                                  editing: _isEditing,
                                  onTap: _pickBP,
                                ),
                                const _HDivider(),
                                _TypedRow(
                                  icon: Icons.warning_amber_outlined,
                                  label: 'Allergies',
                                  ctrl: _allergiesCtrl,
                                  editing: _isEditing,
                                  hint: 'e.g. Penicillin',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Quick Access ─────────────────────────
                    _SectionLabel('Quick Access', isTablet: isTablet),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _Card(
                            child: Column(
                              children: [
                                _MenuTile(
                                  icon: Icons.calendar_today_outlined,
                                  color: AppColors.info,
                                  label: 'My Appointments',
                                  onTap: () => context.go('/my-appointments'),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.inventory_2_outlined,
                                  color: const Color(0xFFDB2777),
                                  label: 'My Prescriptions',
                                  onTap: () => context.push('/prescriptions'),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.folder_open_outlined,
                                  color: AppColors.warning,
                                  label: 'My Medical History',
                                  onTap: () => context.push('/medical-history'),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.medication_outlined,
                                  color: AppColors.secondary,
                                  label: 'My Medications',
                                  onTap: () => context.push('/my-medications'),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.description_outlined,
                                  color: AppColors.success,
                                  label: 'My Records',
                                  onTap: () => context.push('/records'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Payment Methods ───────────────────────
                    _SectionLabel('Payment Methods', isTablet: isTablet),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _Card(
                            child: Column(
                              children: [
                                _PaymentTile(
                                  logo: '📱',
                                  name: 'MTN Mobile Money',
                                  subtitle: 'Link your MTN MoMo number',
                                  color: const Color(0xFFFFCC00),
                                  onTap: () => _showPaymentSheet(
                                    context,
                                    'MTN Mobile Money',
                                    'Enter MTN number (e.g. 077X XXX XXX)',
                                    const Color(0xFFFFAA00),
                                  ),
                                ),
                                const _HDivider(),
                                _PaymentTile(
                                  logo: '📱',
                                  name: 'Airtel Money',
                                  subtitle: 'Link your Airtel number',
                                  color: const Color(0xFFDC2626),
                                  onTap: () => _showPaymentSheet(
                                    context,
                                    'Airtel Money',
                                    'Enter Airtel number (e.g. 075X XXX XXX)',
                                    const Color(0xFFDC2626),
                                  ),
                                ),
                                const _HDivider(),
                                _PaymentTile(
                                  logo: '💳',
                                  name: 'Visa / Mastercard',
                                  subtitle: 'Add a debit or credit card',
                                  color: AppColors.info,
                                  onTap: () => _showCardSheet(context),
                                ),
                                const _HDivider(),
                                _PaymentTile(
                                  logo: '🏦',
                                  name: 'Bank Transfer',
                                  subtitle: 'Stanbic · DFCU · Centenary Bank',
                                  color: AppColors.success,
                                  onTap: () => _showPaymentSheet(
                                    context,
                                    'Bank Transfer',
                                    'Enter bank account number',
                                    AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Settings ──────────────────────────────
                    _SectionLabel('Settings', isTablet: isTablet),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _Card(
                            child: Column(
                              children: [
                                _SettingsTile(
                                  icon: Icons.notifications_outlined,
                                  label: 'Notifications',
                                  color: AppColors.info,
                                  trailing: Switch(
                                    value: _notificationsEnabled,
                                    activeThumbColor: AppColors.info,
                                    onChanged: (v) => setState(
                                      () => _notificationsEnabled = v,
                                    ),
                                  ),
                                ),
                                const _HDivider(),
                                _SettingsTile(
                                  icon: Icons.dark_mode_outlined,
                                  label: 'Dark Mode',
                                  color: AppColors.secondary,
                                  trailing: Switch(
                                    value: _darkMode,
                                    activeThumbColor: AppColors.secondary,
                                    onChanged: (v) =>
                                        setState(() => _darkMode = v),
                                  ),
                                ),
                                const _HDivider(),
                                _SettingsTile(
                                  icon: Icons.language_outlined,
                                  label: 'Language',
                                  color: AppColors.success,
                                  trailing: DropdownButton<String>(
                                    value: _language,
                                    underline: const SizedBox(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'English',
                                        child: Text('English'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Luganda',
                                        child: Text('Luganda'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'Swahili',
                                        child: Text('Swahili'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _language = v ?? 'English',
                                    ),
                                  ),
                                ),
                                const _HDivider(),
                                _SettingsTile(
                                  icon: Icons.lock_outline,
                                  label: 'Change Password',
                                  color: AppColors.warning,
                                  onTap: () =>
                                      _showChangePasswordSheet(context),
                                ),
                                const _HDivider(),
                                _SettingsTile(
                                  icon: Icons.info_outline,
                                  label: 'About SOMA CARE',
                                  color: AppColors.info,
                                  labelColor: AppColors.info,
                                  onTap: () => _showAboutSheet(context),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Help & Support ────────────────────────
                    _SectionLabel('Help & Support', isTablet: isTablet),
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: _Card(
                            child: Column(
                              children: [
                                _MenuTile(
                                  icon: Icons.chat_bubble_outline,
                                  color: AppColors.info,
                                  label: 'Live Chat Support',
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text('Opening live chat...'),
                                        ),
                                      ),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.help_outline,
                                  color: AppColors.secondary,
                                  label: 'FAQs',
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text('Coming soon'),
                                        ),
                                      ),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.privacy_tip_outlined,
                                  color: AppColors.success,
                                  label: 'Privacy Policy',
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text('Coming soon'),
                                        ),
                                      ),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.description_outlined,
                                  color: AppColors.warning,
                                  label: 'Terms of Service',
                                  onTap: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text('Coming soon'),
                                        ),
                                      ),
                                ),
                                const _HDivider(),
                                _MenuTile(
                                  icon: Icons.info_outline,
                                  color: AppColors.textTertiary,
                                  label: 'App Version 2.0.0',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Sign Out ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isTablet ? 24 : 16,
                              24,
                              isTablet ? 24 : 16,
                              32,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _logout,
                                icon: const Icon(
                                  Icons.logout,
                                  color: AppColors.error,
                                ),
                                label: const Text(
                                  'Sign Out',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.error,
                                    width: 1.5,
                                  ),
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.mdAll,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends SliverToBoxAdapter {
  final String text;
  final bool isTablet;

  _SectionLabel(this.text, {this.isTablet = false})
    : super(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isTablet ? 24 : 16,
            24,
            isTablet ? 24 : 16,
            0,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      );
}

// ── Card Wrapper ──────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.surfaceVariant),
        boxShadow: AppShadows.card,
      ),
      child: ClipRRect(borderRadius: AppRadius.lgAll, child: child),
    );
  }
}

// ── Picker Row ────────────────────────────────────────────────────────────────

class _PickerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool editing;
  final VoidCallback onTap;

  const _PickerRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.editing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: editing ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.isEmpty ? '—' : value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: editing
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (editing)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Typed Row ─────────────────────────────────────────────────────────────────

class _TypedRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController ctrl;
  final bool editing;
  final String hint;

  const _TypedRow({
    required this.icon,
    required this.label,
    required this.ctrl,
    required this.editing,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningLight.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: AppColors.warning),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 4),
                if (editing)
                  TextField(
                    controller: ctrl,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    ctrl.text.isEmpty ? '—' : ctrl.text,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Picker Sheet ──────────────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback onDone;

  const _PickerSheet({
    required this.title,
    required this.child,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    onDone();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Menu Tile ─────────────────────────────────────────────────────────────────

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment Tile ──────────────────────────────────────────────────────────────

class _PaymentTile extends StatelessWidget {
  final String logo;
  final String name;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.logo,
    required this.name,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(logo, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              ?trailing,
              if (onTap != null && trailing == null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Divider ──────────────────────────────────────────────────────────────────

class _HDivider extends StatelessWidget {
  const _HDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, indent: 76, endIndent: 16);
  }
}
