import '../config/app_config.dart';
import 'auth_service.dart';
import 'supabase_auth_service.dart';

class AppAuthService {
  const AppAuthService({this.demoModeOverride});

  final bool? demoModeOverride;

  bool get _isDemoMode => demoModeOverride ?? AppConfig.isDemoMode;

  void _requireLiveConfig() {
    if (!AppConfig.hasSupabaseConfig) {
      throw StateError(
        'Live mode is selected, but Supabase URL or publishable key is '
        'missing or invalid. Configure the project URL and publishable key '
        'before continuing.',
      );
    }
  }

  Future<AuthSession?> login({
    required String email,
    required String password,
  }) async {
    if (_isDemoMode) {
      return const DemoAuthService().login(username: email, password: password);
    }
    _requireLiveConfig();
    return const SupabaseAuthService().signInWithEmail(
      email: email,
      password: password,
    );
  }

  Future<AuthSession?> register({
    required String email,
    required String password,
    required String displayName,
    String? department,
    String? studentId,
  }) {
    if (_isDemoMode) {
      throw StateError(
        'Registration is unavailable in demo mode. Set APP_MODE=live and '
        'configure Supabase to create real accounts.',
      );
    }
    _requireLiveConfig();
    return const SupabaseAuthService().register(
      email: email,
      password: password,
      displayName: displayName,
      department: department,
      studentId: studentId,
    );
  }

  Future<void> sendPasswordReset(String email) {
    if (_isDemoMode) {
      throw StateError(
        'Password reset is unavailable in demo mode. Set APP_MODE=live and '
        'configure Supabase to reset real accounts.',
      );
    }
    _requireLiveConfig();
    return const SupabaseAuthService().sendPasswordReset(email);
  }

  Future<void> updatePassword(String password) {
    if (_isDemoMode) {
      throw StateError(
        'Password recovery is unavailable in demo mode. Set APP_MODE=live '
        'and configure Supabase to update a real account.',
      );
    }
    _requireLiveConfig();
    return const SupabaseAuthService().updatePassword(password);
  }

  Future<AuthSession?> restoreSession() async {
    if (_isDemoMode) {
      return null;
    }
    _requireLiveConfig();
    return const SupabaseAuthService().restoreSession();
  }

  Future<void> logout() async {
    if (_isDemoMode) {
      return;
    }
    _requireLiveConfig();
    await const SupabaseAuthService().signOut();
  }
}
