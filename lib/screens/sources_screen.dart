import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source.dart' as models;
import '../models/group.dart';
import '../providers/source_provider.dart';
import '../providers/group_provider.dart';
import 'add_source_screen.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  final String? groupId; // Optional filter by group

  const SourcesScreen({super.key, this.groupId});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedGroupId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _selectedGroupId = widget.groupId ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupProvider);
    String groupName = '';

    if (widget.groupId != null) {
      groupName = groupsAsync.when(
        data: (groups) {
          final group = groups.firstWhere(
            (g) => g.id == widget.groupId,
            orElse: () => Group(
              id: '',
              name: 'Unknown Group',
              description: '',
              createdAt: DateTime.now(),
            ),
          );
          return group.name;
        },
        loading: () => 'Loading...',
        error: (_, __) => 'Unknown Group',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.groupId != null ? '$groupName Sources' : 'Sources',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: '📖 Books'),
            Tab(text: '🎥 Videos'),
            Tab(text: '📄 Articles'),
            Tab(text: '🎧 Podcasts'),
            Tab(text: '🌐 Websites'),
            Tab(text: '📝 Other'),
          ],
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSourcesList(_getFilteredSources()),
          _buildSourcesList(_getFilteredSourcesByType(models.SourceType.book)),
          _buildSourcesList(_getFilteredSourcesByType(models.SourceType.video)),
          _buildSourcesList(
            _getFilteredSourcesByType(models.SourceType.article),
          ),
          _buildSourcesList(
            _getFilteredSourcesByType(models.SourceType.podcast),
          ),
          _buildSourcesList(
            _getFilteredSourcesByType(models.SourceType.website),
          ),
          _buildSourcesList(_getFilteredSourcesByType(models.SourceType.other)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddSourceScreen(groupId: _selectedGroupId),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  List<models.Source> _getFilteredSources() {
    final sourcesAsync = ref.watch(sourceProvider);
    return sourcesAsync.when(
      data: (sources) {
        var filteredSources = sources;

        // Filter by group if selected
        if (_selectedGroupId.isNotEmpty) {
          filteredSources = filteredSources
              .where((source) => source.groupId == _selectedGroupId)
              .toList();
        }

        // Filter by search query
        final searchQuery = ref.watch(sourceSearchProvider);
        if (searchQuery.isNotEmpty) {
          filteredSources = filteredSources.where((source) {
            final lowerQuery = searchQuery.toLowerCase();
            return source.title.toLowerCase().contains(lowerQuery) ||
                source.source.toLowerCase().contains(lowerQuery) ||
                (source.notes?.toLowerCase().contains(lowerQuery) ?? false);
          }).toList();
        }

        return filteredSources;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<models.Source> _getFilteredSourcesByType(models.SourceType type) {
    final sourcesAsync = ref.watch(sourceProvider);
    return sourcesAsync.when(
      data: (sources) {
        var filteredSources = sources
            .where((source) => source.type == type)
            .toList();

        // Filter by group if selected
        if (_selectedGroupId.isNotEmpty) {
          filteredSources = filteredSources
              .where((source) => source.groupId == _selectedGroupId)
              .toList();
        }

        // Filter by search query
        final searchQuery = ref.watch(sourceSearchProvider);
        if (searchQuery.isNotEmpty) {
          filteredSources = filteredSources.where((source) {
            final lowerQuery = searchQuery.toLowerCase();
            return source.title.toLowerCase().contains(lowerQuery) ||
                source.source.toLowerCase().contains(lowerQuery) ||
                (source.notes?.toLowerCase().contains(lowerQuery) ?? false);
          }).toList();
        }

        return filteredSources;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  Widget _buildSourcesList(List<models.Source> sources) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              widget.groupId != null
                  ? 'No sources in this group'
                  : 'No sources found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              widget.groupId != null
                  ? 'Add sources to this group to get started'
                  : 'Add your first source to get started',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getTypeColor(source.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                source.typeIcon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            title: Text(
              source.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'by ${source.source}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                    if (source.groupId.isNotEmpty)
                      Consumer(
                        builder: (context, ref, child) {
                          final groupsAsync = ref.watch(groupProvider);
                          return groupsAsync.when(
                            data: (groups) {
                              final group = groups.firstWhere(
                                (g) => g.id == source.groupId,
                                orElse: () => Group(
                                  id: '',
                                  name: 'Unknown',
                                  description: '',
                                  createdAt: DateTime.now(),
                                ),
                              );
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  group.name,
                                  style: TextStyle(
                                    color: Colors.blue[800],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          );
                        },
                      ),
                  ],
                ),
                if (source.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    source.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Chip(
                      label: Text(
                        source.statusDisplayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(source.status),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text(
                        source.typeDisplayName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getTypeColor(
                        source.type,
                      ).withOpacity(0.2),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editSource(source);
                } else if (value == 'delete') {
                  _deleteSource(source);
                }
              },
            ),
            onTap: () {
              // Navigate to source details or quotes
              _navigateToSourceDetails(source);
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(models.SourceStatus status) {
    switch (status) {
      case models.SourceStatus.notStarted:
        return Colors.grey[300]!;
      case models.SourceStatus.inProgress:
        return Colors.blue[200]!;
      case models.SourceStatus.completed:
        return Colors.green[200]!;
      case models.SourceStatus.paused:
        return Colors.orange[200]!;
      case models.SourceStatus.abandoned:
        return Colors.red[200]!;
    }
  }

  Color _getTypeColor(models.SourceType type) {
    switch (type) {
      case models.SourceType.book:
        return Colors.brown;
      case models.SourceType.video:
        return Colors.red;
      case models.SourceType.article:
        return Colors.blue;
      case models.SourceType.podcast:
        return Colors.purple;
      case models.SourceType.website:
        return Colors.green;
      case models.SourceType.other:
        return Colors.grey;
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Sources'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            ref.read(sourceSearchProvider.notifier).state = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              ref.read(sourceSearchProvider.notifier).state = '';
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final groupsAsync = ref.watch(groupProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Group'),
        content: groupsAsync.when(
          data: (groups) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: const Text('All Groups'),
                value: '',
                groupValue: _selectedGroupId,
                onChanged: (value) {
                  setState(() {
                    _selectedGroupId = value!;
                  });
                },
              ),
              ...groups.map(
                (group) => RadioListTile<String>(
                  title: Text(group.name),
                  value: group.id,
                  groupValue: _selectedGroupId,
                  onChanged: (value) {
                    setState(() {
                      _selectedGroupId = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading groups'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedGroupId = '';
              });
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _editSource(models.Source source) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSourceScreen(source: source)),
    );
  }

  void _deleteSource(models.Source source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source'),
        content: Text(
          'Are you sure you want to delete "${source.title}"? This will also delete all quotes from this source.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(sourceProvider.notifier).deleteSource(source.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToSourceDetails(models.Source source) {
    // TODO: Navigate to source details or quotes screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for "${source.title}"')),
    );
  }
}
