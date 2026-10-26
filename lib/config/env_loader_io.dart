import 'dart:convert';
import 'dart:io';

Future<Map<String, String>> loadRuntimeEnvImpl() async {
  final env = <String, String>{};
  final file = File('.env.json');
  if (!await file.exists()) {
    return env;
  }

  try {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return env;
    }

    for (final entry in decoded.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) {
        env[key] = value;
      }
    }
  } on FormatException {
    return env;
  } on FileSystemException {
    return env;
  }

  return env;
}
