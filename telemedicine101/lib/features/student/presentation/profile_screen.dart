import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
          _bloodType = data?['blood_type'] ?? 'A+';
          final bp = (data?['blood_pressure'] ?? '120/80').toString();
          final parts = bp.split('/');
          _systolic = int.tryParse(parts.isNotEmpty ? parts[0] : '120') ?? 120;
          _diastolic = int.tryParse(parts.length > 1 ? parts[1] : '80') ?? 80;
          _allergiesCtrl.text = data?['allergies'] ?? '';
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
            backgroundColor: Color(0xFF22C55E),
          ),
        );
        _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to save: $e'),
            backgroundColor: const Color(0xFFDC2626),
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
                  color: const Color(0xFFCBD5E1),
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
                        color: Color(0xFF0F172A),
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
                          color: Color(0xFF3B82F6),
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
                            color: Color(0xFF64748B),
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
                            color: Color(0xFF64748B),
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
                        color: Color(0xFF0F172A),
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
                  color: const Color(0xFFCBD5E1),
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
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: hint,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
                  color: const Color(0xFFCBD5E1),
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
                color: Color(0xFF0F172A),
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
                      backgroundColor: Color(0xFF1A56DB),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56DB),
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
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1A56DB), width: 2),
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
                  color: const Color(0xFFCBD5E1),
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
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFD97706),
                    width: 2,
                  ),
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
                          backgroundColor: Color(0xFF22C55E),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ $e'),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
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

  // ── Delete Account ────────────────────────────────────────────────────────
  void _confirmDeleteAccount(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all data. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await Supabase.instance.client.auth.signOut();
              if (mounted) context.go('/onboarding');
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
              style: TextStyle(color: Color(0xFFDC2626)),
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
    final name = _profile?['full_name'] ?? user?.email ?? 'Student';
    final email = user?.email ?? '';
    final school = _profile?['school'] ?? 'University';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF5B8CFF), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      28,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
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
                                size: 48,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 14,
                                  color: Color(0xFF5B8CFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            school,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
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
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
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
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _isEditing
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isEditing ? Icons.check : Icons.edit,
                                  size: 14,
                                  color: _isEditing
                                      ? Colors.white
                                      : const Color(0xFF3B82F6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isEditing ? 'Save' : 'Edit',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _isEditing
                                        ? Colors.white
                                        : const Color(0xFF3B82F6),
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

                // ── Quick Access ─────────────────────────
                _SectionLabel('Quick Access'),
                SliverToBoxAdapter(
                  child: _Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.calendar_today_outlined,
                          color: const Color(0xFF3B82F6),
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
                          color: const Color(0xFFD97706),
                          label: 'My Medical History',
                          onTap: () => context.push('/medical-history'),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.medication_outlined,
                          color: const Color(0xFF7C3AED),
                          label: 'My Medications',
                          onTap: () => context.push('/my-medications'),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.description_outlined,
                          color: const Color(0xFF059669),
                          label: 'My Records',
                          onTap: () => context.push('/records'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Payment Methods ───────────────────────
                _SectionLabel('Payment Methods'),
                SliverToBoxAdapter(
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
                          color: const Color(0xFF1A56DB),
                          onTap: () => _showCardSheet(context),
                        ),
                        const _HDivider(),
                        _PaymentTile(
                          logo: '🏦',
                          name: 'Bank Transfer',
                          subtitle: 'Stanbic · DFCU · Centenary Bank',
                          color: const Color(0xFF059669),
                          onTap: () => _showPaymentSheet(
                            context,
                            'Bank Transfer',
                            'Enter bank account number',
                            const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Settings ──────────────────────────────
                _SectionLabel('Settings'),
                SliverToBoxAdapter(
                  child: _Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          color: const Color(0xFF3B82F6),
                          trailing: Switch(
                            value: _notificationsEnabled,
                            activeThumbColor: const Color(0xFF3B82F6),
                            onChanged: (v) =>
                                setState(() => _notificationsEnabled = v),
                          ),
                        ),
                        const _HDivider(),
                        _SettingsTile(
                          icon: Icons.dark_mode_outlined,
                          label: 'Dark Mode',
                          color: const Color(0xFF7C3AED),
                          trailing: Switch(
                            value: _darkMode,
                            activeThumbColor: const Color(0xFF7C3AED),
                            onChanged: (v) => setState(() => _darkMode = v),
                          ),
                        ),
                        const _HDivider(),
                        _SettingsTile(
                          icon: Icons.language_outlined,
                          label: 'Language',
                          color: const Color(0xFF059669),
                          trailing: DropdownButton<String>(
                            value: _language,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
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
                            onChanged: (v) =>
                                setState(() => _language = v ?? 'English'),
                          ),
                        ),
                        const _HDivider(),
                        _SettingsTile(
                          icon: Icons.lock_outline,
                          label: 'Change Password',
                          color: const Color(0xFFD97706),
                          onTap: () => _showChangePasswordSheet(context),
                        ),
                        const _HDivider(),
                        _SettingsTile(
                          icon: Icons.delete_outline,
                          label: 'Delete Account',
                          color: const Color(0xFFDC2626),
                          labelColor: const Color(0xFFDC2626),
                          onTap: () => _confirmDeleteAccount(context),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Help & Support ────────────────────────
                _SectionLabel('Help & Support'),
                SliverToBoxAdapter(
                  child: _Card(
                    child: Column(
                      children: [
                        _MenuTile(
                          icon: Icons.chat_bubble_outline,
                          color: const Color(0xFF3B82F6),
                          label: 'Live Chat Support',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Opening live chat...'),
                                ),
                              ),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.help_outline,
                          color: const Color(0xFF7C3AED),
                          label: 'FAQs',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coming soon')),
                              ),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.privacy_tip_outlined,
                          color: const Color(0xFF059669),
                          label: 'Privacy Policy',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coming soon')),
                              ),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.description_outlined,
                          color: const Color(0xFFD97706),
                          label: 'Terms of Service',
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Coming soon')),
                              ),
                        ),
                        const _HDivider(),
                        _MenuTile(
                          icon: Icons.info_outline,
                          color: const Color(0xFF64748B),
                          label: 'App Version 1.0.0',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Sign Out ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFDC2626),
                        ),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w800,
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
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends SliverToBoxAdapter {
  _SectionLabel(String text)
    : super(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
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
    return InkWell(
      onTap: editing ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF475569),
                ),
              ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    value.isEmpty ? '—' : value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: editing
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  if (editing) ...[
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.expand_more,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ],
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: editing
                ? TextField(
                    controller: ctrl,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                    ),
                  )
                : Text(
                    ctrl.text.isEmpty ? '—' : ctrl.text,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.right,
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
              color: const Color(0xFFCBD5E1),
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
                    color: Color(0xFF0F172A),
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
                      color: Color(0xFF3B82F6),
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(logo, style: const TextStyle(fontSize: 20))),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Link',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
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
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: labelColor ?? const Color(0xFF0F172A),
        ),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1))
              : null),
    );
  }
}

// ── Divider ───────────────────────────────────────────────────────────────────

class _HDivider extends StatelessWidget {
  const _HDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}
