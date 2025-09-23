import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Generic list screen widget that can be used for groups, quotes, and sources
class CommonListScreen<T> extends ConsumerStatefulWidget {
  final String title;
  final String searchHint;
  final String emptyStateTitle;
  final String emptyStateSubtitle;
  final String searchEmptyTitle;
  final String searchEmptySubtitle;
  final IconData emptyStateIcon;
  final List<T> items;
  final bool showSearch;
  final Widget Function(T item) itemBuilder;
  final VoidCallback? onAddPressed;
  final VoidCallback? onFilterPressed;
  final Widget? searchWidget;

  const CommonListScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.emptyStateTitle,
    required this.emptyStateSubtitle,
    required this.searchEmptyTitle,
    required this.searchEmptySubtitle,
    required this.emptyStateIcon,
    required this.items,
    required this.itemBuilder,
    this.showSearch = true,
    this.onAddPressed,
    this.onFilterPressed,
    this.searchWidget,
  });

  @override
  ConsumerState<CommonListScreen<T>> createState() =>
      _CommonListScreenState<T>();
}

class _CommonListScreenState<T> extends ConsumerState<CommonListScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSearchAtTop = false;
  double _lastScrollPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.showSearch || widget.items.isEmpty) return;

    final currentPosition = _scrollController.position.pixels;
    final isScrollingUp = currentPosition < _lastScrollPosition;

    // Show search bar when scrolling up
    if (isScrollingUp && currentPosition > 50) {
      if (!_showSearchAtTop) {
        setState(() {
          _showSearchAtTop = true;
        });
      }
    } else if (!isScrollingUp && currentPosition > 100) {
      // Hide search bar when scrolling down and past 100px
      if (_showSearchAtTop) {
        setState(() {
          _showSearchAtTop = false;
        });
      }
    }

    _lastScrollPosition = currentPosition;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (widget.onFilterPressed != null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: widget.onFilterPressed,
            ),
          if (widget.onAddPressed != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: widget.onAddPressed,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Input - Show at top when scrolling up or when there are no items
          if (widget.showSearch && (widget.items.isEmpty || _showSearchAtTop))
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child:
                  widget.searchWidget ??
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(8),
                      hintText: widget.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(
                                  () {},
                                ); // Rebuild to show/hide clear button
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
                    onChanged: (value) {
                      setState(() {}); // Rebuild to show/hide clear button
                    },
                  ),
            ),
          // Items List - Always scrollable when there are items
          Expanded(
            child: widget.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.emptyStateIcon,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchController.text.isNotEmpty
                              ? widget.searchEmptyTitle
                              : widget.emptyStateTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isNotEmpty
                              ? widget.searchEmptySubtitle
                              : widget.emptyStateSubtitle,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: widget.items.length,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return widget.itemBuilder(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Generic slidable list item widget
class SlidableListItem<T> extends StatelessWidget {
  final T item;
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String editLabel;
  final String deleteLabel;
  final Color? editColor;
  final Color? deleteColor;

  const SlidableListItem({
    super.key,
    required this.item,
    required this.child,
    this.onEdit,
    this.onDelete,
    this.editLabel = 'Update',
    this.deleteLabel = 'Delete',
    this.editColor,
    this.deleteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey(_getItemId(item)),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (onEdit != null)
            SlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: editColor ?? Colors.green.shade600,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: editLabel,
            ),
          if (onDelete != null)
            SlidableAction(
              onPressed: (_) => onDelete!(),
              backgroundColor: deleteColor ?? Colors.red.shade600,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: deleteLabel,
            ),
        ],
      ),
      child: child,
    );
  }

  String _getItemId(T item) {
    // Try to get id property using reflection-like approach
    if (item is Map) {
      return item['id']?.toString() ?? '';
    }
    // For objects with id property, we'll need to handle this in the specific implementations
    return item.hashCode.toString();
  }
}

/// Mixin for common list screen functionality
mixin CommonListScreenMixin<T> {
  String get searchQuery;
  set searchQuery(String value);

  List<T> get filteredItems;

  void onSearchChanged(String query) {
    searchQuery = query;
  }

  void clearSearch() {
    searchQuery = '';
  }
}
