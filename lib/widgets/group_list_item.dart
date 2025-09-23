import 'package:flutter/material.dart';
import '../models/group.dart';
import 'common_list_screen.dart';

class GroupListItem extends StatelessWidget {
  final Group group;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const GroupListItem({
    super.key,
    required this.group,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SlidableListItem<Group>(
      item: group,
      onEdit: onEdit,
      onDelete: onDelete,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.folder,
            color: Colors.blueGrey.shade600,
          ),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: group.description.isNotEmpty
            ? Text(
                group.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
