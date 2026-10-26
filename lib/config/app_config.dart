import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env_loader.dart';

class AppConfig {
  static const String _appMode = String.fromEnvironment(
    'APP_MODE',
    defaultValue: 'live',
  );
  static const String _buildSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
  );
  static const String _buildSupabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static final Map<String, String> _runtimeEnv = <String, String>{};

  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
    _runtimeEnv.clear();
    final fileEnv = await loadRuntimeEnv();
    _runtimeEnv.addAll(fileEnv);
    for (final entry in _runtimeEnv.entries) {
      dotenv.env[entry.key] = entry.value;
    }
  }

  static String _valueFor(String key, String buildValue) {
    if (buildValue.isNotEmpty) {
      return buildValue;
    }
    return dotenv.env[key] ?? _runtimeEnv[key] ?? '';
  }

  static String get supabaseUrl =>
      _valueFor('SUPABASE_URL', _buildSupabaseUrl);
  static String get supabasePublishableKey =>
      _valueFor('SUPABASE_PUBLISHABLE_KEY', _buildSupabasePublishableKey);

  static bool get isDemoMode => _appMode == 'demo';

  static bool get hasSupabaseConfig {
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null &&
        uri.scheme == 'https' &&
        uri.host.endsWith('.supabase.co') &&
        supabasePublishableKey.startsWith('sb_publishable_');
  }

  static Future<void> initializeSupabase() async {
    if (isDemoMode) {
      return;
    }
    if (_appMode != 'live') {
      throw StateError('APP_MODE must be either "live" or "demo".');
    }
    if (!hasSupabaseConfig) {
      throw StateError(
        'Live mode requires SUPABASE_URL and a Supabase publishable key. '
        'Copy the project URL and key from Supabase Dashboard → '
        'Project Settings → API Keys, then set them in .env.json and run '
        'with --dart-define-from-file=.env.json. For a local-only demo, '
        'explicitly set APP_MODE=demo.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(persistSession: true),
    );
  }
}
