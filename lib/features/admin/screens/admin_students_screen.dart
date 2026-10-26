import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';
import '../../../services/admin_user_service.dart';

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final _adminUserService = const AdminUserService();
  final _inviteFormKey = GlobalKey<FormState>();
  final _inviteName = TextEditingController();
  final _inviteEmail = TextEditingController();
  final Set<String> _busyUsers = {};
  String _search = '';

  @override
  void dispose() {
    _inviteName.dispose();
    _inviteEmail.dispose();
    super.dispose();
  }

  Future<void> _inviteUser() async {
    _inviteName.clear();
    _inviteEmail.clear();
    final shouldInvite = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite student'),
        content: Form(
          key: _inviteFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _inviteName,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'Enter the student’s name.'
                    : null,
              ),
              TextFormField(
                controller: _inviteEmail,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(value.trim())
                    ? 'Enter a valid email.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (_inviteFormKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Send invite'),
          ),
        ],
      ),
    );
    if (shouldInvite != true || !mounted) return;
    try {
      await _adminUserService.inviteUser(
        email: _inviteEmail.text,
        displayName: _inviteName.text,
      );
      await widget.repository.load();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invitation sent.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _manageUser(StudentProfile student, String action) async {
    if (student.id == null || _busyUsers.contains(student.id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action ${student.displayName}?'),
        content: Text(
          action == 'Delete'
              ? 'This permanently deletes the Auth account and associated profile data.'
              : 'This change is applied to the Supabase account by the protected admin function.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyUsers.add(student.id!));
    try {
      switch (action) {
        case 'Suspend':
          await _adminUserService.setSuspended(
            userId: student.id!,
            suspended: true,
          );
        case 'Restore':
          await _adminUserService.setSuspended(
            userId: student.id!,
            suspended: false,
          );
        case 'Promote to admin':
          await _adminUserService.setRole(userId: student.id!, role: 'admin');
        case 'Revoke admin':
          await _adminUserService.setRole(userId: student.id!, role: 'student');
        case 'Delete':
          await _adminUserService.deleteUser(student.id!);
      }
      await widget.repository.load();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$action completed.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _busyUsers.remove(student.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final students = widget.repository.students.where((student) {
      final query = _search.toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return student.displayName.toLowerCase().contains(query) ||
          student.username.toLowerCase().contains(query) ||
          student.email.toLowerCase().contains(query) ||
          (student.studentId?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
          IconButton(
            onPressed: widget.repository.isLive
                ? () async {
                    try {
                      await widget.repository.load();
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error.toString())),
                        );
                      }
                    }
                  }
                : null,
            tooltip: 'Refresh student list',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search students',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: students.isEmpty
                  ? const Center(child: Text('No accounts match your search.'))
                  : RefreshIndicator(
                      onRefresh: widget.repository.load,
                      child: ListView.separated(
                        itemCount: students.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final clubs = student.joinedClubIds
                              .map(
                                (id) =>
                                    widget.repository.clubById(id)?.name ?? id,
                              )
                              .join(', ');
                          final registeredEvents = student.registeredEventIds
                              .map(
                                (id) =>
                                    widget.repository.eventById(id)?.title ??
                                    id,
                              )
                              .join(', ');
                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_rounded),
                              ),
                              title: Text(student.displayName),
                              subtitle: Text(
                                '${student.role} • ${student.email}\n'
                                '${student.department ?? 'Department not provided'}'
                                '${student.studentId == null ? '' : ' • ${student.studentId}'}\n'
                                'Joined: ${_formatDate(student.createdAt)} • Clubs: ${clubs.isEmpty ? 'None' : clubs} • Events: ${registeredEvents.isEmpty ? 'None' : registeredEvents}'
                                '${student.isSuspended ? '\nSuspended' : ''}',
                              ),
                              trailing: student.id == null
                                  ? null
                                  : PopupMenuButton<String>(
                                      enabled: !_busyUsers.contains(student.id),
                                      onSelected: (action) =>
                                          _manageUser(student, action),
                                      itemBuilder: (context) => [
                                        if (student.isSuspended)
                                          const PopupMenuItem(
                                            value: 'Restore',
                                            child: Text('Restore account'),
                                          )
                                        else if (student.role != 'admin')
                                          const PopupMenuItem(
                                            value: 'Suspend',
                                            child: Text('Suspend account'),
                                          ),
                                        if (student.role == 'admin')
                                          const PopupMenuItem(
                                            value: 'Revoke admin',
                                            child: Text('Revoke admin'),
                                          )
                                        else
                                          const PopupMenuItem(
                                            value: 'Promote to admin',
                                            child: Text('Promote to admin'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'Delete',
                                          child: Text('Delete account'),
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
      floatingActionButton: widget.repository.isLive
          ? FloatingActionButton.extended(
              onPressed: _inviteUser,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Invite student'),
            )
          : null,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Demo account';
    return '${date.day}/${date.month}/${date.year}';
  }
}
