import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({
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
  Widget build(BuildContext context) {
    final profile = repository.studentProfile;
    final clubNames = profile.joinedClubIds
        .map((id) => repository.clubById(id)?.name ?? id)
        .toList();
    final eventNames = profile.registeredEventIds
        .map((id) => repository.eventById(id)?.title ?? id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => _editProfile(context, profile),
            tooltip: 'Edit profile',
            icon: const Icon(Icons.edit_rounded),
          ),
          IconButton(
            onPressed: onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
          IconButton(
            onPressed: () async {
              try {
                await repository.load();
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            tooltip: 'Refresh profile',
            icon: const Icon(Icons.refresh_rounded),
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 32,
                    child: Icon(Icons.person_rounded),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '@${profile.username} • Student',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(profile.email),
                  if (profile.department?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text('Department: ${profile.department}'),
                  ],
                  if (profile.studentId?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 6),
                    Text('Student ID: ${profile.studentId}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Joined clubs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (clubNames.isEmpty)
            const Text('No clubs joined yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: clubNames
                  .map((name) => Chip(label: Text(name)))
                  .toList(),
            ),
          const SizedBox(height: 18),
          Text(
            'Registered events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (eventNames.isEmpty)
            const Text('No registrations yet.')
          else
            ...eventNames.map(
              (name) => ListTile(
                title: Text(name),
                leading: const Icon(Icons.event_rounded),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    StudentProfile profile,
  ) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final updated = await showDialog<bool>(
      context: context,
      builder: (_) => _ProfileEditDialog(
        profile: profile,
        onSave: repository.updateProfile,
      ),
    );
    if (updated == true && scaffoldMessenger.mounted) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    }
  }
}

class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile, required this.onSave});

  final StudentProfile profile;
  final Future<void> Function({
    required String displayName,
    required String department,
    required String studentId,
  })
  onSave;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _departmentController;
  late final TextEditingController _studentIdController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _departmentController = TextEditingController(
      text: widget.profile.department ?? '',
    );
    _studentIdController = TextEditingController(
      text: widget.profile.studentId ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _departmentController.dispose();
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        displayName: _nameController.text,
        department: _departmentController.text,
        studentId: _studentIdController.text,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter your name.'
                  : value.trim().length > 120
                  ? 'Name must be 120 characters or fewer.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _departmentController,
              decoration: const InputDecoration(
                labelText: 'Department (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _studentIdController,
              decoration: const InputDecoration(
                labelText: 'Student ID (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(_isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }
}
