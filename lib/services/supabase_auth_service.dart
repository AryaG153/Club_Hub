import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/clubhub_models.dart';

class SupabaseAuthService {
  const SupabaseAuthService();

  static Map<String, Object> registrationMetadata({
    required String displayName,
    String? department,
    String? studentId,
  }) => {
    'full_name': displayName.trim(),
    if (department != null && department.trim().isNotEmpty)
      'department': department.trim(),
    if (studentId != null && studentId.trim().isNotEmpty)
      'student_id': studentId.trim(),
  };

  Future<AuthSession?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    return user == null ? null : _sessionForUser(user);
  }

  Future<AuthSession?> register({
    required String email,
    required String password,
    required String displayName,
    String? department,
    String? studentId,
  }) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email.trim(),
      password: password,
      data: registrationMetadata(
        displayName: displayName,
        department: department,
        studentId: studentId,
      ),
    );

    final user = response.user;
    if (user == null) {
      throw StateError('Registration did not return a user. Please try again.');
    }
    if (user.identities?.isEmpty ?? false) {
      throw StateError(
        'An account with this email may already exist. Try signing in or use password reset.',
      );
    }
    if (response.session == null) {
      return null;
    }
    return _sessionForUser(user);
  }

  Future<void> sendPasswordReset(String email) async {
    await Supabase.instance.client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AuthSession?> restoreSession() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || Supabase.instance.client.auth.currentSession == null) {
      return null;
    }
    return _sessionForUser(user);
  }

  Future<void> signOut() => Supabase.instance.client.auth.signOut();

  Future<AuthSession> _sessionForUser(User user) async {
    final profile = await Supabase.instance.client
        .from('profiles')
        .select('username, display_name, role')
        .eq('id', user.id)
        .maybeSingle();
    if (profile == null) {
      throw StateError(
        'Your account profile is missing. Contact a ClubHub administrator.',
      );
    }

    final role = switch (profile['role']) {
      'admin' => UserRole.admin,
      'student' => UserRole.student,
      _ => throw StateError('Your account has an unsupported role.'),
    };
    return AuthSession(
      id: user.id,
      username: (profile['username'] as String?) ?? user.email ?? user.id,
      displayName: profile['display_name'] as String,
      role: role,
    );
  }
}
