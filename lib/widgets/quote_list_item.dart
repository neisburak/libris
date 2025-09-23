import 'package:flutter/material.dart';
import '../models/quote.dart';
import 'common_list_screen.dart';

class QuoteListItem extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const QuoteListItem({
    super.key,
    required this.quote,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableListItem<Quote>(
      item: quote,
      onEdit: onEdit,
      onDelete: onDelete,
      child: ListTile(
        title: Text(
          quote.quote,
          style: const TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Source info and page number
            Row(
              children: [
                Expanded(
                  child: Text(
                    '— Source ID: ${quote.sourceId}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (quote.pageNumber != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Text(
                      'Page ${quote.pageNumber}',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            // Hashtags
            if (quote.hashtags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: quote.hashtags.map((tag) {
                  return Chip(
                    label: Text(
                      '#$tag',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.blue[100],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                    ),
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
                fontSize: 11,
              ),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: onTap,
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
