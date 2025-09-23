import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import 'common_list_screen.dart';

class SourceListItem extends ConsumerWidget {
  final Source source;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SourceListItem({
    super.key,
    required this.source,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SlidableListItem<Source>(
      item: source,
      onEdit: onEdit,
      onDelete: onDelete,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              source.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _getTypeColor(source.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                source.typeDisplayName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    source.source,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (source.hasGroups)
              Consumer(
                builder: (context, ref, child) {
                  final groupsAsync = ref.watch(groupProvider);
                  return groupsAsync.when(
                    data: (groups) {
                      return Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: source.groupIds.map((groupId) {
                          final group = groups.firstWhere(
                            (g) => g.id == groupId,
                            orElse: () => Group(
                              id: '',
                              name: 'Unknown',
                              description: '',
                              createdAt: DateTime.now(),
                            ),
                          );
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              group.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getTypeColor(SourceType type) {
    switch (type) {
      case SourceType.book:
        return Colors.brown;
      case SourceType.video:
        return Colors.red;
      case SourceType.article:
        return Colors.blue;
      case SourceType.podcast:
        return Colors.purple;
      case SourceType.website:
        return Colors.green;
      case SourceType.other:
        return Colors.grey;
    }
  }
}
