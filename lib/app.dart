import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'data/demo_repository.dart';
import 'features/admin/admin_shell.dart';
import 'features/auth/login_screen.dart';
import 'features/student/student_shell.dart';
import 'models/clubhub_models.dart';
import 'services/app_auth_service.dart';

class ClubHubApp extends StatefulWidget {
  const ClubHubApp({super.key, this.startupError, this.demoModeOverride});

  final Object? startupError;
  final bool? demoModeOverride;

  @override
  State<ClubHubApp> createState() => _ClubHubAppState();
}

class _ClubHubAppState extends State<ClubHubApp> {
  late final AppAuthService _authService = AppAuthService(
    demoModeOverride: widget.demoModeOverride,
  );
  ClubHubDemoRepository _repository = ClubHubDemoRepository();
  ThemeMode _themeMode = ThemeMode.light;
  AuthSession? _session;
  bool _isInitializing = false;
  Object? _initializationError;

  bool get _isDemoMode => widget.demoModeOverride ?? AppConfig.isDemoMode;

  Future<AuthSession?> _login({
    required String email,
    required String password,
  }) async {
    final session = await _authService.login(email: email, password: password);
    if (session != null) {
      final repository = _repositoryFor(session);
      await repository.load();
      if (mounted) {
        setState(() {
          _repository = repository;
          _session = session;
        });
      }
    }
    return session;
  }

  Future<AuthSession?> _register({
    required String email,
    required String password,
    required String displayName,
    required String department,
    required String studentId,
  }) async {
    final session = await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
      department: department,
      studentId: studentId,
    );
    if (session != null) {
      final repository = _repositoryFor(session);
      await repository.load();
      if (mounted) {
        setState(() {
          _repository = repository;
          _session = session;
        });
      }
    }
    return session;
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) {
      return;
    }
    setState(() {
      _repository = ClubHubDemoRepository();
      _session = null;
    });
  }

  ClubHubDemoRepository _repositoryFor(AuthSession session) =>
      ClubHubDemoRepository(session: session, useSupabase: !_isDemoMode);

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializationError = widget.startupError;
    _isInitializing = widget.startupError == null && !_isDemoMode;
    if (widget.startupError != null) return;
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    if (_isDemoMode) {
      return;
    }

    try {
      final session = await _authService.restoreSession();
      final repository = session == null ? null : _repositoryFor(session);
      await repository?.load();
      if (!mounted) return;
      setState(() {
        _session = session;
        if (repository != null) _repository = repository;
        _isInitializing = false;
        _initializationError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initializationError = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClubHub',
      themeMode: _themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: _isInitializing
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _initializationError != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.startupError == null
                            ? 'Could not restore your account session.'
                            : 'Supabase configuration could not be initialized. Correct the public URL/key and restart the app.',
                      ),
                      const SizedBox(height: 8),
                      Text(_initializationError.toString()),
                      if (widget.startupError == null) ...[
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _isInitializing = true;
                            _initializationError = null;
                            _initializeSession();
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
          : _session == null
          ? LoginScreen(
              onLogin: _login,
              onRegister: _register,
              onPasswordReset: _authService.sendPasswordReset,
              onToggleTheme: _toggleTheme,
              isDemoMode: _isDemoMode,
            )
          : _session!.role == UserRole.student
          ? StudentShell(
              session: _session!,
              repository: _repository,
              onLogout: _logout,
              onToggleTheme: _toggleTheme,
            )
          : AdminShell(
              session: _session!,
              repository: _repository,
              onLogout: _logout,
              onToggleTheme: _toggleTheme,
            ),
    );
  }
}
