import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../models/clubhub_models.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onRegister,
    required this.onPasswordReset,
    required this.onToggleTheme,
    required this.isDemoMode,
  });

  final Future<AuthSession?> Function({
    required String email,
    required String password,
  })
  onLogin;
  final Future<AuthSession?> Function({
    required String email,
    required String password,
    required String displayName,
    required String department,
    required String studentId,
  })
  onRegister;
  final Future<void> Function(String email) onPasswordReset;
  final VoidCallback onToggleTheme;
  final bool isDemoMode;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _registrationSubmitted = false;

  String _errorMessage(Object error) {
    if (error is AuthException) {
      final message = error.message;
      final normalized = message.toLowerCase();
      if (normalized.contains('email not confirmed') ||
          normalized.contains('email_not_confirmed')) {
        return 'Confirm your email using the link we sent before signing in.';
      }
      if (normalized.contains('invalid login credentials')) {
        return 'Email or password is incorrect. Check your details and try again.';
      }
      if (normalized.contains('user already registered')) {
        return 'An account with this email already exists. Sign in or reset your password.';
      }
      return message;
    }
    if (error is PostgrestException) {
      return 'Supabase database error: ${error.message}';
    }
    if (error is StateError) {
      return error.message.toString();
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });
    try {
      final session = _isRegistering
          ? await widget.onRegister(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _nameController.text.trim(),
              department: _departmentController.text.trim(),
              studentId: _studentIdController.text.trim(),
            )
          : await widget.onLogin(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
      if (!mounted) return;
      if (!_isRegistering && session == null) {
        throw StateError('Email or password is incorrect.');
      }
      if (_isRegistering && session == null) {
        setState(() => _registrationSubmitted = true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your account email first.')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.onPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Row(
                  children: [
                    if (isWide)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          color: colorScheme.primary.withValues(alpha: 0.95),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.school_rounded,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'ClubHub',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Connect students with clubs, events, and campus life.',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                if (widget.isDemoMode) ...[
                                  const _InfoPill(
                                    label: 'Development demo',
                                    detail: 'Student: student / student123',
                                  ),
                                  const SizedBox(height: 16),
                                  const _InfoPill(
                                    label: 'Development demo',
                                    detail: 'Admin: admin / admin123',
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, panelConstraints) => SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: panelConstraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWide ? 48 : 22,
                                  vertical: 32,
                                ),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 480,
                                  ),
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        _isRegistering
                                                            ? 'Create your account'
                                                            : 'Welcome back',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .headlineSmall,
                                                      ),
                                                      Text(
                                                        _isRegistering
                                                            ? 'Register with your student email'
                                                            : 'Sign in to your club portal',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed:
                                                      widget.onToggleTheme,
                                                  icon: Icon(
                                                    isDark
                                                        ? Icons.light_mode
                                                        : Icons
                                                              .dark_mode_rounded,
                                                  ),
                                                  tooltip: 'Toggle theme',
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 20),
                                            if (_isRegistering) ...[
                                              TextFormField(
                                                controller: _nameController,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Full name',
                                                      prefixIcon: Icon(
                                                        Icons.badge_outlined,
                                                      ),
                                                    ),
                                                validator: (value) =>
                                                    _isRegistering &&
                                                        (value == null ||
                                                            value
                                                                    .trim()
                                                                    .length <
                                                                2)
                                                    ? 'Enter your full name.'
                                                    : _isRegistering &&
                                                          value!.trim().length >
                                                              120
                                                    ? 'Name must be 120 characters or fewer.'
                                                    : null,
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller:
                                                    _departmentController,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText: 'Department (optional)',
                                                      prefixIcon: Icon(
                                                        Icons.school_outlined,
                                                      ),
                                                    ),
                                              ),
                                              const SizedBox(height: 16),
                                              TextFormField(
                                                controller:
                                                    _studentIdController,
                                                decoration: const InputDecoration(
                                                  labelText:
                                                      'Student ID (optional)',
                                                  prefixIcon: Icon(
                                                    Icons
                                                        .confirmation_number_outlined,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            if (_registrationSubmitted) ...[
                                              MaterialBanner(
                                                content: Text(
                                                  'Account request submitted for ${_emailController.text.trim()}. Check your email to confirm your account before signing in. In Supabase, verify it under Authentication → Users and Table Editor → profiles.',
                                                ),
                                                leading: const Icon(
                                                  Icons
                                                      .mark_email_read_outlined,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => setState(
                                                      () =>
                                                          _registrationSubmitted =
                                                              false,
                                                    ),
                                                    child: const Text(
                                                      'Dismiss',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            TextFormField(
                                              controller: _emailController,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              autofillHints: const [
                                                AutofillHints.email,
                                              ],
                                              decoration: InputDecoration(
                                                labelText: widget.isDemoMode
                                                    ? 'Demo username or email'
                                                    : 'Email',
                                                hintText: widget.isDemoMode
                                                    ? 'student or admin'
                                                    : 'you@example.com',
                                                prefixIcon: Icon(
                                                  Icons.person_outline_rounded,
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    !(widget.isDemoMode
                                                        ? const {
                                                            'student',
                                                            'admin',
                                                          }.contains(
                                                            value.trim(),
                                                          )
                                                        : RegExp(
                                                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                                          ).hasMatch(
                                                            value.trim(),
                                                          ))) {
                                                  return 'Enter a valid email address.';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 20),
                                            TextFormField(
                                              controller: _passwordController,
                                              obscureText: !_isPasswordVisible,
                                              autofillHints: _isRegistering
                                                  ? const [
                                                      AutofillHints.newPassword,
                                                    ]
                                                  : const [
                                                      AutofillHints.password,
                                                    ],
                                              decoration: InputDecoration(
                                                labelText: 'Password',
                                                hintText: 'Enter password',
                                                prefixIcon: const Icon(
                                                  Icons.lock_outline_rounded,
                                                ),
                                                suffixIcon: IconButton(
                                                  onPressed: () => setState(
                                                    () => _isPasswordVisible =
                                                        !_isPasswordVisible,
                                                  ),
                                                  icon: Icon(
                                                    _isPasswordVisible
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                  ),
                                                ),
                                              ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.length < 8) {
                                                  return 'Use a password with at least 8 characters.';
                                                }
                                                return null;
                                              },
                                            ),
                                            const SizedBox(height: 22),
                                            FilledButton.icon(
                                              onPressed: _isLoading
                                                  ? null
                                                  : _submitLogin,
                                              icon: _isLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.login_rounded,
                                                    ),
                                              label: Text(
                                                _isLoading
                                                    ? (_isRegistering
                                                          ? 'Creating account...'
                                                          : 'Signing in...')
                                                    : (_isRegistering
                                                          ? 'Create account'
                                                          : 'Login'),
                                              ),
                                              style: FilledButton.styleFrom(
                                                minimumSize:
                                                    const Size.fromHeight(52),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                            if (!_isRegistering &&
                                                !widget.isDemoMode)
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _resetPassword,
                                                  child: Text(
                                                    'Forgot password?',
                                                  ),
                                                ),
                                              ),
                                            TextButton(
                                              onPressed: _isLoading
                                                  ? null
                                                  : () => setState(() {
                                                      _isRegistering =
                                                          !_isRegistering;
                                                      _registrationSubmitted =
                                                          false;
                                                    }),
                                              child: Text(
                                                _isRegistering
                                                    ? 'Already registered? Sign in'
                                                    : 'New student? Create an account',
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: AppTheme.softBlue
                                                    .withValues(alpha: 0.35),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                widget.isDemoMode
                                                    ? 'Development demo mode: accounts are temporary and are not saved. Configure Supabase to enable real registration and persistent accounts.'
                                                    : 'Authentication and profile creation use your configured Supabase project.',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
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
            );
          },
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.detail});

  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
