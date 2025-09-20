import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../models/source.dart' as models;
import '../providers/quotation_provider.dart';
import '../providers/source_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Search'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Sources'),
            Tab(text: 'Quotes'),
            Tab(text: 'Hashtags'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search sources, quotes, or hashtags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // Search Results
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSourcesTab(),
                _buildQuotesTab(),
                _buildHashtagsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourcesTab() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search Sources',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Enter a search term to find sources',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<models.Source>>(
      future: Future.value(ref.read(sourceProvider.notifier).searchSources(_searchQuery)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final sources = snapshot.data ?? [];
        if (sources.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No sources found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
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
                leading: CircleAvatar(
                  child: Text(source.typeIcon),
                ),
                title: Text(
                  source.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('by ${source.source}'),
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
                onTap: () {
                  // TODO: Navigate to source details
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Viewing "${source.title}"')),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuotesTab() {
    if (_searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search Quotes',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Enter a search term to find quotes',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Quote>>(
      stream: ref.read(quotesProvider.stream).map((quotes) => 
          quotes.where((quote) => quote.matchesSearch(_searchQuery)).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final quotes = snapshot.data ?? [];
        if (quotes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No quotes found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: quotes.length,
          itemBuilder: (context, index) {
            final quote = quotes[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quote.quote,
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '— Source ID: ${quote.sourceId}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (quote.hashtags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: quote.hashtags.map((tag) {
                          return Chip(
                            label: Text(
                              '#$tag',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Colors.blue[100],
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHashtagsTab() {
    return FutureBuilder<List<String>>(
      future: ref.read(allHashtagsProvider.future),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final hashtags = snapshot.data ?? [];
        if (hashtags.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tag, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hashtags yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Add hashtags to your quotes',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filter hashtags based on search query
        final filteredHashtags = _searchQuery.isEmpty
            ? hashtags
            : hashtags.where((tag) => 
                tag.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredHashtags.length,
          itemBuilder: (context, index) {
            final hashtag = filteredHashtags[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.tag),
                title: Text('#$hashtag'),
                onTap: () {
                  // TODO: Show quotes with this hashtag
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Showing quotes with #$hashtag')),
                  );
                },
              ),
            );
          },
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
}