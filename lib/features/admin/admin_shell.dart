import 'package:flutter/material.dart';

import '../../core/widgets/demo_mode_banner.dart';
import '../../data/demo_repository.dart';
import '../../models/clubhub_models.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_clubs_screen.dart';
import 'screens/admin_events_screen.dart';
import 'screens/admin_announcements_screen.dart';
import 'screens/admin_students_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
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
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenBuilders = [
      () => AdminDashboardScreen(
        repository: widget.repository,
        onLogout: widget.onLogout,
        onToggleTheme: widget.onToggleTheme,
        onNavigate: (index) => setState(() => _selectedIndex = index),
      ),
      () => AdminClubsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => AdminEventsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => AdminAnnouncementsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
      () => AdminStudentsScreen(
        repository: widget.repository,
        onToggleTheme: widget.onToggleTheme,
      ),
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
                      icon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.groups_rounded),
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
                      icon: Icon(Icons.people_rounded),
                      label: Text('Students'),
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
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_rounded),
                label: 'Clubs',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_rounded),
                label: 'Events',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_rounded),
                label: 'Announcements',
              ),
              NavigationDestination(
                icon: Icon(Icons.people_rounded),
                label: 'Students',
              ),
            ],
          ),
        );
      },
    );
  }
}
