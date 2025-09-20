import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../providers/quotation_provider.dart';
import 'add_quotation_screen.dart';

class BookDetailScreen extends ConsumerWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotationsAsync = ref.watch(quotationsByBookProvider(book.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddQuotationScreen(book: book),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (book.coverUrl != null)
                          Container(
                            width: 80,
                            height: 120,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(book.coverUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                book.title,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                book.author,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Chip(
                                label: Text(_getStatusDisplayName(book.status)),
                                backgroundColor: _getStatusColor(book.status),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (book.description != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(book.description!),
                    ],
                    if (book.totalPages != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Progress: '),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: book.progressPercentage / 100,
                              backgroundColor: Colors.grey[300],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${book.currentPage ?? 0}/${book.totalPages}'),
                        ],
                      ),
                    ],
                    if (book.rating != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Rating: '),
                          ...List.generate(5, (index) {
                            return Icon(
                              index < book.rating! ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 20,
                            );
                          }),
                          const SizedBox(width: 8),
                          Text('${book.rating!.toStringAsFixed(1)}/5'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Quotations Section
            Text(
              'Quotations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            quotationsAsync.when(
              data: (quotations) {
                if (quotations.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.format_quote_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No quotations yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the + button to add your first quotation',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: quotations.length,
                  itemBuilder: (context, index) {
                    final quotation = quotations[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quotation.content,
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (quotation.pageNumber != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Page ${quotation.pageNumber}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (quotation.hashtags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: quotation.hashtags.map((tag) {
                                  return Chip(
                                    label: Text('#$tag'),
                                    backgroundColor: Colors.blue[50],
                                    labelStyle: const TextStyle(fontSize: 12),
                                  );
                                }).toList(),
                              ),
                            ],
                            if (quotation.note != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                quotation.note!,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Error loading quotations: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusDisplayName(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.willRead:
        return 'Will Read';
    }
  }

  Color _getStatusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.willRead:
        return Colors.blue[100]!;
      case ReadingStatus.reading:
        return Colors.orange[100]!;
      case ReadingStatus.read:
        return Colors.green[100]!;
    }
  }
}
