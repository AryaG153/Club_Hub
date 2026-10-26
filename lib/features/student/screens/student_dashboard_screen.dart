import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({
    super.key,
    required this.session,
    required this.repository,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final AuthSession session;
  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalClubs = repository.clubs.length;
    final upcoming = repository.upcomingEvents();
    final registered = repository.studentProfile.registeredEventIds.length;
    final announcements = repository.announcements;
    final recentAnnouncements = [
      ...announcements.where(
        (announcement) => announcement.slug == 'fintech-unlocked-2026',
      ),
      ...announcements.where(
        (announcement) => announcement.slug != 'fintech-unlocked-2026',
      ),
    ].take(3);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
            tooltip: 'Toggle theme',
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: repository.load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${repository.studentProfile.displayName}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your campus community is ready for the next opportunity.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _SummaryBadge(label: 'ClubHub', value: 'Student'),
              ],
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.7,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _MetricCard(
                  title: 'Available clubs',
                  value: '$totalClubs',
                  icon: Icons.group_rounded,
                ),
                _MetricCard(
                  title: 'Upcoming events',
                  value: '${upcoming.length}',
                  icon: Icons.event_available_rounded,
                ),
                _MetricCard(
                  title: 'Registered',
                  value: '$registered',
                  icon: Icons.check_circle_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Featured clubs', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: repository.featuredClubs().length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final club = repository.featuredClubs()[index];
                  return SizedBox(
                    width: 220,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text(club.icon)),
                                const Spacer(),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      club.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(club.name, style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(
                              club.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text('Upcoming events', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: upcoming.take(3).length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = upcoming[index];
                final club = repository.clubById(event.clubId);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        event.featured
                            ? Icons.star_rounded
                            : Icons.event_rounded,
                      ),
                    ),
                    title: Text(event.title),
                    subtitle: Text(
                      '${club?.name ?? 'Club'} • ${_formatDate(event.dateTime)} • ${event.venue}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: theme.colorScheme.primaryContainer,
                      ),
                      child: Text(
                        '${event.dateTime.hour.toString().padLeft(2, '0')}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Recent announcements', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            ...recentAnnouncements.map(
              (announcement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: ListTile(
                    title: Text(announcement.title),
                    subtitle: Text(
                      '${announcement.source} • ${announcement.category} • '
                      '${_formatDate(announcement.publishedAt)}'
                      '${announcement.slug == 'fintech-unlocked-2026' ? ' • Past event sample' : ''}\n'
                      '${announcement.description}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const Spacer(),
            Text(value, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(title, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
