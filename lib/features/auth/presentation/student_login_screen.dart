import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/bloom_components.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedSchool;
  String _role = 'student';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final extra = GoRouterState.of(context).extra;
      if (extra is Map<String, dynamic>) {
        setState(() {
          if (extra['role'] == 'doctor') _role = 'doctor';
          _selectedSchool = extra['school'] as String?;
        });
      } else if (extra is String) {
        setState(() => _selectedSchool = extra);
      }
    });
  }

  Future<void> _login() async {
    if (_role == 'student' && _selectedSchool == null) {
      _showError('Please select your school first');
      return;
    }
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter your email and password');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (response.user == null) {
        _showError('Login failed. Please check your credentials.');
        setState(() => _isLoading = false);
        return;
      }
      final userId = response.user!.id;
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();
      if (!mounted) return;
      final dbRole = (profile?['role'] as String?) ?? 'student';
      if (dbRole != _role) {
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          _showError(
              'This account is registered as a $dbRole, not a $_role.');
          setState(() => _isLoading = false);
        }
        return;
      }
      if (_role == 'student' && _selectedSchool != null) {
        await Supabase.instance.client
            .from('profiles')
            .upsert({'id': userId, 'school': _selectedSchool}).select('id');
      }
      await Supabase.instance.client
          .from('profiles')
          .upsert({'id': userId, 'role': _role}).select('id');
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_role == 'doctor') {
          context.go('/doctor-dashboard');
        } else {
          context.go('/student-dashboard');
        }
      });
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showError('Something went wrong. Please try again.');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = _role == 'doctor';

    return Scaffold(
      backgroundColor: AppColors.darkScreenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Role tab chips ─────────────────────────────────────────────
              Row(
                children: [
                  _RoleChip(
                    label: 'Student',
                    selected: !isDoctor,
                    onTap: () => setState(() {
                      _role = 'student';
                      _selectedSchool = null;
                    }),
                  ),
                  const SizedBox(width: 6),
                  _RoleChip(
                    label: 'Doctor',
                    selected: isDoctor,
                    onTap: () => setState(() {
                      _role = 'doctor';
                      _selectedSchool = null;
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Greeting ──────────────────────────────────────────────────
              Text(
                'Welcome back',
                style: TextStyle(fontFamily: 'Fraunces', 
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: AppColors.darkTextPrimary,
                ),
              ),

              const SizedBox(height: 16),

              // ── School badge (students only) ──────────────────────────────
              if (!isDoctor) ...[
                BloomCard(
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedSchool ?? 'Tap to select school',
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.darkTextPrimary),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final school =
                              await context.push<String>('/school-selection');
                          if (school != null && mounted) {
                            setState(() => _selectedSchool = school);
                          }
                        },
                        child: Text(
                          'Change',
                          style: TextStyle(fontFamily: 'Inter', 
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lime),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Email / ID field ──────────────────────────────────────────
              BloomInputField(
                label: isDoctor ? 'License / Doctor ID' : 'Email',
                hint: isDoctor ? 'UG-MD-33847' : 'student@somacare.app',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),

              // ── Password ─────────────────────────────────────────────────
              BloomInputField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffix: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 16,
                    color: AppColors.darkTextMuted,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Forgot password ───────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Contact ${_selectedSchool ?? "admin"} for password reset'),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(fontFamily: 'Inter', 
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lime),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Login button ─────────────────────────────────────────────
              BloomButton(
                label: isDoctor ? 'Log In' : 'Log In',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.darkSurface,
          borderRadius: BorderRadius.circular(999),
          border: selected
              ? null
              : Border.all(color: AppColors.darkBorder, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(fontFamily: 'Inter', 
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0x99FFFFFF),
          ),
        ),
      ),
    );
  }
}
