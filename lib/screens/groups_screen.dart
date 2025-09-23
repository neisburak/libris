import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../providers/group_provider.dart';
import '../widgets/common_list_screen.dart';
import '../widgets/group_list_item.dart';
import 'add_group_screen.dart';
import 'settings_screen.dart';
import 'sources_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(filteredGroupsProvider);

    return CommonListScreen<Group>(
      title: 'Groups',
      searchHint: 'Search groups...',
      emptyStateTitle: 'No groups yet',
      emptyStateSubtitle: 'Create your first group to organize your sources',
      searchEmptyTitle: 'No groups found',
      searchEmptySubtitle: 'Try a different search term',
      emptyStateIcon: Icons.folder_outlined,
      items: groupsAsync,
      showSearch: true,
      searchWidget: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(8),
          hintText: 'Search groups...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(groupSearchProvider.notifier).state = '';
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
          ref.read(groupSearchProvider.notifier).state = value;
        },
        onChanged: (value) {
          ref.read(groupSearchProvider.notifier).state = value;
          setState(() {}); // Rebuild to show/hide clear button
        },
      ),
      itemBuilder: (group) => GroupListItem(
        group: group,
        onTap: () => _navigateToGroupSources(group),
        onEdit: () => _editGroup(group),
        onDelete: () => _deleteGroup(group),
      ),
      onAddPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddGroupScreen()),
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

  void _editGroup(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddGroupScreen(group: group)),
    );
  }

  void _deleteGroup(Group group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "${group.name}"? This will remove the group from all sources but will not delete the sources themselves.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(groupProvider.notifier).deleteGroup(group.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToGroupSources(Group group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SourcesScreen(groupId: group.id)),
    );
  }
}
