import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/quote.dart';
import '../models/source.dart' as models;
import '../providers/quotation_provider.dart';
import '../providers/source_provider.dart';

class AddQuoteScreen extends ConsumerStatefulWidget {
  final Quote? quote; // For editing existing quote
  final String? sourceId; // Pre-select source

  const AddQuoteScreen({super.key, this.quote, this.sourceId});

  @override
  ConsumerState<AddQuoteScreen> createState() => _AddQuoteScreenState();
}

class _AddQuoteScreenState extends ConsumerState<AddQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _pageNumberController = TextEditingController();
  final _hashtagController = TextEditingController();

  models.Source? _selectedSource;
  List<String> _hashtags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.quote != null) {
      _quoteController.text = widget.quote!.quote;
      _pageNumberController.text = widget.quote!.pageNumber?.toString() ?? '';
      _hashtags = List.from(widget.quote!.hashtags);
    }
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _pageNumberController.dispose();
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourcesAsync = ref.watch(sourceProvider);
    final isEditing = widget.quote != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Quote' : 'Add Quote'),
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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Source Selection
              Consumer(
                builder: (context, ref, child) {
                  return sourcesAsync.when(
                    data: (sources) => DropdownButtonFormField<models.Source>(
                      value: _selectedSource,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.library_books),
                      ),
                      items: sources.map((source) {
                        return DropdownMenuItem<models.Source>(
                          value: source,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(source.typeIcon),
                              const SizedBox(width: 8),
                              Flexible(child: Text(source.title)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSource = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a source';
                        }
                        return null;
                      },
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (_, __) => const Text('Error loading sources'),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Quote Content
              TextFormField(
                controller: _quoteController,
                decoration: const InputDecoration(
                  labelText: 'Quote',
                  hintText: 'Enter the quote text',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_quote),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quote';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),

              // Page Number (for books and articles)
              if (_selectedSource?.type == models.SourceType.book || 
                  _selectedSource?.type == models.SourceType.article)
                TextFormField(
                  controller: _pageNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Page Number',
                    hintText: 'Enter page number (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bookmark),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final pageNum = int.tryParse(value);
                      if (pageNum == null || pageNum < 1) {
                        return 'Please enter a valid page number';
                      }
                    }
                    return null;
                  },
                ),
              if (_selectedSource?.type == models.SourceType.book || 
                  _selectedSource?.type == models.SourceType.article)
                const SizedBox(height: 16),

              // Hashtags
              TextFormField(
                controller: _hashtagController,
                decoration: InputDecoration(
                  labelText: 'Hashtags',
                  hintText: 'Enter hashtags separated by spaces',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.tag),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _addHashtag,
                  ),
                ),
                onFieldSubmitted: (_) => _addHashtag(),
              ),
              const SizedBox(height: 8),

              // Display hashtags
              if (_hashtags.isNotEmpty) ...[
                Wrap(
                  spacing: 4,
                  children: _hashtags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      onDeleted: () => _removeHashtag(tag),
                      backgroundColor: Colors.blue[100],
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveQuote,
                child: Text(isEditing ? 'Update Quote' : 'Add Quote'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _addHashtag() {
    final tag = _hashtagController.text.trim();
    if (tag.isNotEmpty && !_hashtags.contains(tag)) {
      setState(() {
        _hashtags.add(tag);
        _hashtagController.clear();
      });
    }
  }

  void _removeHashtag(String tag) {
    setState(() {
      _hashtags.remove(tag);
    });
  }

  Future<void> _saveQuote() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a source'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final quote = Quote(
        id: widget.quote?.id ?? const Uuid().v4(),
        sourceId: _selectedSource!.id,
        quote: _quoteController.text.trim(),
        pageNumber: _pageNumberController.text.isEmpty 
            ? null 
            : int.tryParse(_pageNumberController.text),
        hashtags: _hashtags,
        createdAt: widget.quote?.createdAt ?? DateTime.now(),
      );

      if (widget.quote != null) {
        await ref.read(quoteOperationsProvider).updateQuote(quote);
      } else {
        await ref.read(quoteOperationsProvider).addQuote(quote);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.quote != null ? 'Quote updated successfully' : 'Quote added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
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
