enum UserRole { student, admin }

class AuthSession {
  const AuthSession({
    required this.username,
    required this.displayName,
    required this.role,
    this.id,
  });

  final String username;
  final String displayName;
  final UserRole role;
  final String? id;
}

class Club {
  const Club({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.membershipCount,
    required this.featured,
    this.isActive = true,
    this.needsAdminReview = false,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final String icon;
  final int membershipCount;
  final bool featured;
  final bool isActive;
  final bool needsAdminReview;
}

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.venue,
    required this.organizer,
    required this.dateTime,
    required this.featured,
    this.isActive = true,
  });

  final String id;
  final String title;
  final String description;
  final String clubId;
  final String venue;
  final String organizer;
  final DateTime dateTime;
  final bool featured;
  final bool isActive;
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.publishedAt,
    required this.source,
    required this.relatedClubId,
    this.category = 'General',
    this.slug,
    this.imagePath,
    this.isPublished = true,
  });

  final String id;
  final String title;
  final String description;
  final DateTime publishedAt;
  final String source;
  final String? relatedClubId;
  final String category;
  final String? slug;
  final String? imagePath;
  final bool isPublished;
}

class StudentProfile {
  const StudentProfile({
    required this.username,
    required this.displayName,
    required this.email,
    required this.joinedClubIds,
    required this.registeredEventIds,
    this.id,
    this.createdAt,
    this.role = 'student',
    this.department,
    this.studentId,
    this.isSuspended = false,
  });

  final String username;
  final String displayName;
  final String email;
  final List<String> joinedClubIds;
  final List<String> registeredEventIds;
  final String? id;
  final DateTime? createdAt;
  final String role;
  final String? department;
  final String? studentId;
  final bool isSuspended;

  StudentProfile copyWith({
    String? username,
    String? displayName,
    String? email,
    List<String>? joinedClubIds,
    List<String>? registeredEventIds,
    String? id,
    DateTime? createdAt,
    String? department,
    String? studentId,
  }) {
    return StudentProfile(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      joinedClubIds: joinedClubIds ?? this.joinedClubIds,
      registeredEventIds: registeredEventIds ?? this.registeredEventIds,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      role: role,
      department: department ?? this.department,
      studentId: studentId ?? this.studentId,
    );
  }
}
