import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen> {
  String _search = '';
  String _category = 'All';
  final Set<String> _workingEvents = {};

  Future<void> _toggleRegistration(String eventId) async {
    setState(() => _workingEvents.add(eventId));
    try {
      await widget.repository.toggleEventRegistration(eventId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _workingEvents.remove(eventId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.repository.eventsForQuery(
      _search,
      category: _category,
    );
    final categories = [
      'All',
      ...widget.repository.clubs.map((club) => club.category).toSet(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search events',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final current = categories[index];
                  final isSelected = _category == current;
                  return ChoiceChip(
                    label: Text(current),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _category = current),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: RefreshIndicator(
                onRefresh: widget.repository.load,
                child: events.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No events match your filters.')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: events.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final club = widget.repository.clubById(event.clubId);
                          final registered = widget.repository
                              .isEventRegistered(event.id);
                          final isPast = event.dateTime.isBefore(
                            DateTime.now(),
                          );
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          event.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isPast
                                              ? Colors.grey.shade200
                                              : Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          isPast ? 'Past' : 'Upcoming',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(event.description),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    children: [
                                      _InfoChip(
                                        icon: Icons.group_rounded,
                                        text: club?.name ?? 'Unknown club',
                                      ),
                                      _InfoChip(
                                        icon: Icons.location_on_rounded,
                                        text: event.venue,
                                      ),
                                      _InfoChip(
                                        icon: Icons.calendar_month_rounded,
                                        text: _formatDate(event.dateTime),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Organizer: ${event.organizer}'),
                                      FilledButton(
                                        onPressed:
                                            (isPast && !registered) ||
                                                !event.isActive ||
                                                _workingEvents.contains(
                                                  event.id,
                                                )
                                            ? null
                                            : () =>
                                                  _toggleRegistration(event.id),
                                        child: _workingEvents.contains(event.id)
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : Text(
                                                registered
                                                    ? 'Cancel Registration'
                                                    : 'Register',
                                              ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year} • ${value.hour}:${value.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
