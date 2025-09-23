import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../providers/quotation_provider.dart';
import '../widgets/common_list_screen.dart';
import '../widgets/quote_list_item.dart';
import 'add_quote_screen.dart';
import 'settings_screen.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> {
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
      showSearch: quotesAsync.isNotEmpty,
      itemBuilder: (quote) => QuoteListItem(
        quote: quote,
        onEdit: () => _editQuote(quote),
        onDelete: () => _deleteQuote(quote),
      ),
      onAddPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddQuoteScreen()),
        );
      },
      onSettingsPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
      },
    );
  }

  void _editQuote(Quote quote) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddQuoteScreen(quote: quote)),
    );
  }

  void _deleteQuote(Quote quote) {
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
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quote deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
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
