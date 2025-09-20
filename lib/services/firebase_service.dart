import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group.dart';
import '../models/quote.dart';
import '../models/source.dart' as models;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User management - using demo user for now
  static String get currentUserId => 'demo_user';

  // Simple in-memory storage as fallback
  static final List<Map<String, dynamic>> _localGroups = [];
  static final List<Map<String, dynamic>> _localSources = [];
  static final List<Map<String, dynamic>> _localQuotes = [];

  // Test Firestore connectivity
  static Future<void> testFirestoreConnection() async {
    try {
      print('Testing Firestore connection...');
      await _firestore.collection('test').doc('connection').set({
        'timestamp': Timestamp.now(),
        'message': 'Connection test successful',
      });
      print('Firestore connection test successful');
      
      // Clean up test document
      await _firestore.collection('test').doc('connection').delete();
      print('Test document cleaned up');
    } catch (e, stackTrace) {
      print('Firestore connection test failed: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Groups collection - using a simpler path for testing
  static CollectionReference get _groupsCollection =>
      _firestore.collection('groups');

  // Sources collection - using a simpler path for testing
  static CollectionReference get _sourcesCollection =>
      _firestore.collection('sources');

  // Quotes collection - using a simpler path for testing
  static CollectionReference get _quotesCollection =>
      _firestore.collection('quotes');

  // Group operations
  static Future<String> addGroup(Group group) async {
    print('FirebaseService.addGroup called with group: $group');
    print('Group toFirestore: ${group.toFirestore()}');
    print('Current user ID: $currentUserId');
    print('Groups collection path: groups');
    
    try {
      // Add timeout to prevent hanging
      final docRef = await _groupsCollection.add(group.toFirestore()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Firestore operation timed out after 3 seconds');
        },
      );
      print('Group added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e, stackTrace) {
      print('Error in FirebaseService.addGroup: $e');
      print('Stack trace: $stackTrace');
      print('Falling back to local storage...');
      
      // Fallback to local storage
      return await _addGroupLocally(group);
    }
  }

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

  static Future<void> updateGroup(Group group) async {
    await _groupsCollection.doc(group.id).update(group.toFirestore());
  }

  static Future<void> deleteGroup(String groupId) async {
    // Delete all sources in this group first
    final sources = await _sourcesCollection
        .where('groupId', isEqualTo: groupId)
        .get();
    
    for (var doc in sources.docs) {
      await deleteSource(doc.id);
    }
    
    // Delete the group
    await _groupsCollection.doc(groupId).delete();
  }

  static Future<List<Group>> getGroups() async {
    try {
      final snapshot = await _groupsCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => Group.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading groups from Firestore: $e');
      print('Falling back to local storage...');
      return await _getGroupsLocally();
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

  static Future<Group?> getGroupById(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (doc.exists) {
      return Group.fromFirestore(doc);
    }
    return null;
  }

  // Quote operations
  static Future<String> addQuote(Quote quote) async {
    final docRef = await _quotesCollection.add(quote.toFirestore());
    return docRef.id;
  }

  static Future<void> updateQuote(Quote quote) async {
    await _quotesCollection.doc(quote.id).update(quote.toFirestore());
  }

  static Future<void> deleteQuote(String quoteId) async {
    await _quotesCollection.doc(quoteId).delete();
  }

  static Stream<List<Quote>> getQuotes() {
    return _quotesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quote.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Quote>> getQuotesBySource(String sourceId) {
    return _quotesCollection
        .where('sourceId', isEqualTo: sourceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quote.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Quote>> searchQuotes(String query) {
    return _quotesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quote.fromFirestore(doc))
            .where((quote) => quote.matchesSearch(query))
            .toList());
  }

  static Stream<List<Quote>> getQuotesByHashtag(String hashtag) {
    return _quotesCollection
        .where('hashtags', arrayContains: hashtag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quote.fromFirestore(doc))
            .toList());
  }

  // Get all unique hashtags
  static Future<List<String>> getAllHashtags() async {
    final quotes = await _quotesCollection.get();
    final allHashtags = <String>{};
    
    for (var doc in quotes.docs) {
      final quote = Quote.fromFirestore(doc);
      allHashtags.addAll(quote.hashtags);
    }
    
    return allHashtags.toList()..sort();
  }

  // Source operations
  static Future<String> addSource(models.Source source) async {
    final docRef = await _sourcesCollection.add(source.toFirestore());
    return docRef.id;
  }

  static Future<void> updateSource(models.Source source) async {
    await _sourcesCollection.doc(source.id).update(source.toFirestore());
  }

  static Future<void> deleteSource(String sourceId) async {
    // Delete all quotes for this source first
    final quotes = await _quotesCollection
        .where('sourceId', isEqualTo: sourceId)
        .get();
    
    for (var doc in quotes.docs) {
      await doc.reference.delete();
    }
    
    // Delete the source
    await _sourcesCollection.doc(sourceId).delete();
  }

  static Stream<List<models.Source>> getSources() {
    return _sourcesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Source.fromFirestore(doc))
            .toList());
  }

  static Stream<List<models.Source>> getSourcesByType(models.SourceType type) {
    return _sourcesCollection
        .where('type', isEqualTo: type.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => models.Source.fromFirestore(doc))
            .toList());
  }

  static Future<models.Source?> getSourceById(String sourceId) async {
    final doc = await _sourcesCollection.doc(sourceId).get();
    if (doc.exists) {
      return models.Source.fromFirestore(doc);
    }
    return null;
  }

  static Future<List<models.Source>> searchSources(String query) async {
    final snapshot = await _sourcesCollection
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => models.Source.fromFirestore(doc))
        .where((source) => 
            source.title.toLowerCase().contains(query.toLowerCase()) ||
            source.source.toLowerCase().contains(query.toLowerCase()) ||
            (source.notes?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }
}
