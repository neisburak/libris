import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source.dart' as models;
import '../providers/source_provider.dart';
import 'add_source_screen.dart';

class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.library_books)),
            Tab(text: '📖 Books', icon: Icon(Icons.book)),
            Tab(text: '🎥 Videos', icon: Icon(Icons.video_library)),
            Tab(text: '📄 Articles', icon: Icon(Icons.article)),
            Tab(text: '🎧 Podcasts', icon: Icon(Icons.headphones)),
            Tab(text: '🌐 Websites', icon: Icon(Icons.web)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddSourceScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSourcesList(ref.watch(filteredSourcesProvider)),
          _buildSourcesList(ref.watch(bookSourcesProvider)),
          _buildSourcesList(ref.watch(videoSourcesProvider)),
          _buildSourcesList(ref.watch(articleSourcesProvider)),
          _buildSourcesList(ref.watch(podcastSourcesProvider)),
          _buildSourcesList(ref.watch(filteredSourcesProvider).where((s) => s.type == models.SourceType.website).toList()),
        ],
      ),
    );
  }

  Widget _buildSourcesList(List<models.Source> sources) {
    if (sources.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.library_books, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No sources found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the + button to add a source',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sources.length,
      itemBuilder: (context, index) {
        final source = sources[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(source.typeIcon),
            ),
            title: Text(source.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('by ${source.author}'),
                if (source.description != null)
                  Text(
                    source.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                Row(
                  children: [
                    Chip(
                      label: Text(source.typeDisplayName),
                      backgroundColor: _getTypeColor(source.type).withOpacity(0.2),
                    ),
                    if (source.rating != null) ...[
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          return Icon(
                            i < source.rating!.round() ? Icons.star : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete'),
                    contentPadding: EdgeInsets.zero,
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
              // Navigate to source details or quotations
            },
          ),
        );
      },
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Sources'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search by title, author, or description...',
            border: OutlineInputBorder(),
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
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editSource(models.Source source) {
    // Navigate to edit source screen
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  void _deleteSource(models.Source source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Source'),
        content: Text('Are you sure you want to delete "${source.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(sourceProvider.notifier).deleteSource(source.id);
              if (mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Source deleted successfully!')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(models.SourceType type) {
    switch (type) {
      case models.SourceType.book:
        return Colors.blue;
      case models.SourceType.video:
        return Colors.red;
      case models.SourceType.article:
        return Colors.green;
      case models.SourceType.podcast:
        return Colors.purple;
      case models.SourceType.website:
        return Colors.orange;
      case models.SourceType.other:
        return Colors.grey;
    }
  }
}
