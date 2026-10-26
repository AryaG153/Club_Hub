import 'package:flutter_test/flutter_test.dart';
import 'package:club_hub/data/demo_repository.dart';
import 'package:club_hub/config/app_config.dart';
import 'package:club_hub/services/auth_service.dart';
import 'package:club_hub/services/app_auth_service.dart';
import 'package:club_hub/services/supabase_auth_service.dart';

void main() {
  group('Demo auth flow', () {
    test('student demo login grants student role', () {
      final auth = DemoAuthService();

      final session = auth.login(username: 'student', password: 'student123');

      expect(session, isNotNull);
      expect(session!.role, UserRole.student);
      expect(session.username, 'student');
    });

    test('Supabase registration metadata matches profile trigger fields', () {
      final metadata = SupabaseAuthService.registrationMetadata(
        displayName: '  Test Student ',
        department: ' Computer Engineering ',
        studentId: ' FCRIT-123 ',
      );

      expect(metadata, {
        'full_name': 'Test Student',
        'department': 'Computer Engineering',
        'student_id': 'FCRIT-123',
      });
      expect(metadata.containsKey('password'), isFalse);
      expect(metadata.containsKey('role'), isFalse);
    });

    test('admin demo login grants admin role', () {
      final auth = DemoAuthService();

      final session = auth.login(username: 'admin', password: 'admin123');

      expect(session, isNotNull);
      expect(session!.role, UserRole.admin);
      expect(session.username, 'admin');
    });

    test('invalid demo credentials return null and do not route', () {
      final auth = DemoAuthService();

      final session = auth.login(username: 'student', password: 'wrong');

      expect(session, isNull);
    });
  });

  group('Demo repository', () {
    test('FinTech sample is unique and labelled as a past event', () {
      final repo = ClubHubDemoRepository();
      final sample = repo.announcements.singleWhere(
        (item) => item.slug == 'fintech-unlocked-2026',
      );

      expect(sample.category, 'Event Announcement');
      expect(sample.source, 'E-Cell FCRIT');
      expect(sample.publishedAt, DateTime(2026, 10, 22));
      expect(
        repo.clubs
            .singleWhere((club) => club.id == 'club-e-cell')
            .needsAdminReview,
        isTrue,
      );
    });

    test('club CRUD updates shared in-memory state', () async {
      final repo = ClubHubDemoRepository();

      final club = await repo.createClub(
        name: 'Debate Club',
        description: 'Public speaking and argument analysis',
        category: 'Academic',
      );

      expect(repo.clubs.any((item) => item.id == club.id), isTrue);

      await repo.deleteClub(club.id);

      expect(repo.clubs.any((item) => item.id == club.id), isFalse);
    });

    test('profile updates preserve the assigned role', () async {
      final repo = ClubHubDemoRepository(
        session: const AuthSession(
          id: 'student-id',
          username: 'student',
          displayName: 'Original Name',
          role: UserRole.student,
        ),
      );

      await repo.updateProfile(
        displayName: 'Updated Name',
        department: 'Computer Engineering',
        studentId: 'FCRIT-123',
      );

      expect(repo.studentProfile.displayName, 'Updated Name');
      expect(repo.studentProfile.department, 'Computer Engineering');
      expect(repo.studentProfile.studentId, 'FCRIT-123');
      expect(repo.studentProfile.role, 'student');
    });

    test('live repository starts empty until Supabase data is loaded', () {
      final repo = ClubHubDemoRepository(
        session: const AuthSession(
          id: 'authenticated-user',
          username: 'student',
          displayName: 'Test Student',
          role: UserRole.student,
        ),
        useSupabase: true,
      );

      expect(repo.isLive, isTrue);
      expect(repo.clubs, isEmpty);
      expect(repo.events, isEmpty);
      expect(repo.announcements, isEmpty);
    });

    test(
      'event registrations prevent duplicates and allow cancellation',
      () async {
        final repo = ClubHubDemoRepository();
        final event = repo.events.firstWhere(
          (item) => !repo.isEventRegistered(item.id),
        );

        expect(repo.isEventRegistered(event.id), isFalse);

        await repo.toggleEventRegistration(event.id);
        expect(repo.isEventRegistered(event.id), isTrue);

        await repo.toggleEventRegistration(event.id);
        expect(repo.isEventRegistered(event.id), isFalse);
      },
    );
  });

  test(
    'registration cannot silently fall back without Supabase config',
    () async {
      await AppConfig.load();
      if (!AppConfig.hasSupabaseConfig) {
        expect(
          () => const AppAuthService().register(
            email: 'student@example.com',
            password: 'password123',
            displayName: 'Test Student',
          ),
          throwsStateError,
        );
      }
    },
  );

  test('live login never accepts demo credentials without Supabase config', () {
    if (AppConfig.isDemoMode || AppConfig.hasSupabaseConfig) return;

    expect(
      const AppAuthService().login(email: 'student', password: 'student123'),
      throwsA(isA<StateError>()),
    );
  });
}
