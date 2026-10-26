import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club_hub/app.dart';
import 'package:club_hub/config/app_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _hasBuildConfig =
    String.fromEnvironment('SUPABASE_URL') != '' &&
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY') != '';
const _buildUsesDemoMode =
    String.fromEnvironment('APP_MODE', defaultValue: 'live') == 'demo';

void main() {
  testWidgets(
    'compiled live configuration initializes Supabase without demo UI',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await AppConfig.load();

      expect(AppConfig.isDemoMode, isFalse);
      expect(AppConfig.hasSupabaseConfig, isTrue);

      await AppConfig.initializeSupabase();

      expect(Supabase.instance.isInitialized, isTrue);
      expect(Supabase.instance.client.auth.currentSession, isNull);

      await tester.pumpWidget(const ClubHubApp());
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('New student? Create an account'), findsOneWidget);
      expect(find.text('Development demo'), findsNothing);
      expect(find.textContaining('DEVELOPMENT DEMO'), findsNothing);

      Supabase.instance.client.auth.stopAutoRefresh();
    },
    skip: !_hasBuildConfig || _buildUsesDemoMode,
  );
}
