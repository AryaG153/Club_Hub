import 'package:flutter/material.dart';

import 'app.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Object? startupError;
  try {
    await AppConfig.load();
    await AppConfig.initializeSupabase();
  } catch (error) {
    startupError = error;
  }

  runApp(ClubHubApp(startupError: startupError));
}
