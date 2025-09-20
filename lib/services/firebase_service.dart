import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group.dart';
import '../models/quote.dart';
import '../models/source.dart' as models;

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User management
  static String? get currentUserId => _auth.currentUser?.uid;

  // Groups collection
  static CollectionReference get _groupsCollection =>
      _firestore.collection('users').doc(currentUserId).collection('groups');

  // Sources collection
  static CollectionReference get _sourcesCollection =>
      _firestore.collection('users').doc(currentUserId).collection('sources');

  // Quotes collection
  static CollectionReference get _quotesCollection =>
      _firestore.collection('users').doc(currentUserId).collection('quotes');

  // Group operations
  static Future<String> addGroup(Group group) async {
    final docRef = await _groupsCollection.add(group.toFirestore());
    return docRef.id;
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
    final snapshot = await _groupsCollection
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Group.fromFirestore(doc))
        .toList();
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
