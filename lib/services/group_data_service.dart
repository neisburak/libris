import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';

class GroupDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _groupsCollection = _firestore.collection('groups');

  // Simple in-memory storage as fallback
  static final List<Map<String, dynamic>> _localGroups = [];

  static String get currentUserId => 'demo_user';

  /// Add a new group
  static Future<String> addGroup(Group group) async {
    print('Adding group: ${group.name}');
    print('Group toFirestore: ${group.toFirestore()}');
    print('Current user ID: $currentUserId');
    print('Groups collection path: groups');

    try {
      // Add timeout to prevent hanging
      final docRef = await _groupsCollection
          .add(group.toFirestore())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw Exception('Firestore operation timed out after 3 seconds');
            },
          );
      print('Group added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('Error in GroupDataService.addGroup: $e');
      print('Stack trace: $stackTrace');
      print('Falling back to local storage...');

      // Fallback to local storage
      return await _addGroupLocally(group);
    }
  }

  /// Update an existing group
  static Future<void> updateGroup(Group group) async {
    await _groupsCollection.doc(group.id).update(group.toFirestore());
  }

  /// Delete a group and all its sources
  static Future<void> deleteGroup(String groupId) async {
    // First, delete all sources in this group
    final sources = await _firestore
        .collection('sources')
        .where('groupId', isEqualTo: groupId)
        .get();

    for (var doc in sources.docs) {
      await _firestore.collection('sources').doc(doc.id).delete();
    }

    // Delete the group
    await _groupsCollection.doc(groupId).delete();
  }

  /// Get all groups
  static Future<List<Group>> getGroups() async {
    try {
      final snapshot = await _groupsCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs.map((doc) => Group.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error loading groups from Firestore: $e');
      print('Falling back to local storage...');
      return await _getGroupsLocally();
    }
  }

  /// Get groups as a stream
  static Stream<List<Group>> getGroupsStream() {
    return _groupsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Group.fromFirestore(doc))
            .toList());
  }

  /// Get a specific group by ID
  static Future<Group?> getGroupById(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (doc.exists) {
      return Group.fromFirestore(doc);
    }
    return null;
  }

  /// Local storage fallback methods
  static Future<String> _addGroupLocally(Group group) async {
    try {
      _localGroups.add(group.toFirestore());
      print('Group saved locally with ID: ${group.id}');
      return group.id;
    } catch (e) {
      print('Error saving group locally: $e');
      rethrow;
    }
  }

  static Future<List<Group>> _getGroupsLocally() async {
    try {
      return _localGroups.map((groupData) {
        return Group(
          id: groupData['id'] ?? '',
          name: groupData['name'] ?? '',
          description: groupData['description'] ?? '',
          createdAt: groupData['createdAt'] != null
              ? (groupData['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      print('Error loading groups from local storage: $e');
      return [];
    }
  }
}