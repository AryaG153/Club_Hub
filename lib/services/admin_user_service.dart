import 'package:supabase_flutter/supabase_flutter.dart';

class AdminUserService {
  const AdminUserService();

  Future<void> inviteUser({
    required String email,
    required String displayName,
  }) async {
    await _invoke({
      'action': 'invite-user',
      'email': email.trim(),
      'displayName': displayName.trim(),
    });
  }

  Future<void> setRole({required String userId, required String role}) async {
    await _invoke({'action': 'set-role', 'targetUserId': userId, 'role': role});
  }

  Future<void> setSuspended({
    required String userId,
    required bool suspended,
  }) async {
    await _invoke({
      'action': suspended ? 'suspend' : 'restore',
      'targetUserId': userId,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _invoke({'action': 'delete-user', 'targetUserId': userId});
  }

  Future<void> _invoke(Map<String, Object?> body) async {
    final response = await Supabase.instance.client.functions.invoke(
      'clubhub-admin',
      body: body,
    );
    if (response.status < 200 || response.status >= 300) {
      final details = response.data;
      final message = details is Map<String, dynamic>
          ? details['error'] as String? ?? 'Admin action failed.'
          : 'Admin action failed.';
      throw StateError(message);
    }
  }
}
