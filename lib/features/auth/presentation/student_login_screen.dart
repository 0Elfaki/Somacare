import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/app_ui.dart';

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
      // The role is deliberately NOT written back here. It was redundant —
      // the check above has already established that the row's role equals
      // `_role` — and a client-writable role column is a privilege-escalation
      // path. The migration now pins profiles.role with a BEFORE UPDATE
      // trigger, so this write would silently no-op anyway.
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
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: ConstrainedBox(
              // Keeps the form from stretching edge-to-edge on wide screens
              // (tablets) while still filling the width naturally on phones.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / brand mark ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.accent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.local_hospital_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SomaCare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Fraunces',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Card ────────────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Role switcher ──────────────────────────────────────
                        // Full width, two equal halves. The old pill chips hugged
                        // their labels, so "Student" and "Doctor" were different
                        // widths and the pair floated at the card's left edge.
                        AppSegmentedControl(
                          segments: const ['Student', 'Doctor'],
                          selectedIndex: isDoctor ? 1 : 0,
                          onChanged: (i) => setState(() {
                            _role = i == 1 ? 'doctor' : 'student';
                            _selectedSchool = null;
                          }),
                        ),

                        const SizedBox(height: 16),

                        // ── Greeting ────────────────────────────────────────────
                        Text(
                          'Welcome back',
                          style: BloomTextStyles.inter(
                            size: 22,
                            weight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isDoctor
                              ? 'Log in with your doctor credentials'
                              : 'Log in to continue to your school',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── School badge (students only) ─────────────────────────
                        if (!isDoctor) ...[
                          GestureDetector(
                            onTap: () async {
                              final school = await context
                                  .push<String>('/school-selection');
                              if (school != null && mounted) {
                                setState(() => _selectedSchool = school);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.pageBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      Icons.school_rounded,
                                      size: 19,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'School',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          _selectedSchool ??
                                              'Tap to select school',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedSchool != null
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // ── Email / ID field ──────────────────────────────────────
                        _LoginField(
                          label: isDoctor ? 'License / Doctor ID' : 'Email',
                          hint: isDoctor ? 'UG-MD-33847' : 'student@somacare.app',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),

                        // ── Password ─────────────────────────────────────────────
                        _LoginField(
                          label: 'Password',
                          hint: 'Enter your password',
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Forgot password ───────────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Contact ${_selectedSchool ?? "admin"} for password reset',
                                  ),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // ── Login button ─────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
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
        ),
      ),
    );
  }
}

/// Clean, standard-looking text field for login — label above, boxed
/// input, no extra visual noise. Deliberately simple rather than heavily
/// styled, per request.
class _LoginField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffix;

  const _LoginField({
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    // Local copy: `suffix` is a public field, so it does not get null
    // promotion inside the conditional below.
    final Widget? suffixWidget = suffix;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        // One border, drawn by the field itself. This used to be a bordered
        // Container wrapping a field that drew its own outline on focus —
        // two stacked rounded rectangles, slightly out of register.
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: BloomTextStyles.inter(
            size: 14,
            color: AppColors.textPrimary,
          ),
          decoration: appInputDecoration(
            hintText: hint ?? '',
            // The login card is already white; a white field on it reads as
            // one flat surface.
            fillColor: AppColors.pageBg,
            suffixIcon: suffixWidget == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffixWidget,
                  ),
          ),
        ),
      ],
    );
  }
}
