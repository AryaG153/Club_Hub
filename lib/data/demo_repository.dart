import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/clubhub_models.dart';

class ClubHubDemoRepository extends ChangeNotifier {
  ClubHubDemoRepository({AuthSession? session, this._useSupabase = false})
    : _session = session {
    if (_useSupabase) {
      _clubs.clear();
      _events.clear();
      _announcements.clear();
    }
    _studentProfile = const StudentProfile(
      username: 'student',
      displayName: 'Maya Patel',
      email: 'maya.patel@college.edu',
      joinedClubIds: ['club-coding', 'club-culture', 'club-sports'],
      registeredEventIds: ['event-robotics', 'event-gala'],
    );
    if (session != null) {
      _studentProfile = StudentProfile(
        id: session.id,
        username: session.username,
        displayName: session.displayName,
        email: session.username,
        joinedClubIds: const [],
        registeredEventIds: const [],
        role: session.role.name,
      );
    }
  }

  final AuthSession? _session;
  final bool _useSupabase;
  late StudentProfile _studentProfile;
  final List<StudentProfile> _liveStudents = [];
  int _liveRegistrationsCount = 0;
  bool get isLive => _useSupabase;

  final List<Club> _clubs = [
    Club(
      id: 'club-coding',
      name: 'Coding Club',
      description:
          'Build projects, learn DSA, and sharpen your coding confidence.',
      category: 'Technology',
      icon: '💻',
      membershipCount: 214,
      featured: true,
    ),
    Club(
      id: 'club-robotics',
      name: 'Robotics Club',
      description:
          'Design robot builds, automations, and competition-ready prototypes.',
      category: 'STEM',
      icon: '🤖',
      membershipCount: 164,
      featured: true,
    ),
    Club(
      id: 'club-culture',
      name: 'Cultural Club',
      description:
          'Celebrate art, music, dance, and campus traditions together.',
      category: 'Arts',
      icon: '🎭',
      membershipCount: 188,
      featured: false,
    ),
    Club(
      id: 'club-photography',
      name: 'Photography Club',
      description:
          'Capture campus stories, photo walks, and visual storytelling.',
      category: 'Media',
      icon: '📷',
      membershipCount: 126,
      featured: false,
    ),
    Club(
      id: 'club-entrepreneurship',
      name: 'Entrepreneurship Club',
      description: 'Pitch ideas, discover startups, and connect with mentors.',
      category: 'Business',
      icon: '🚀',
      membershipCount: 132,
      featured: true,
    ),
    Club(
      id: 'club-sports',
      name: 'Sports Club',
      description:
          'Train, compete, and build community through campus sport events.',
      category: 'Wellness',
      icon: '🏆',
      membershipCount: 241,
      featured: false,
    ),
    Club(
      id: 'club-literary',
      name: 'Literary Club',
      description:
          'Discuss books, host open mic sessions, and write with purpose.',
      category: 'Humanities',
      icon: '📚',
      membershipCount: 98,
      featured: false,
    ),
    Club(
      id: 'club-environment',
      name: 'Environment Club',
      description:
          'Promote sustainability, cleanups, and green campus initiatives.',
      category: 'Community',
      icon: '🌱',
      membershipCount: 140,
      featured: false,
    ),
    Club(
      id: 'club-e-cell',
      name: 'E-Cell FCRIT',
      description: 'Entrepreneurship and innovation activities. Official details need administrator review.',
      category: 'Entrepreneurship',
      icon: '🚀',
      membershipCount: 0,
      featured: false,
      needsAdminReview: true,
    ),
  ];

  final List<EventItem> _events = [
    EventItem(
      id: 'event-robotics',
      title: 'Robotics Expo Night',
      description: 'Showcase competition robots and interactive demos from engineering teams.',
      clubId: 'club-robotics',
      venue: 'Innovation Lab 204',
      organizer: 'Robotics Club',
      dateTime: DateTime.now().add(const Duration(days: 4, hours: 3)),
      featured: true,
    ),
    EventItem(
      id: 'event-gala',
      title: 'Cultural Fest Gala',
      description:
          'An evening of dance, music, stage acts, and student performances.',
      clubId: 'club-culture',
      venue: 'Main Auditorium',
      organizer: 'Cultural Club',
      dateTime: DateTime.now().add(const Duration(days: 7, hours: 5)),
      featured: true,
    ),
    EventItem(
      id: 'event-startup',
      title: 'Startup Sprint Pitch',
      description:
          'Students pitch startup ideas and receive feedback from mentors.',
      clubId: 'club-entrepreneurship',
      venue: 'Business Center',
      organizer: 'Entrepreneurship Club',
      dateTime: DateTime.now().add(const Duration(days: 10, hours: 4)),
      featured: true,
    ),
    EventItem(
      id: 'event-hackathon',
      title: 'Weekend Hackathon',
      description:
          'Team up to build a prototype under time pressure and win prizes.',
      clubId: 'club-coding',
      venue: 'Engineering Hall',
      organizer: 'Coding Club',
      dateTime: DateTime.now().add(const Duration(days: 12, hours: 2)),
      featured: false,
    ),
    EventItem(
      id: 'event-photo',
      title: 'Campus Photo Walk',
      description:
          'Explore scenic corners of campus and learn framing techniques.',
      clubId: 'club-photography',
      venue: 'North Lawn',
      organizer: 'Photography Club',
      dateTime: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      featured: false,
    ),
  ];

  final List<Announcement> _announcements = [
    Announcement(
      id: 'ann-1',
      title: 'Summer Internship Fair',
      description: 'Visit the career center this week for internship opportunities and resume support.',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      source: 'Admin Office',
      relatedClubId: null,
    ),
    Announcement(
      id: 'ann-2',
      title: 'Robotics Workshop Registration Open',
      description: 'The Robotics Club is welcoming new members to their introductory prototyping workshop.',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      source: 'Robotics Club',
      relatedClubId: 'club-robotics',
    ),
    Announcement(
      id: 'ann-3',
      title: 'Volunteer Day for Campus Sustainability',
      description: 'Join the Environment Club for a campus cleanup and recycling drive this Friday.',
      publishedAt: DateTime.now().subtract(const Duration(days: 6)),
      source: 'Environment Club',
      relatedClubId: 'club-environment',
    ),
    Announcement(
      id: 'ann-fintech-unlocked-2026',
      slug: 'fintech-unlocked-2026',
      title: 'FinTech Unlocked 2026',
      category: 'Event Announcement',
      description:
          'SAMPLE ANNOUNCEMENT — PAST EVENT (22 October 2026)\n\n'
          'PRESS RELEASE | FINTECH UNLOCKED 2026\n\n'
          'E-CELL is excited to present “FinTech Unlocked” — an engaging online event exploring how AI, Engineering, and Innovation are reshaping the future of Finance!\n\n'
          'Join us to discover how emerging technologies, artificial intelligence, and innovative engineering solutions are transforming the financial world.\n\n'
          'Date: Thursday, 22nd October 2026\n'
          'Time: 7:30 PM\n'
          'Mode: Online\n\n'
          'Certificates will be provided, and the event is completely free of cost.\n\n'
          'Be a part of this exciting journey into the future of financial technology and innovation!\n\n'
          'Registration link: https://forms.gle/tQSsxVVjGMjPkizR6\n\n'
          "Let's unlock new possibilities at the intersection of technology and finance!",
      publishedAt: DateTime(2026, 10, 22),
      source: 'E-Cell FCRIT',
      relatedClubId: 'club-e-cell',
    ),
  ];

  List<Club> get clubs => List.unmodifiable(_clubs);
  List<EventItem> get events => List.unmodifiable(_events);
  List<Announcement> get announcements => List.unmodifiable(_announcements);
  StudentProfile get studentProfile => _studentProfile;
  List<StudentProfile> get students => _useSupabase
      ? List.unmodifiable(_liveStudents)
      : [
          _studentProfile,
          const StudentProfile(
            username: 'samir',
            displayName: 'Samir Khan',
            email: 'samir.khan@college.edu',
            joinedClubIds: ['club-coding', 'club-robotics'],
            registeredEventIds: ['event-hackathon'],
          ),
          const StudentProfile(
            username: 'zoe',
            displayName: 'Zoe Brown',
            email: 'zoe.brown@college.edu',
            joinedClubIds: ['club-culture', 'club-photography'],
            registeredEventIds: ['event-gala'],
          ),
        ];

  Future<void> load() async {
    if (!_useSupabase) return;
    final session = _session;
    if (session?.id == null) {
      throw StateError('A signed-in Supabase user is required to load data.');
    }

    final client = Supabase.instance.client;
    final isAdmin = session!.role == UserRole.admin;
    final clubRows = await client
        .from('clubs')
        .select(
          'id, name, description, category, icon, featured, is_active, needs_admin_review',
        )
        .order('name');
    final eventRows = await client
        .from('events')
        .select(
          'id, title, description, club_id, venue, organizer, starts_at, featured, is_active',
        )
        .order('starts_at');
    final announcementRows = await client
        .from('announcements')
        .select(
          'id, slug, title, category, description, source, related_club_id, image_path, published_at, is_published',
        )
        .order('published_at', ascending: false);
    final membershipRows = await client
        .from('club_memberships')
        .select('profile_id, club_id')
        .order('joined_at', ascending: false);
    final registrationRows = await client
        .from('event_registrations')
        .select('profile_id, event_id')
        .order('registered_at', ascending: false);
    final profileRows = await client
        .from('profiles')
        .select(
          'id, username, display_name, email, department, student_id, role, is_suspended, created_at',
        )
        .eq('id', session.id!)
        .maybeSingle();
    if (profileRows == null) {
      throw StateError('Your user profile could not be loaded.');
    }

    final allProfiles = isAdmin
        ? await client
              .from('profiles')
              .select(
                'id, username, display_name, email, department, student_id, role, is_suspended, created_at',
              )
              .order('created_at', ascending: false)
        : <Map<String, dynamic>>[];
    final countRows = await client.rpc('get_club_member_counts');
    final memberCounts = <String, int>{
      for (final row in countRows as List<dynamic>)
        (row as Map<String, dynamic>)['club_id'] as String:
            (row['member_count'] as num).toInt(),
    };

    _clubs
      ..clear()
      ..addAll(
        clubRows.map(
          (row) => Club(
            id: row['id'] as String,
            name: row['name'] as String,
            description: row['description'] as String,
            category: row['category'] as String,
            icon: row['icon'] as String,
            membershipCount: memberCounts[row['id']] ?? 0,
            featured: row['featured'] as bool,
            isActive: row['is_active'] as bool,
            needsAdminReview: row['needs_admin_review'] as bool,
          ),
        ),
      );
    _events
      ..clear()
      ..addAll(
        eventRows.map(
          (row) => EventItem(
            id: row['id'] as String,
            title: row['title'] as String,
            description: row['description'] as String,
            clubId: row['club_id'] as String,
            venue: row['venue'] as String,
            organizer: row['organizer'] as String,
            dateTime: DateTime.parse(row['starts_at'] as String),
            featured: row['featured'] as bool,
            isActive: row['is_active'] as bool,
          ),
        ),
      );
    _announcements
      ..clear()
      ..addAll(
        announcementRows.map(
          (row) => Announcement(
            id: row['id'] as String,
            slug: row['slug'] as String?,
            title: row['title'] as String,
            description: row['description'] as String,
            category: row['category'] as String,
            publishedAt: DateTime.parse(row['published_at'] as String),
            source: row['source'] as String,
            relatedClubId: row['related_club_id'] as String?,
            imagePath: row['image_path'] as String?,
            isPublished: row['is_published'] as bool,
          ),
        ),
      );

    final profileId = profileRows['id'] as String;
    final ownClubIds = membershipRows
        .where((row) => row['profile_id'] == profileId)
        .map((row) => row['club_id'] as String)
        .toList();
    final ownEventIds = registrationRows
        .where((row) => row['profile_id'] == profileId)
        .map((row) => row['event_id'] as String)
        .toList();
    _studentProfile = _profileFromRow(
      profileRows,
      joinedClubIds: ownClubIds,
      registeredEventIds: ownEventIds,
    );
    _liveStudents
      ..clear()
      ..addAll(
        allProfiles.map((row) {
          final id = row['id'] as String;
          return _profileFromRow(
            row,
            joinedClubIds: membershipRows
                .where((membership) => membership['profile_id'] == id)
                .map((membership) => membership['club_id'] as String)
                .toList(),
            registeredEventIds: registrationRows
                .where((registration) => registration['profile_id'] == id)
                .map((registration) => registration['event_id'] as String)
                .toList(),
          );
        }),
      );
    _liveRegistrationsCount = isAdmin
        ? registrationRows.length
        : ownEventIds.length;
    notifyListeners();
  }

  StudentProfile _profileFromRow(
    Map<String, dynamic> row, {
    required List<String> joinedClubIds,
    required List<String> registeredEventIds,
  }) {
    return StudentProfile(
      id: row['id'] as String,
      username: row['username'] as String,
      displayName: row['display_name'] as String,
      email: row['email'] as String,
      joinedClubIds: joinedClubIds,
      registeredEventIds: registeredEventIds,
      createdAt: DateTime.parse(row['created_at'] as String),
      role: row['role'] as String,
      department: row['department'] as String?,
      studentId: row['student_id'] as String?,
      isSuspended: row['is_suspended'] as bool,
    );
  }

  List<Club> featuredClubs() =>
      _clubs.where((club) => club.featured && club.isActive).toList();

  List<EventItem> upcomingEvents() => _events
      .where(
        (event) => event.isActive && event.dateTime.isAfter(DateTime.now()),
      )
      .toList();

  Club? clubById(String id) =>
      _clubs.where((club) => club.id == id).firstOrNull;

  EventItem? eventById(String id) =>
      _events.where((event) => event.id == id).firstOrNull;

  bool isClubJoined(String clubId) =>
      _studentProfile.joinedClubIds.contains(clubId);

  bool isEventRegistered(String eventId) =>
      _studentProfile.registeredEventIds.contains(eventId);

  Future<void> updateProfile({
    required String displayName,
    required String department,
    required String studentId,
  }) async {
    if (_useSupabase) {
      final profileId = _session?.id;
      if (profileId == null) {
        throw StateError('Your account is not connected to Supabase Auth.');
      }
      await Supabase.instance.client
          .from('profiles')
          .update({
            'display_name': displayName.trim(),
            'department': department.trim().isEmpty ? null : department.trim(),
            'student_id': studentId.trim().isEmpty ? null : studentId.trim(),
          })
          .eq('id', profileId);
      await load();
      return;
    }

    _studentProfile = _studentProfile.copyWith(
      displayName: displayName.trim(),
      department: department.trim(),
      studentId: studentId.trim(),
    );
    notifyListeners();
  }

  Future<void> toggleClubMembership(String clubId) async {
    if (_useSupabase) {
      final profileId = _session?.id;
      if (profileId == null) {
        throw StateError('Your account is not connected to Supabase Auth.');
      }
      final membership = Supabase.instance.client.from('club_memberships');
      if (isClubJoined(clubId)) {
        await membership
            .delete()
            .eq('profile_id', profileId)
            .eq('club_id', clubId);
      } else {
        await membership.insert({'profile_id': profileId, 'club_id': clubId});
      }
      await load();
      return;
    }

    final current = _studentProfile.joinedClubIds;
    final updated = List<String>.from(current);
    if (updated.contains(clubId)) {
      updated.remove(clubId);
    } else {
      updated.add(clubId);
    }
    _studentProfile = _studentProfile.copyWith(joinedClubIds: updated);
    notifyListeners();
  }

  Future<void> toggleEventRegistration(String eventId) async {
    if (_useSupabase) {
      final profileId = _session?.id;
      if (profileId == null) {
        throw StateError('Your account is not connected to Supabase Auth.');
      }
      final registration = Supabase.instance.client.from('event_registrations');
      if (isEventRegistered(eventId)) {
        await registration
            .delete()
            .eq('profile_id', profileId)
            .eq('event_id', eventId);
      } else {
        await registration.insert({
          'profile_id': profileId,
          'event_id': eventId,
        });
      }
      await load();
      return;
    }

    final current = _studentProfile.registeredEventIds;
    final updated = List<String>.from(current);
    if (updated.contains(eventId)) {
      updated.remove(eventId);
    } else {
      updated.add(eventId);
    }
    _studentProfile = _studentProfile.copyWith(registeredEventIds: updated);
    notifyListeners();
  }

  Future<Club> createClub({
    required String name,
    required String description,
    required String category,
  }) async {
    if (_useSupabase) {
      return await _createClubInSupabase(
        name: name,
        description: description,
        category: category,
      );
    }
    final club = Club(
      id: 'club-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      category: category,
      icon: '✨',
      membershipCount: 0,
      featured: false,
    );
    _clubs.add(club);
    notifyListeners();
    return club;
  }

  Future<void> updateClub({
    required String id,
    required String name,
    required String description,
    required String category,
  }) async {
    if (_useSupabase) {
      await _updateClubInSupabase(
        id: id,
        name: name,
        description: description,
        category: category,
      );
      return;
    }
    final index = _clubs.indexWhere((club) => club.id == id);
    if (index == -1) {
      return;
    }
    final original = _clubs[index];
    _clubs[index] = Club(
      id: original.id,
      name: name,
      description: description,
      category: category,
      icon: original.icon,
      membershipCount: original.membershipCount,
      featured: original.featured,
    );
    notifyListeners();
  }

  Future<Club> _createClubInSupabase({
    required String name,
    required String description,
    required String category,
  }) async {
    await Supabase.instance.client.from('clubs').insert({
      'name': name,
      'description': description,
      'category': category,
    });
    await load();
    return _clubs.firstWhere((club) => club.name == name);
  }

  Future<void> _updateClubInSupabase({
    required String id,
    required String name,
    required String description,
    required String category,
  }) async {
    await Supabase.instance.client
        .from('clubs')
        .update({
          'name': name,
          'description': description,
          'category': category,
        })
        .eq('id', id);
    await load();
  }

  Future<void> setClubActive(String id, bool isActive) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('clubs')
          .update({'is_active': isActive})
          .eq('id', id);
      await load();
      return;
    }
    final index = _clubs.indexWhere((club) => club.id == id);
    if (index == -1) return;
    final club = _clubs[index];
    _clubs[index] = Club(
      id: club.id,
      name: club.name,
      description: club.description,
      category: club.category,
      icon: club.icon,
      membershipCount: club.membershipCount,
      featured: club.featured,
      isActive: isActive,
      needsAdminReview: club.needsAdminReview,
    );
    notifyListeners();
  }

  Future<void> deleteClub(String id) async {
    if (_useSupabase) {
      await Supabase.instance.client.from('clubs').delete().eq('id', id);
      await load();
      return;
    }
    _clubs.removeWhere((club) => club.id == id);
    _events.removeWhere((event) => event.clubId == id);
    _studentProfile = _studentProfile.copyWith(
      joinedClubIds: _studentProfile.joinedClubIds
          .where((clubId) => clubId != id)
          .toList(),
    );
    notifyListeners();
  }

  Future<EventItem> createEvent({
    required String title,
    required String description,
    required String clubId,
    required String venue,
    required String organizer,
    required DateTime dateTime,
  }) async {
    if (_useSupabase) {
      return await _createEventInSupabase(
        title: title,
        description: description,
        clubId: clubId,
        venue: venue,
        organizer: organizer,
        dateTime: dateTime,
      );
    }
    final event = EventItem(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      clubId: clubId,
      venue: venue,
      organizer: organizer,
      dateTime: dateTime,
      featured: false,
    );
    _events.add(event);
    notifyListeners();
    return event;
  }

  Future<void> updateEvent({
    required String id,
    required String title,
    required String description,
    required String clubId,
    required String venue,
    required String organizer,
    required DateTime dateTime,
  }) async {
    if (_useSupabase) {
      await _updateEventInSupabase(
        id: id,
        title: title,
        description: description,
        clubId: clubId,
        venue: venue,
        organizer: organizer,
        dateTime: dateTime,
      );
      return;
    }
    final index = _events.indexWhere((event) => event.id == id);
    if (index == -1) {
      return;
    }
    final original = _events[index];
    _events[index] = EventItem(
      id: original.id,
      title: title,
      description: description,
      clubId: clubId,
      venue: venue,
      organizer: organizer,
      dateTime: dateTime,
      featured: original.featured,
    );
    notifyListeners();
  }

  Future<EventItem> _createEventInSupabase({
    required String title,
    required String description,
    required String clubId,
    required String venue,
    required String organizer,
    required DateTime dateTime,
  }) async {
    await Supabase.instance.client.from('events').insert({
      'title': title,
      'description': description,
      'club_id': clubId,
      'venue': venue,
      'organizer': organizer,
      'starts_at': dateTime.toUtc().toIso8601String(),
    });
    await load();
    return _events.firstWhere(
      (event) => event.title == title && event.dateTime == dateTime,
    );
  }

  Future<void> _updateEventInSupabase({
    required String id,
    required String title,
    required String description,
    required String clubId,
    required String venue,
    required String organizer,
    required DateTime dateTime,
  }) async {
    await Supabase.instance.client
        .from('events')
        .update({
          'title': title,
          'description': description,
          'club_id': clubId,
          'venue': venue,
          'organizer': organizer,
          'starts_at': dateTime.toUtc().toIso8601String(),
        })
        .eq('id', id);
    await load();
  }

  Future<void> setEventActive(String id, bool isActive) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('events')
          .update({'is_active': isActive})
          .eq('id', id);
      await load();
      return;
    }
    final index = _events.indexWhere((event) => event.id == id);
    if (index == -1) return;
    final event = _events[index];
    _events[index] = EventItem(
      id: event.id,
      title: event.title,
      description: event.description,
      clubId: event.clubId,
      venue: event.venue,
      organizer: event.organizer,
      dateTime: event.dateTime,
      featured: event.featured,
      isActive: isActive,
    );
    notifyListeners();
  }

  Future<void> deleteEvent(String id) async {
    if (_useSupabase) {
      await Supabase.instance.client.from('events').delete().eq('id', id);
      await load();
      return;
    }
    _events.removeWhere((event) => event.id == id);
    _studentProfile = _studentProfile.copyWith(
      registeredEventIds: _studentProfile.registeredEventIds
          .where((eventId) => eventId != id)
          .toList(),
    );
    notifyListeners();
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String description,
    required String source,
    String? relatedClubId,
    String category = 'General',
  }) async {
    if (_useSupabase) {
      await Supabase.instance.client.from('announcements').insert({
        'title': title,
        'description': description,
        'source': source,
        'category': category,
        'related_club_id': relatedClubId,
      });
      await load();
      return _announcements.firstWhere(
        (announcement) => announcement.title == title,
      );
    }
    final announcement = Announcement(
      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      publishedAt: DateTime.now(),
      source: source,
      relatedClubId: relatedClubId,
      category: category,
    );
    _announcements.add(announcement);
    notifyListeners();
    return announcement;
  }

  Future<void> updateAnnouncement({
    required String id,
    required String title,
    required String description,
    required String source,
    String? relatedClubId,
    String category = 'General',
  }) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('announcements')
          .update({
            'title': title,
            'description': description,
            'source': source,
            'category': category,
            'related_club_id': relatedClubId,
          })
          .eq('id', id);
      await load();
      return;
    }
    final index = _announcements.indexWhere(
      (announcement) => announcement.id == id,
    );
    if (index == -1) {
      return;
    }

    final original = _announcements[index];
    _announcements[index] = Announcement(
      id: original.id,
      title: title,
      description: description,
      publishedAt: original.publishedAt,
      source: source,
      relatedClubId: relatedClubId,
      category: category,
    );
    notifyListeners();
  }

  Future<void> setAnnouncementPublished(String id, bool isPublished) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('announcements')
          .update({'is_published': isPublished})
          .eq('id', id);
      await load();
      return;
    }
    final index = _announcements.indexWhere(
      (announcement) => announcement.id == id,
    );
    if (index == -1) return;
    final announcement = _announcements[index];
    _announcements[index] = Announcement(
      id: announcement.id,
      title: announcement.title,
      description: announcement.description,
      publishedAt: announcement.publishedAt,
      source: announcement.source,
      relatedClubId: announcement.relatedClubId,
      category: announcement.category,
      slug: announcement.slug,
      imagePath: announcement.imagePath,
      isPublished: isPublished,
    );
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    if (_useSupabase) {
      await Supabase.instance.client
          .from('announcements')
          .delete()
          .eq('id', id);
      await load();
      return;
    }
    _announcements.removeWhere((announcement) => announcement.id == id);
    notifyListeners();
  }

  List<Club> clubsForQuery(String query, {String? category}) {
    final normalized = query.trim().toLowerCase();
    return _clubs.where((club) {
      final matchesQuery =
          normalized.isEmpty ||
          club.name.toLowerCase().contains(normalized) ||
          club.description.toLowerCase().contains(normalized) ||
          club.category.toLowerCase().contains(normalized);
      final matchesCategory =
          category == null || category == 'All' || club.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<EventItem> eventsForQuery(String query, {String? category}) {
    final normalized = query.trim().toLowerCase();
    return _events.where((event) {
      final club = clubById(event.clubId);
      final matchesQuery =
          normalized.isEmpty ||
          event.title.toLowerCase().contains(normalized) ||
          (club?.name.toLowerCase().contains(normalized) ?? false) ||
          event.venue.toLowerCase().contains(normalized);
      final matchesCategory =
          category == null || category == 'All' || (club?.category == category);
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<Announcement> announcementsForQuery(String query) {
    final normalized = query.trim().toLowerCase();
    return _announcements.where((announcement) {
      return normalized.isEmpty ||
          announcement.title.toLowerCase().contains(normalized) ||
          announcement.description.toLowerCase().contains(normalized) ||
          announcement.source.toLowerCase().contains(normalized);
    }).toList();
  }

  int get registrationsCount => _useSupabase
      ? _liveRegistrationsCount
      : _studentProfile.registeredEventIds.length;

  int get totalClubs => _clubs.length;
  int get totalEvents => _events.length;
  int get totalStudents =>
      students.where((student) => student.role == 'student').length;
}

extension FirstWhereOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (_) {
      return null;
    }
  }
}
