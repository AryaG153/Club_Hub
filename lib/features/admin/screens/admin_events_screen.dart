import 'package:flutter/material.dart';

import '../../../data/demo_repository.dart';
import '../../../models/clubhub_models.dart';
import '../admin_split_layout.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({
    super.key,
    required this.repository,
    required this.onToggleTheme,
  });

  final ClubHubDemoRepository repository;
  final VoidCallback onToggleTheme;

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _organizerController = TextEditingController();
  String? _selectedClubId;
  DateTime? _selectedDateTime;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _editingId;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a club.')));
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date and time.')),
      );
      return;
    }

    final wasEditing = _isEditing;
    setState(() => _isSaving = true);
    try {
      if (wasEditing && _editingId != null) {
        await widget.repository.updateEvent(
          id: _editingId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          clubId: _selectedClubId!,
          venue: _venueController.text.trim(),
          organizer: _organizerController.text.trim(),
          dateTime: _selectedDateTime!,
        );
      } else {
        await widget.repository.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          clubId: _selectedClubId!,
          venue: _venueController.text.trim(),
          organizer: _organizerController.text.trim(),
          dateTime: _selectedDateTime!,
        );
      }
      if (!mounted) return;
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(wasEditing ? 'Event updated.' : 'Event created.'),
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

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _venueController.clear();
    _organizerController.clear();
    _selectedClubId = widget.repository.clubs.firstOrNull?.id;
    _selectedDateTime = DateTime.now().add(const Duration(days: 1));
    _isEditing = false;
    _editingId = null;
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? now),
    );
    if (!mounted || time == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _editEvent(EventItem item) {
    _titleController.text = item.title;
    _descriptionController.text = item.description;
    _venueController.text = item.venue;
    _organizerController.text = item.organizer;
    _selectedClubId = item.clubId;
    _selectedDateTime = item.dateTime;
    _isEditing = true;
    _editingId = item.id;
    setState(() {});
  }

  void _deleteEvent(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: const Text(
          'This permanently removes the event and registrations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await widget.repository.deleteEvent(id);
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

  Future<void> _setEventActive(EventItem event) async {
    try {
      await widget.repository.setEventActive(event.id, !event.isActive);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedClubId = widget.repository.clubs.firstOrNull?.id;
    _selectedDateTime = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _organizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.repository.events;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Management'),
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
                    'All events',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: events.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event.title),
                          subtitle: Text(
                            '${event.venue} • ${event.organizer}'
                            '${event.isActive ? '' : ' • Inactive'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () => _setEventActive(event),
                                tooltip: event.isActive
                                    ? 'Deactivate event'
                                    : 'Activate event',
                                icon: Icon(
                                  event.isActive
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _editEvent(event),
                                icon: const Icon(Icons.edit_rounded),
                              ),
                              IconButton(
                                onPressed: () => _deleteEvent(event.id),
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
                      _isEditing ? 'Edit event' : 'Create event',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedClubId,
                      decoration: const InputDecoration(
                        labelText: 'Select club',
                      ),
                      items: widget.repository.clubs
                          .where((club) => club.isActive)
                          .map(
                            (club) => DropdownMenuItem(
                              value: club.id,
                              child: Text(club.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedClubId = value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Event title',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Event title is required.'
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
                      controller: _venueController,
                      decoration: const InputDecoration(labelText: 'Venue'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Venue is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _organizerController,
                      decoration: const InputDecoration(labelText: 'Organizer'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Organizer is required.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Date & time'),
                      subtitle: Text(
                        _selectedDateTime == null
                            ? 'Choose a time'
                            : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} • ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today_rounded),
                      onTap: _pickDateTime,
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
                            : 'Add event',
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
