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
            orElse: () => Group(id: '', name: 'Unknown Group', description: '', createdAt: DateTime.now()),
          );
          return group.name;
        },
        loading: () => 'Loading...',
        error: (_, __) => 'Unknown Group',
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupId != null ? 'Sources in "$groupName"' : 'Sources'),
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sources found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Add your first source to get started',
              style: TextStyle(color: Colors.grey),
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
          child: ListTile(
            leading: CircleAvatar(child: Text(source.typeIcon)),
            title: Text(
              source.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('by ${source.source}'),
                if (source.notes?.isNotEmpty == true)
                  Text(
                    source.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                Row(
                  children: [
                    Chip(
                      label: Text(source.statusDisplayName),
                      backgroundColor: _getStatusColor(source.status),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(source.typeDisplayName),
                      backgroundColor: Colors.blue[100],
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
