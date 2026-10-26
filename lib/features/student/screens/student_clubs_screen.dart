import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';

class StudentClubsScreen extends StatefulWidget {
  const StudentClubsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<StudentClubsScreen> createState() => _StudentClubsScreenState();
}

class _StudentClubsScreenState extends State<StudentClubsScreen> {
  String _search = '';
  String _category = 'All';
  final Set<String> _workingClubs = {};

  Future<void> _toggleMembership(String clubId) async {
    setState(() => _workingClubs.add(clubId));
    try {
      await widget.repository.toggleClubMembership(clubId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _workingClubs.remove(clubId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubs = widget.repository.clubsForQuery(_search, category: _category);
    final categories = [
      'All',
      ...widget.repository.clubs.map((club) => club.category).toSet(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs'),
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
                hintText: 'Search clubs',
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
                child: clubs.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 160),
                          Center(child: Text('No clubs match your filters.')),
                        ],
                      )
                    : ListView.separated(
                        itemCount: clubs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final club = clubs[index];
                          final joined = widget.repository.isClubJoined(
                            club.id,
                          );
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    child: Text(club.icon),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                club.name,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(club.category),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(club.description),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.people_outline_rounded,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '${club.membershipCount} members',
                                            ),
                                            const Spacer(),
                                            TextButton(
                                              onPressed:
                                                  _workingClubs.contains(
                                                    club.id,
                                                  )
                                                  ? null
                                                  : () => _toggleMembership(
                                                      club.id,
                                                    ),
                                              child:
                                                  _workingClubs.contains(
                                                    club.id,
                                                  )
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : Text(
                                                      joined
                                                          ? 'Leave Club'
                                                          : 'Join Club',
                                                    ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
}
