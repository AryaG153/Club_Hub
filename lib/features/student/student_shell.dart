import 'package:flutter/material.dart';

import '../../core/widgets/demo_mode_banner.dart';
import '../../data/demo_repository.dart';
import '../../models/clubhub_models.dart';
import 'screens/student_dashboard_screen.dart';
import 'screens/student_clubs_screen.dart';
import 'screens/student_events_screen.dart';
import 'screens/student_announcements_screen.dart';
import 'screens/student_profile_screen.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.session,
    required this.repository,
    required this.onLogout,
    required this.onToggleTheme,
  });

  final AuthSession session;
  final ClubHubDemoRepository repository;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenBuilders = [
      () => StudentDashboardScreen(
        session: widget.session,
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
        onLogout: widget.onLogout,
      ),
      () => StudentClubsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => StudentEventsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => StudentAnnouncementsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => StudentProfileScreen(
        session: widget.session,
        repository: widget.repository,
        onLogout: widget.onLogout,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    final navItems = const [
      NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
      NavigationDestination(icon: Icon(Icons.group_rounded), label: 'Clubs'),
      NavigationDestination(icon: Icon(Icons.event_rounded), label: 'Events'),
      NavigationDestination(icon: Icon(Icons.campaign_rounded), label: 'News'),
      NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (value) =>
                      setState(() => _selectedIndex = value),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_rounded),
                      label: Text('Clubs'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.event_rounded),
                      label: Text('Events'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.campaign_rounded),
                      label: Text('Announcements'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_rounded),
                      label: Text('Profile'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Column(
                    children: [
                      if (!widget.repository.isLive) const DemoModeBanner(),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: widget.repository,
                          builder: (context, _) =>
                              screenBuilders[_selectedIndex](),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: Column(
            children: [
              if (!widget.repository.isLive) const DemoModeBanner(),
              Expanded(
                child: AnimatedBuilder(
                  animation: widget.repository,
                  builder: (context, _) => screenBuilders[_selectedIndex](),
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (value) =>
                setState(() => _selectedIndex = value),
            destinations: navItems,
          ),
        );
      },
    );
  }
}
