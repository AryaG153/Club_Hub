import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';

class StudentAnnouncementsScreen extends StatelessWidget {
  const StudentAnnouncementsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final announcements = [
      ...repository.announcements.where(
        (announcement) => announcement.slug == 'fintech-unlocked-2026',
      ),
      ...repository.announcements.where(
        (announcement) => announcement.slug != 'fintech-unlocked-2026',
      ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            onPressed: onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: repository.load,
        child: announcements.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No announcements yet.')),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: announcements.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final announcement = announcements[index];
                  final isPastSample =
                      announcement.slug == 'fintech-unlocked-2026';
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(label: Text(announcement.category)),
                              if (isPastSample)
                                const Chip(label: Text('Past event • Sample')),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(announcement.description),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(_formatDate(announcement.publishedAt)),
                              const Spacer(),
                              Text(announcement.source),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }
}
