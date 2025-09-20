import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import 'add_book_screen.dart';
import 'book_detail_screen.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddBookScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No books yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first book',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Will Read'),
                    Tab(text: 'Reading'),
                    Tab(text: 'Read'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildBookList(books.where((b) => b.status == ReadingStatus.willRead).toList()),
                      _buildBookList(books.where((b) => b.status == ReadingStatus.reading).toList()),
                      _buildBookList(books.where((b) => b.status == ReadingStatus.read).toList()),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading books',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookList(List<Book> books) {
    if (books.isEmpty) {
      return const Center(
        child: Text(
          'No books in this category',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(book.status),
              child: Text(
                book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              book.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.author),
                if (book.status == ReadingStatus.reading && book.totalPages != null)
                  LinearProgressIndicator(
                    value: book.progressPercentage / 100,
                    backgroundColor: Colors.grey[300],
                  ),
                if (book.status == ReadingStatus.reading && book.totalPages != null)
                  Text(
                    '${book.currentPage ?? 0}/${book.totalPages} pages',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddBookScreen(book: book),
                    ),
                  );
                } else if (value == 'delete') {
                  await _showDeleteDialog(context, book);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailScreen(book: book),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.willRead:
        return Colors.blue;
      case ReadingStatus.reading:
        return Colors.orange;
      case ReadingStatus.read:
        return Colors.green;
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, Book book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"? This will also delete all associated quotations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete book logic would go here
      // This will be handled by the provider
    }
  }
}
