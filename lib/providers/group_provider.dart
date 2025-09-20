import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group.dart';
import '../services/firebase_service.dart';

class GroupNotifier extends StateNotifier<AsyncValue<List<Group>>> {
  GroupNotifier() : super(const AsyncValue.loading()) {
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    try {
      state = const AsyncValue.loading();
      final groups = await FirebaseService.getGroups();
      state = AsyncValue.data(groups);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addGroup(Group group) async {
    try {
      await FirebaseService.addGroup(group);
      await _loadGroups();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateGroup(Group group) async {
    try {
      await FirebaseService.updateGroup(group);
      await _loadGroups();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteGroup(String groupId) async {
    try {
      await FirebaseService.deleteGroup(groupId);
      await _loadGroups();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    await _loadGroups();
  }
}

final groupProvider = StateNotifierProvider<GroupNotifier, AsyncValue<List<Group>>>(
  (ref) => GroupNotifier(),
);

final groupSearchProvider = StateProvider<String>((ref) => '');

final filteredGroupsProvider = Provider<List<Group>>((ref) {
  final groupsAsync = ref.watch(groupProvider);
  final searchQuery = ref.watch(groupSearchProvider);

  return groupsAsync.when(
    data: (groups) {
      if (searchQuery.isEmpty) return groups;
      return groups.where((group) {
        return group.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               group.description.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
