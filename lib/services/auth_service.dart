export '../models/clubhub_models.dart';

import '../models/clubhub_models.dart';

class DemoAuthService {
  const DemoAuthService();

  AuthSession? login({required String username, required String password}) {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    final match = _demoUsers[normalizedUsername];
    if (match == null) {
      return null;
    }

    if (match['password'] != normalizedPassword) {
      return null;
    }

    final role = match['role'] as UserRole;

    return AuthSession(
      username: normalizedUsername,
      displayName: match['displayName'] as String,
      role: role,
    );
  }

  static const Map<String, Map<String, Object>> _demoUsers = {
    'student': {
      'password': 'student123',
      'displayName': 'Maya Patel',
      'role': UserRole.student,
    },
    'admin': {
      'password': 'admin123',
      'displayName': 'Alicia Morgan',
      'role': UserRole.admin,
    },
  };
}
