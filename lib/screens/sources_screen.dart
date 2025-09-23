import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source.dart';
import '../models/group.dart';
import '../providers/source_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/source_list_item.dart';
import 'add_source_screen.dart';
import 'source_detail_screen.dart';

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
        title: Text(widget.groupId != null ? '$groupName Sources' : 'Sources'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddSourceScreen(
                    groupId: _selectedGroupId.isNotEmpty
                        ? _selectedGroupId
                        : null,
                  ),
                ),
              );
            },
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
          _buildSourcesList(_getFilteredSourcesByType(SourceType.book)),
          _buildSourcesList(_getFilteredSourcesByType(SourceType.video)),
          _buildSourcesList(_getFilteredSourcesByType(SourceType.article)),
          _buildSourcesList(_getFilteredSourcesByType(SourceType.podcast)),
          _buildSourcesList(_getFilteredSourcesByType(SourceType.website)),
          _buildSourcesList(_getFilteredSourcesByType(SourceType.other)),
        ],
      ),
    );
  }

  List<Source> _getFilteredSources() {
    final sourcesAsync = ref.watch(sourceProvider);
    return sourcesAsync.when(
      data: (sources) {
        var filteredSources = sources;

        // Filter by group if selected
        if (_selectedGroupId.isNotEmpty) {
          filteredSources = filteredSources
              .where((source) => source.isInGroup(_selectedGroupId))
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

  List<Source> _getFilteredSourcesByType(SourceType type) {
    final sourcesAsync = ref.watch(sourceProvider);
    return sourcesAsync.when(
      data: (sources) {
        var filteredSources = sources
            .where((source) => source.type == type)
            .toList();

        // Filter by group if selected
        if (_selectedGroupId.isNotEmpty) {
          filteredSources = filteredSources
              .where((source) => source.isInGroup(_selectedGroupId))
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

  Widget _buildSourcesList(List<Source> sources) {
    if (sources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              ref.watch(sourceSearchProvider).isNotEmpty
                  ? 'No sources found'
                  : widget.groupId != null
                      ? 'No sources in this group'
                      : 'No sources found',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              ref.watch(sourceSearchProvider).isNotEmpty
                  ? 'Try a different search term'
                  : widget.groupId != null
                      ? 'Add sources to this group to get started'
                      : 'Add your first source to get started',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return SourceListItem(
          source: source,
          onTap: () => _navigateToSourceDetails(source),
          onEdit: () => _editSource(source),
          onDelete: () => _deleteSource(source),
        );
      },
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

  void _editSource(Source source) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddSourceScreen(source: source)),
    );
  }

  void _deleteSource(Source source) {
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

  void _navigateToSourceDetails(Source source) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SourceDetailScreen(source: source),
      ),
    );
  }
}