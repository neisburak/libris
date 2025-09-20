import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote.dart';

class QuoteDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _quotesCollection = _firestore.collection('quotes');

  static String get currentUserId => 'demo_user';

  /// Add a new quote
  static Future<String> addQuote(Quote quote) async {
    try {
      final docRef = await _quotesCollection.add(quote.toFirestore()).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Firestore operation timed out after 3 seconds');
        },
      );
      return docRef.id;
    } catch (e) {
      print('Error adding quote: $e');
      rethrow;
    }
  }

  /// Update an existing quote
  static Future<void> updateQuote(Quote quote) async {
    await _quotesCollection.doc(quote.id).update(quote.toFirestore());
  }

  /// Delete a quote
  static Future<void> deleteQuote(String quoteId) async {
    await _quotesCollection.doc(quoteId).delete();
  }

  /// Get all quotes
  static Future<List<Quote>> getQuotes() async {
    try {
      final snapshot = await _quotesCollection
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => Quote.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading quotes: $e');
      return [];
    }
  }

  /// Get quotes as a stream
  static Stream<List<Quote>> getQuotesStream() {
    return _quotesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList(),
        );
  }

  /// Get quotes by source
  static Future<List<Quote>> getQuotesBySource(String sourceId) async {
    try {
      final snapshot = await _quotesCollection
          .where('sourceId', isEqualTo: sourceId)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => Quote.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading quotes by source: $e');
      return [];
    }
  }

  /// Get quotes by source as a stream
  static Stream<List<Quote>> getQuotesBySourceStream(String sourceId) {
    return _quotesCollection
        .where('sourceId', isEqualTo: sourceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList(),
        );
  }

  /// Search quotes
  static Future<List<Quote>> searchQuotes(String query) async {
    try {
      final snapshot = await _quotesCollection
          .where('quote', isGreaterThanOrEqualTo: query)
          .where('quote', isLessThan: query + 'z')
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => Quote.fromFirestore(doc))
          .where((quote) => quote.matchesSearch(query))
          .toList();
    } catch (e) {
      print('Error searching quotes: $e');
      return [];
    }
  }

  /// Get quotes by hashtag
  static Future<List<Quote>> getQuotesByHashtag(String hashtag) async {
    try {
      final snapshot = await _quotesCollection
          .where('hashtags', arrayContains: hashtag)
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 3));
      return snapshot.docs
          .map((doc) => Quote.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error loading quotes by hashtag: $e');
      return [];
    }
  }

  /// Get quotes by hashtag as a stream
  static Stream<List<Quote>> getQuotesByHashtagStream(String hashtag) {
    return _quotesCollection
        .where('hashtags', arrayContains: hashtag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Quote.fromFirestore(doc)).toList(),
        );
  }

  /// Get all hashtags
  static Future<List<String>> getAllHashtags() async {
    try {
      final quotes = await _quotesCollection.get();
      final allHashtags = <String>{};

      for (var doc in quotes.docs) {
        final quote = Quote.fromFirestore(doc);
        allHashtags.addAll(quote.hashtags);
      }

      return allHashtags.toList()..sort();
    } catch (e) {
      print('Error loading hashtags: $e');
      return [];
    }
  }
}
