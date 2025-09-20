import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/source.dart';
import '../models/group.dart';
import '../providers/source_provider.dart';
import '../providers/group_provider.dart';
import 'add_source_screen.dart';
import 'source_detail_screen.dart';
import 'settings_screen.dart';

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
    final sourcesAsync = ref.watch(sourceProvider);
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
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
      body: Column(
        children: [
          // Search Input - Always visible when there are sources
          if (sourcesAsync.when(
            data: (sources) => sources.isNotEmpty,
            loading: () => false,
            error: (_, __) => false,
          ))
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.all(8),
                  hintText: 'Search sources...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(sourceSearchProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                onSubmitted: (value) {
                  ref.read(sourceSearchProvider.notifier).state = value;
                },
                onChanged: (value) {
                  ref.read(sourceSearchProvider.notifier).state = value;
                  setState(() {}); // Rebuild to show/hide clear button
                },
              ),
            ),
          // TabBarView
          Expanded(
            child: TabBarView(
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
          ),
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
        return Slidable(
          key: ValueKey(source.id),
          endActionPane: ActionPane(
            motion: const ScrollMotion(),
            children: [
              SlidableAction(
                // An action can be bigger than the others.
                onPressed: (_) => _editSource(source),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'Update',
              ),
              SlidableAction(
                onPressed: (_) => _deleteSource(source),
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'Delete',
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Text(
                  source.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getTypeColor(source.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    source.typeDisplayName,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        source.source,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (source.hasGroups)
                  Consumer(
                    builder: (context, ref, child) {
                      final groupsAsync = ref.watch(groupProvider);
                      return groupsAsync.when(
                        data: (groups) {
                          return Wrap(
                            spacing: 4,
                            runSpacing: 2,
                            children: source.groupIds.map((groupId) {
                              final group = groups.firstWhere(
                                (g) => g.id == groupId,
                                orElse: () => Group(
                                  id: '',
                                  name: 'Unknown',
                                  description: '',
                                  createdAt: DateTime.now(),
                                ),
                              );
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  group.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
              ],
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

  Color _getTypeColor(SourceType type) {
    switch (type) {
      case SourceType.book:
        return Colors.brown;
      case SourceType.video:
        return Colors.red;
      case SourceType.article:
        return Colors.blue;
      case SourceType.podcast:
        return Colors.purple;
      case SourceType.website:
        return Colors.green;
      case SourceType.other:
        return Colors.grey;
    }
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
