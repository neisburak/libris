import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/quotation.dart';
import '../providers/book_provider.dart';
import '../providers/quotation_provider.dart';

class AddQuotationScreen extends ConsumerStatefulWidget {
  final Book? book;

  const AddQuotationScreen({super.key, this.book});

  @override
  ConsumerState<AddQuotationScreen> createState() => _AddQuotationScreenState();
}

class _AddQuotationScreenState extends ConsumerState<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _pageNumberController = TextEditingController();
  final _hashtagsController = TextEditingController();
  final _noteController = TextEditingController();

  Book? _selectedBook;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedBook = widget.book;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageNumberController.dispose();
    _hashtagsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Quotation'),
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Selection
              booksAsync.when(
                data: (books) {
                  if (books.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.library_books_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No books available',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Add a book first to create quotations',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Go to Books'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<Book>(
                    value: _selectedBook,
                    decoration: const InputDecoration(
                      labelText: 'Select Book *',
                      border: OutlineInputBorder(),
                    ),
                    items: books.map((book) {
                      return DropdownMenuItem(
                        value: book,
                        child: Text(book.title),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedBook = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a book';
                      }
                      return null;
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error loading books: ${error.toString()}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quotation Content
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Quotation *',
                  border: OutlineInputBorder(),
                  hintText: 'Enter the quotation text...',
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quotation';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Page Number
              TextFormField(
                controller: _pageNumberController,
                decoration: const InputDecoration(
                  labelText: 'Page Number',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              // Hashtags
              TextFormField(
                controller: _hashtagsController,
                decoration: const InputDecoration(
                  labelText: 'Hashtags',
                  border: OutlineInputBorder(),
                  hintText: 'Enter hashtags separated by spaces (e.g., inspiration motivation)',
                  helperText: 'Enter hashtags without the # symbol',
                ),
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  hintText: 'Add a personal note about this quotation...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveQuotation,
                child: const Text('Save Quotation'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQuotation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBook == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a book')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final hashtags = _hashtagsController.text
          .trim()
          .split(' ')
          .where((tag) => tag.isNotEmpty)
          .map((tag) => tag.toLowerCase())
          .toList();

      final quotation = Quotation(
        id: const Uuid().v4(),
        bookId: _selectedBook!.id,
        bookTitle: _selectedBook!.title,
        content: _contentController.text.trim(),
        pageNumber: _pageNumberController.text.isEmpty 
            ? null 
            : int.tryParse(_pageNumberController.text),
        hashtags: hashtags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        note: _noteController.text.trim().isEmpty 
            ? null 
            : _noteController.text.trim(),
      );

      final quotationOperations = ref.read(quotationOperationsProvider);
      await quotationOperations.addQuotation(quotation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation added successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
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
}
