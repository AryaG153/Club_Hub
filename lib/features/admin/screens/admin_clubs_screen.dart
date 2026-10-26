import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';
import '../admin_split_layout.dart';

class AdminClubsScreen extends StatefulWidget {
  const AdminClubsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<AdminClubsScreen> createState() => _AdminClubsScreenState();
}

class _AdminClubsScreenState extends State<AdminClubsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;
  String? _editingId;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _categoryController.text.trim();

    final wasEditing = _isEditing;
    setState(() => _isSaving = true);
    try {
      if (wasEditing && _editingId != null) {
        await widget.repository.updateClub(
          id: _editingId!,
          name: name,
          description: description,
          category: category,
        );
      } else {
        await widget.repository.createClub(
          name: name,
          description: description,
          category: category,
        );
      }
      if (!mounted) return;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasEditing ? 'Club updated.' : 'Club created.')),
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

  void _resetForm() {
    _nameController.clear();
    _descriptionController.clear();
    _categoryController.clear();
    _isEditing = false;
    _editingId = null;
    setState(() {});
  }

  void _editClub(Club club) {
    _nameController.text = club.name;
    _descriptionController.text = club.description;
    _categoryController.text = club.category;
    _isEditing = true;
    _editingId = club.id;
    setState(() {});
  }

  void _deleteClub(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete club?'),
        content: const Text(
          'This permanently removes the club and related data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.repository.deleteClub(id);
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

  Future<void> _setActive(Club club) async {
    try {
      await widget.repository.setClubActive(club.id, !club.isActive);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clubs = widget.repository.clubs;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Management'),
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
                    'All clubs',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: clubs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final club = clubs[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(club.icon)),
                          title: Text(club.name),
                          subtitle: Text(
                            '${club.category} • ${club.membershipCount} members'
                            '${club.isActive ? '' : ' • Inactive'}'
                            '${club.needsAdminReview ? ' • Needs name/details review' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _setActive(club),
                                tooltip: club.isActive
                                    ? 'Deactivate club'
                                    : 'Activate club',
                                icon: Icon(
                                  club.isActive
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editClub(club),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () => _deleteClub(club.id),
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
                      _isEditing ? 'Edit club' : 'Create club',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Club name'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Club name is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
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
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Category is required.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        _isSaving
                            ? 'Saving...'
                            : _isEditing
                            ? 'Save changes'
                            : 'Add club',
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
