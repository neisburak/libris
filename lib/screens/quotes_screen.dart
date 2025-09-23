import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../providers/quotation_provider.dart';
import '../widgets/common_list_screen.dart';
import '../widgets/quote_list_item.dart';
import 'add_quote_screen.dart';
import 'sources_screen.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotesAsync = ref.watch(filteredQuotesProvider);
    
    return CommonListScreen<Quote>(
      title: 'Quotes',
      searchHint: 'Search quotes...',
      emptyStateTitle: 'No quotes yet',
      emptyStateSubtitle: 'Add your first quote to get started',
      searchEmptyTitle: 'No quotes found',
      searchEmptySubtitle: 'Try a different search term',
      emptyStateIcon: Icons.format_quote,
      items: quotesAsync,
      showSearch: true,
      searchWidget: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(8),
          hintText: 'Search quotes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(quoteSearchProvider.notifier).state = '';
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
          ref.read(quoteSearchProvider.notifier).state = value;
        },
        onChanged: (value) {
          ref.read(quoteSearchProvider.notifier).state = value;
          setState(() {}); // Rebuild to show/hide clear button
        },
      ),
      itemBuilder: (quote) => QuoteListItem(
        quote: quote,
        onEdit: () => _editQuote(context, quote),
        onDelete: () => _deleteQuote(context, ref, quote),
      ),
      onAddPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddQuoteScreen()),
        );
      },
      onFilterPressed: () {
        // Navigate to Sources
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SourcesScreen()),
        );
      },
    );
  }

  void _editQuote(BuildContext context, Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddQuoteScreen(quote: quote)),
    );
  }

  void _deleteQuote(BuildContext context, WidgetRef ref, Quote quote) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quote'),
        content: Text(
          'Are you sure you want to delete this quote?\n\n"${quote.quote.length > 100 ? '${quote.quote.substring(0, 100)}...' : quote.quote}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(quoteOperationsProvider).deleteQuote(quote.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quote deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting quote: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
