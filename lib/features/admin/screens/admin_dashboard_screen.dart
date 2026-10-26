import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.repository,
    required this.onLogout,
    required this.onToggleTheme,
    required this.onNavigate,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Overview', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              shrinkWrap: true,
              crossAxisCount: constraints.maxWidth < 560
                  ? 2
                  : constraints.maxWidth < 900
                  ? 2
                  : 4,
              childAspectRatio: constraints.maxWidth < 560 ? 1.05 : 1.7,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Metric(
                  title: 'Clubs',
                  value: '${repository.totalClubs}',
                  icon: Icons.groups_rounded,
                ),
                _Metric(
                  title: 'Events',
                  value: '${repository.totalEvents}',
                  icon: Icons.event_rounded,
                ),
                _Metric(
                  title: 'Students',
                  value: '${repository.totalStudents}',
                  icon: Icons.people_rounded,
                ),
                _Metric(
                  title: 'Registrations',
                  value: '${repository.registrationsCount}',
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Quick actions', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionButton(
                label: 'Add club',
                icon: Icons.add_rounded,
                onPressed: () => onNavigate(1),
              ),
              _ActionButton(
                label: 'Create event',
                icon: Icons.event_available_rounded,
                onPressed: () => onNavigate(2),
              ),
              _ActionButton(
                label: 'Publish update',
                icon: Icons.campaign_rounded,
                onPressed: () => onNavigate(3),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent announcements', style: theme.textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: repository.announcements.take(3).length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = repository.announcements[index];
                return ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.source} • ${item.category}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value, required this.icon});

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(title),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
