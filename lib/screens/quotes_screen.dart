import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../providers/quotation_provider.dart';
import '../widgets/common_list_screen.dart';
import '../widgets/quote_list_item.dart';
import 'add_quote_screen.dart';
import 'groups_screen.dart';
import 'sources_screen.dart';

class QuotesScreen extends ConsumerStatefulWidget {
  const QuotesScreen({super.key});

  @override
  ConsumerState<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends ConsumerState<QuotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<Widget> _tabs = [
    const QuotesContent(),
    const GroupsScreen(),
    const SourcesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: _currentTabIndex);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.format_quote),
              text: 'Quotes',
            ),
            Tab(
              icon: Icon(Icons.folder),
              text: 'Groups',
            ),
            Tab(
              icon: Icon(Icons.library_books),
              text: 'Sources',
            ),
          ],
        ),
      ),
      body: _tabs[_currentTabIndex],
    );
  }
}

class QuotesContent extends ConsumerWidget {
  const QuotesContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
