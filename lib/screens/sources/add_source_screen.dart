import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/source.dart' as models;
import '../../models/group.dart';
import '../../providers/source_provider.dart';
import '../../providers/group_provider.dart';

class AddSourceScreen extends ConsumerStatefulWidget {
  final models.Source? source; // For editing existing source
  final String? groupId; // Pre-select group

  const AddSourceScreen({super.key, this.source, this.groupId});

  @override
  ConsumerState<AddSourceScreen> createState() => _AddSourceScreenState();
}

class _AddSourceScreenState extends ConsumerState<AddSourceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController(); // Author/Creator
  final _urlController = TextEditingController();
  final _notesController = TextEditingController();

  models.SourceType _selectedType = models.SourceType.book;
  models.SourceStatus _selectedStatus = models.SourceStatus.notStarted;
  List<String> _selectedGroupIds = [];
  DateTime? _startDate;
  DateTime? _finishDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.groupId != null) {
      _selectedGroupIds = [widget.groupId!];
    }

    if (widget.source != null) {
      _titleController.text = widget.source!.title;
      _sourceController.text = widget.source!.source;
      _urlController.text = widget.source!.url ?? '';
      _notesController.text = widget.source!.notes ?? '';
      _selectedType = widget.source!.type;
      _selectedStatus = widget.source!.status;
      _selectedGroupIds = List.from(widget.source!.groupIds);
      _startDate = widget.source!.startDate;
      _finishDate = widget.source!.finishDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    _urlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.source != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Source' : 'Add Source'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Group Selection
              Consumer(
                builder: (context, ref, child) {
                  final groupsAsync = ref.watch(groupProvider);
                  return groupsAsync.when(
                    data: (groups) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Groups',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_selectedGroupIds.isEmpty)
                                const Text(
                                  'No groups selected',
                                  style: TextStyle(color: Colors.grey),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _selectedGroupIds.map((groupId) {
                                    final group = groups.firstWhere(
                                      (g) => g.id == groupId,
                                      orElse: () => Group(
                                        id: '',
                                        name: 'Unknown',
                                        description: '',
                                        createdAt: DateTime.now(),
                                      ),
                                    );
                                    return Chip(
                                      label: Text(group.name),
                                      onDeleted: () {
                                        setState(() {
                                          _selectedGroupIds.remove(groupId);
                                        });
                                      },
                                      deleteIcon: const Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _showGroupSelectionDialog(groups),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Groups'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1),
                                  foregroundColor: Theme.of(
                                    context,
                                  ).primaryColor,
                                  elevation: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading groups'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Type Selection
              DropdownButtonFormField<models.SourceType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: models.SourceType.values.map((type) {
                  return DropdownMenuItem<models.SourceType>(
                    value: type,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getTypeIcon(type)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(_getTypeDisplayName(type)),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter source title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Source (Author/Creator)
              TextFormField(
                controller: _sourceController,
                decoration: InputDecoration(
                  labelText: _getSourceLabel(),
                  hintText: _getSourceHint(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter ${_getSourceLabel().toLowerCase()}';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // URL (for non-book sources)
              if (_selectedType != models.SourceType.book)
                TextFormField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Enter URL (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
              if (_selectedType != models.SourceType.book)
                const SizedBox(height: 16),

              // Status
              DropdownButtonFormField<models.SourceStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.flag),
                ),
                items: models.SourceStatus.values.map((status) {
                  return DropdownMenuItem<models.SourceStatus>(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  _startDate != null
                      ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _startDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _startDate = date;
                    });
                  }
                },
              ),

              // Finish Date
              ListTile(
                title: const Text('Finish Date'),
                subtitle: Text(
                  _finishDate != null
                      ? '${_finishDate!.day}/${_finishDate!.month}/${_finishDate!.year}'
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _finishDate ?? DateTime.now(),
                    firstDate: _startDate ?? DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _finishDate = date;
                    });
                  }
                },
              ),

              // Notes
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Enter notes (optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveSource,
                child: Text(isEditing ? 'Update Source' : 'Create Source'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getSourceLabel() {
    switch (_selectedType) {
      case models.SourceType.book:
        return 'Author';
      case models.SourceType.video:
        return 'Creator';
      case models.SourceType.article:
        return 'Author';
      case models.SourceType.podcast:
        return 'Host';
      case models.SourceType.website:
        return 'Creator';
      case models.SourceType.other:
        return 'Creator';
    }
  }

  String _getSourceHint() {
    switch (_selectedType) {
      case models.SourceType.book:
        return 'Enter author name';
      case models.SourceType.video:
        return 'Enter creator name';
      case models.SourceType.article:
        return 'Enter author name';
      case models.SourceType.podcast:
        return 'Enter host name';
      case models.SourceType.website:
        return 'Enter creator name';
      case models.SourceType.other:
        return 'Enter creator name';
    }
  }

  String _getTypeIcon(models.SourceType type) {
    switch (type) {
      case models.SourceType.book:
        return '📖';
      case models.SourceType.video:
        return '🎥';
      case models.SourceType.article:
        return '📄';
      case models.SourceType.podcast:
        return '🎧';
      case models.SourceType.website:
        return '🌐';
      case models.SourceType.other:
        return '📝';
    }
  }

  String _getTypeDisplayName(models.SourceType type) {
    switch (type) {
      case models.SourceType.book:
        return 'Book';
      case models.SourceType.video:
        return 'Video';
      case models.SourceType.article:
        return 'Article';
      case models.SourceType.podcast:
        return 'Podcast';
      case models.SourceType.website:
        return 'Website';
      case models.SourceType.other:
        return 'Other';
    }
  }

  String _getStatusDisplayName(models.SourceStatus status) {
    switch (status) {
      case models.SourceStatus.notStarted:
        return 'Not Started';
      case models.SourceStatus.inProgress:
        return 'In Progress';
      case models.SourceStatus.completed:
        return 'Completed';
      case models.SourceStatus.paused:
        return 'Paused';
      case models.SourceStatus.abandoned:
        return 'Abandoned';
    }
  }

  Future<void> _saveSource() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final source = models.Source(
        id: widget.source?.id ?? const Uuid().v4(),
        groupIds: _selectedGroupIds,
        type: _selectedType,
        title: _titleController.text.trim(),
        source: _sourceController.text.trim(),
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        status: _selectedStatus,
        startDate: _startDate,
        finishDate: _finishDate,
        createdAt: widget.source?.createdAt ?? DateTime.now(),
      );

      if (widget.source != null) {
        await ref.read(sourceProvider.notifier).updateSource(source);
      } else {
        await ref.read(sourceProvider.notifier).addSource(source);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.source != null
                  ? 'Source updated successfully'
                  : 'Source created successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showGroupSelectionDialog(List<Group> groups) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Groups'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final isSelected = _selectedGroupIds.contains(group.id);

              return CheckboxListTile(
                title: Text(group.name),
                subtitle: group.description.isNotEmpty
                    ? Text(
                        group.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      if (!_selectedGroupIds.contains(group.id)) {
                        _selectedGroupIds.add(group.id);
                      }
                    } else {
                      _selectedGroupIds.remove(group.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
