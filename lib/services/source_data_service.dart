import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:libris_app/utils/logger.dart';
import '../models/source.dart' as models;

class SourceDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _sourcesCollection = _firestore.collection(
    'sources',
  );

  static String get currentUserId => 'demo_user';

  /// Add a new source
  static Future<String> addSource(models.Source source) async {
    try {
      final docRef = await _sourcesCollection
          .add(source.toFirestore())
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              throw Exception('Firestore operation timed out after 3 seconds');
            },
          );
      return docRef.id;
    } catch (e) {
      Logger.log('Error adding source: $e');
      rethrow;
    }
  }

  /// Update an existing source
  static Future<void> updateSource(models.Source source) async {
    await _sourcesCollection.doc(source.id).update(source.toFirestore());
  }

  /// Delete a source and all its quotes
  static Future<void> deleteSource(String sourceId) async {
    // First, delete all quotes from this source
    final quotes = await _firestore
        .collection('quotes')
        .where('sourceId', isEqualTo: sourceId)
        .get();

    for (var doc in quotes.docs) {
      await doc.reference.delete();
    }

    // Delete the source
    await _sourcesCollection.doc(sourceId).delete();
  }

  /// Get all sources
  static Future<List<models.Source>> getSources() async {
    try {
      final snapshot = await _sourcesCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => models.Source.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.log('Error loading sources: $e');
      return [];
    }
  }

  /// Get sources as a stream
  static Stream<List<models.Source>> getSourcesStream() {
    return _sourcesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => models.Source.fromFirestore(doc))
              .toList(),
        );
  }

  /// Get sources by type
  static Future<List<models.Source>> getSourcesByType(
    models.SourceType type,
  ) async {
    try {
      final snapshot = await _sourcesCollection
          .where('type', isEqualTo: type.name)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => models.Source.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.log('Error loading sources by type: $e');
      return [];
    }
  }

  /// Get sources by group
  static Future<List<models.Source>> getSourcesByGroup(String groupId) async {
    try {
      final snapshot = await _sourcesCollection
          .where('groupIds', arrayContains: groupId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => models.Source.fromFirestore(doc))
          .toList();
    } catch (e) {
      Logger.log('Error loading sources by group: $e');
      return [];
    }
  }

  /// Get sources by multiple groups
  static Future<List<models.Source>> getSourcesByGroups(List<String> groupIds) async {
    try {
      if (groupIds.isEmpty) return [];
      
      // Firestore doesn't support OR queries directly, so we need to get all sources
      // and filter them in memory for multiple groups
      final snapshot = await _sourcesCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      
      return snapshot.docs
          .map((doc) => models.Source.fromFirestore(doc))
          .where((source) => source.groupIds.any((groupId) => groupIds.contains(groupId)))
          .toList();
    } catch (e) {
      Logger.log('Error loading sources by groups: $e');
      return [];
    }
  }

  /// Get a specific source by ID
  static Future<models.Source?> getSourceById(String sourceId) async {
    final doc = await _sourcesCollection.doc(sourceId).get();
    if (doc.exists) {
      return models.Source.fromFirestore(doc);
    }
    return null;
  }

  /// Search sources
  static Future<List<models.Source>> searchSources(String query) async {
    try {
      final snapshot = await _sourcesCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => models.Source.fromFirestore(doc))
          .where(
            (source) =>
                source.title.toLowerCase().contains(query.toLowerCase()) ||
                source.source.toLowerCase().contains(query.toLowerCase()) ||
                (source.notes?.toLowerCase().contains(query.toLowerCase()) ??
                    false),
          )
          .toList();
    } catch (e) {
      Logger.log('Error searching sources: $e');
      return [];
    }
  }

  /// Remove a group from all sources that contain it
  static Future<void> removeGroupFromAllSources(String groupId) async {
    try {
      final sources = await getSourcesByGroup(groupId);
      final batch = _firestore.batch();
      
      for (final source in sources) {
        final updatedSource = source.removeFromGroup(groupId);
        batch.update(
          _sourcesCollection.doc(source.id),
          updatedSource.toFirestore(),
        );
      }
      
      await batch.commit();
      Logger.log('Removed group $groupId from ${sources.length} sources');
    } catch (e) {
      Logger.log('Error removing group from sources: $e');
      rethrow;
    }
  }
}
