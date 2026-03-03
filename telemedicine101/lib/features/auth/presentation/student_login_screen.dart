import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';

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
        setState(() => _selectedSchool = extra['school'] as String?);
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

      if (response.user != null) {
        if (_role == 'student' && _selectedSchool != null) {
          await Supabase.instance.client
              .from('profiles')
              .upsert({'id': response.user!.id, 'school': _selectedSchool})
              .select('id');
        }

        if (!mounted) return;

        // ✅ KEY FIX: defer navigation to next frame to avoid navigator dispose crash
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_role == 'doctor') {
            context.go('/doctor-dashboard');
          } else {
            context.go('/student-dashboard');
          }
        });
      } else {
        _showError('Login failed. Please check your credentials.');
        setState(() => _isLoading = false);
      }
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
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
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
    final theme = Theme.of(context);
    final isDoctor = _role == 'doctor';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Back ────────────────────────────────
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 20),
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go('/onboarding'),
                alignment: Alignment.centerLeft,
              ),

              // ── Role Selector ────────────────────────
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _RoleTab(
                      icon: Icons.school_outlined,
                      label: 'Student',
                      selected: _role == 'student',
                      onTap: () => setState(() {
                        _role = 'student';
                        _selectedSchool = null;
                      }),
                    ),
                    _RoleTab(
                      icon: Icons.medical_services_outlined,
                      label: 'Doctor',
                      selected: _role == 'doctor',
                      onTap: () => setState(() {
                        _role = 'doctor';
                        _selectedSchool = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── School Badge (students only) ─────────
              if (!isDoctor) ...[
                GestureDetector(
                  onTap: () async {
                    final school = await context.push<String>(
                      '/school-selection',
                    );
                    if (school != null && mounted) {
                      setState(() => _selectedSchool = school);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedSchool == null
                            ? const Color(0xFFDC2626).withValues(alpha: 0.4)
                            : AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedSchool ?? 'Tap to select your school',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: _selectedSchool == null
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                'Selected School',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: _selectedSchool == null
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Title ────────────────────────────────
              Text(
                isDoctor ? 'Doctor Login' : 'Student Login',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isDoctor
                    ? 'Access your doctor dashboard'
                    : 'Enter your credentials to continue',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // ── Email ────────────────────────────────
              Text('Email', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: isDoctor
                      ? 'doctor@somacare.app'
                      : 'student@somacare.app',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Password ─────────────────────────────
              Text('Password', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ── Forgot Password ───────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Contact ${_selectedSchool ?? "school"} admin for password reset',
                        ),
                      ),
                    );
                  },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 24),

              // ── Login Button ──────────────────────────
              SizedBox(
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDoctor
                        ? const Color(0xFF059669)
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isDoctor ? 'Login as Doctor' : 'Login as Student',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Test Credentials ──────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧪 Test Credentials',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF15803D),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isDoctor
                          ? 'Email: doctor1@somacare.app\nPassword: Doctor@1234'
                          : 'Email: student1@somacare.app\nPassword: Student@1234',
                      style: const TextStyle(
                        color: Color(0xFF166534),
                        fontSize: 12,
                        fontFamily: 'monospace',
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
}

// ── Role Tab ──────────────────────────────────────────────────────────────────

class _RoleTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? (label == 'Doctor'
                          ? const Color(0xFF059669)
                          : AppColors.primary)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? (label == 'Doctor'
                            ? const Color(0xFF059669)
                            : AppColors.primary)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
