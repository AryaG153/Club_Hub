import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';
import '../admin_split_layout.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sourceController = TextEditingController();
  final _categoryController = TextEditingController();
  String? _relatedClubId;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _editingId;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final wasEditing = _isEditing;
    setState(() => _isSaving = true);
    try {
      if (wasEditing && _editingId != null) {
        await widget.repository.updateAnnouncement(
          id: _editingId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          source: _sourceController.text.trim(),
          relatedClubId: _relatedClubId,
          category: _categoryController.text.trim(),
        );
      } else {
        await widget.repository.createAnnouncement(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          source: _sourceController.text.trim(),
          relatedClubId: _relatedClubId,
          category: _categoryController.text.trim().isEmpty
              ? 'General'
              : _categoryController.text.trim(),
        );
      }
      if (!mounted) return;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasEditing ? 'Announcement updated.' : 'Announcement published.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _edit(Announcement announcement) {
    _titleController.text = announcement.title;
    _descriptionController.text = announcement.description;
    _sourceController.text = announcement.source;
    _categoryController.text = announcement.category;
    _relatedClubId = announcement.relatedClubId;
    _isEditing = true;
    _editingId = announcement.id;
    setState(() {});
  }

  Future<void> _setPublished(String id, bool published) async {
    try {
      await widget.repository.setAnnouncementPublished(id, published);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  void _deleteAnnouncement(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete announcement?'),
        content: const Text('This permanently deletes the announcement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.repository.deleteAnnouncement(id);
                if (context.mounted) Navigator.pop(context);
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error.toString())));
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _sourceController.clear();
    _categoryController.clear();
    _relatedClubId = null;
    _isEditing = false;
    _editingId = null;
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _sourceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final announcements = widget.repository.announcements;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: const Icon(Icons.dark_mode_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: AdminSplitLayout(
          listPanel: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Announcement feed',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: announcements.isEmpty
                        ? const Center(child: Text('No announcements to show.'))
                        : ListView.separated(
                            itemCount: announcements.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final announcement = announcements[index];
                              return ListTile(
                                title: Text(announcement.title),
                                subtitle: Text(
                                  '${announcement.source} • ${announcement.description}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _setPublished(
                                        announcement.id,
                                        !announcement.isPublished,
                                      ),
                                      tooltip: announcement.isPublished
                                          ? 'Unpublish'
                                          : 'Publish',
                                      icon: Icon(
                                        announcement.isPublished
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _edit(announcement),
                                      icon: const Icon(Icons.edit_rounded),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _deleteAnnouncement(announcement.id),
                                      icon: const Icon(Icons.delete_rounded),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          formPanel: Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _isEditing ? 'Edit announcement' : 'Publish announcement',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Title is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Description is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source or club',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Source is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _relatedClubId,
                      decoration: const InputDecoration(
                        labelText: 'Related club (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('No specific club'),
                        ),
                        ...widget.repository.clubs.map(
                          (club) => DropdownMenuItem(
                            value: club.id,
                            child: Text(club.name),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _relatedClubId = value),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : _isEditing
                            ? 'Save announcement'
                            : 'Publish announcement',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isEditing)
                      OutlinedButton.icon(
                        onPressed: _resetForm,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
