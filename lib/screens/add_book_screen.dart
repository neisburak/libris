import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';

class AddBookScreen extends ConsumerStatefulWidget {
  final Book? book;

  const AddBookScreen({super.key, this.book});

  @override
  ConsumerState<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends ConsumerState<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _currentPageController = TextEditingController();
  final _ratingController = TextEditingController();

  ReadingStatus _selectedStatus = ReadingStatus.willRead;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final book = widget.book!;
    _titleController.text = book.title;
    _authorController.text = book.author;
    _descriptionController.text = book.description ?? '';
    _coverUrlController.text = book.coverUrl ?? '';
    _totalPagesController.text = book.totalPages?.toString() ?? '';
    _currentPageController.text = book.currentPage?.toString() ?? '';
    _ratingController.text = book.rating?.toString() ?? '';
    _selectedStatus = book.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _totalPagesController.dispose();
    _currentPageController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? 'Add Book' : 'Edit Book'),
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
              // Cover Image
              if (_coverUrlController.text.isNotEmpty)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_coverUrlController.text),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author
              TextFormField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Author *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an author';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Reading Status
              DropdownButtonFormField<ReadingStatus>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Reading Status',
                  border: OutlineInputBorder(),
                ),
                items: ReadingStatus.values.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(_getStatusDisplayName(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Cover URL
              TextFormField(
                controller: _coverUrlController,
                decoration: const InputDecoration(
                  labelText: 'Cover Image URL',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {}); // Trigger rebuild to show/hide cover image
                },
              ),
              const SizedBox(height: 16),

              // Total Pages and Current Page
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalPagesController,
                      decoration: const InputDecoration(
                        labelText: 'Total Pages',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _currentPageController,
                      decoration: const InputDecoration(
                        labelText: 'Current Page',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rating
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (1-5)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final rating = double.tryParse(value);
                    if (rating == null || rating < 1 || rating > 5) {
                      return 'Rating must be between 1 and 5';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveBook,
                child: Text(widget.book == null ? 'Add Book' : 'Update Book'),
              ),
            ],
          ),
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

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final book = Book(
        id: widget.book?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        coverUrl: _coverUrlController.text.trim().isEmpty 
            ? null 
            : _coverUrlController.text.trim(),
        status: _selectedStatus,
        createdAt: widget.book?.createdAt ?? now,
        updatedAt: now,
        totalPages: _totalPagesController.text.isEmpty 
            ? null 
            : int.tryParse(_totalPagesController.text),
        currentPage: _currentPageController.text.isEmpty 
            ? null 
            : int.tryParse(_currentPageController.text),
        rating: _ratingController.text.isEmpty 
            ? null 
            : double.tryParse(_ratingController.text),
      );

      final bookOperations = ref.read(bookOperationsProvider);
      
      if (widget.book == null) {
        await bookOperations.addBook(book);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book added successfully!')),
          );
        }
      } else {
        await bookOperations.updateBook(book);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Book updated successfully!')),
          );
        }
      }

      if (mounted) {
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
