import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:club_hub/app.dart';
import 'package:club_hub/config/app_config.dart';
import 'package:club_hub/features/auth/login_screen.dart';

void main() {
  setUpAll(AppConfig.load);

  testWidgets('student can sign in using demo credentials', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClubHubApp(demoModeOverride: true));

    expect(find.text('Welcome back'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'student');
    await tester.enterText(find.byType(TextFormField).at(1), 'student123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Maya Patel'), findsOneWidget);
    expect(
      find.textContaining('DEVELOPMENT DEMO — data is temporary'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('FinTech Unlocked 2026'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('FinTech Unlocked 2026'), findsOneWidget);

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();
    expect(find.text('Past event • Sample'), findsOneWidget);
    expect(find.textContaining('Thursday, 22nd October 2026'), findsOneWidget);
  });

  testWidgets('registration validates fields before submit', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClubHubApp(demoModeOverride: true));

    await tester.tap(find.text('New student? Create an account'));
    await tester.pump();
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pump();

    expect(find.text('Enter your full name.'), findsOneWidget);
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.text('Use a password with at least 8 characters.'),
      findsOneWidget,
    );
  });

  testWidgets('registration submits department and student ID', (
    WidgetTester tester,
  ) async {
    Map<String, String>? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          isDemoMode: false,
          onLogin: ({required email, required password}) async => null,
          onRegister:
              ({
                required email,
                required password,
                required displayName,
                required department,
                required studentId,
              }) async {
                submitted = {
                  'email': email,
                  'password': password,
                  'displayName': displayName,
                  'department': department,
                  'studentId': studentId,
                };
                return null;
              },
          onPasswordReset: (_) async {},
          onToggleTheme: () {},
        ),
      ),
    );

    await tester.tap(find.text('New student? Create an account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Test Student');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Computer Engineering',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'FCRIT-123');
    await tester.enterText(
      find.byType(TextFormField).at(3),
      'test.student@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(4), 'password123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(submitted, {
      'email': 'test.student@example.com',
      'password': 'password123',
      'displayName': 'Test Student',
      'department': 'Computer Engineering',
      'studentId': 'FCRIT-123',
    });
    expect(find.textContaining('Check your email to confirm'), findsOneWidget);
  });

  testWidgets('admin club management fits a narrow mobile viewport', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ClubHubApp(demoModeOverride: true));
    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clubs').last);
    await tester.pumpAndSettle();

    expect(find.text('Club Management'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student can update profile fields without changing their role', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClubHubApp(demoModeOverride: true));
    await tester.enterText(find.byType(TextFormField).at(0), 'student');
    await tester.enterText(find.byType(TextFormField).at(1), 'student123');
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Maya Updated');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Computer Engineering',
    );
    await tester.enterText(find.byType(TextFormField).at(2), 'FCRIT-123');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Maya Updated'), findsOneWidget);
    expect(find.text('Department: Computer Engineering'), findsOneWidget);
    expect(find.text('Student ID: FCRIT-123'), findsOneWidget);
    expect(find.text('@student • Student'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
