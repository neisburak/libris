import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/quotation_provider.dart';
import 'add_quote_screen.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(filteredQuotesProvider);
    final searchQuery = ref.watch(quoteSearchProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddQuoteScreen()),
              );
            },
          ),
        ],
      ),
      body: quotesAsync.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    searchQuery.isEmpty ? 'No quotes yet' : 'No quotes found',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    searchQuery.isEmpty
                        ? 'Add your first quote to get started'
                        : 'Try a different search term',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: quotesAsync.length,
              itemBuilder: (context, index) {
                final quote = quotesAsync[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quote content
                        Text(
                          quote.quote,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Source info and page number
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '— Source ID: ${quote.sourceId}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (quote.pageNumber != null)
                              Text(
                                'Page ${quote.pageNumber}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),

                        // Hashtags
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
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],

                        // Created date
                        const SizedBox(height: 8),
                        Text(
                          'Added ${_formatDate(quote.createdAt)}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Quotes'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search term...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            ref.read(quoteSearchProvider.notifier).state = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(quoteSearchProvider.notifier).state = '';
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
