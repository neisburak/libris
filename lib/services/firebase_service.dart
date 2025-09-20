import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import '../models/quotation.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // User management
  static String? get currentUserId => _auth.currentUser?.uid;

  // Books collection
  static CollectionReference get _booksCollection =>
      _firestore.collection('users').doc(currentUserId).collection('books');

  // Quotations collection
  static CollectionReference get _quotationsCollection =>
      _firestore.collection('users').doc(currentUserId).collection('quotations');

  // Book operations
  static Future<String> addBook(Book book) async {
    final docRef = await _booksCollection.add(book.toFirestore());
    return docRef.id;
  }

  static Future<void> updateBook(Book book) async {
    await _booksCollection.doc(book.id).update(book.toFirestore());
  }

  static Future<void> deleteBook(String bookId) async {
    // Delete all quotations for this book first
    final quotations = await _quotationsCollection
        .where('bookId', isEqualTo: bookId)
        .get();
    
    for (var doc in quotations.docs) {
      await doc.reference.delete();
    }
    
    // Delete the book
    await _booksCollection.doc(bookId).delete();
  }

  static Stream<List<Book>> getBooks() {
    return _booksCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Book>> getBooksByStatus(ReadingStatus status) {
    return _booksCollection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .toList());
  }

  static Future<Book?> getBookById(String bookId) async {
    final doc = await _booksCollection.doc(bookId).get();
    if (doc.exists) {
      return Book.fromFirestore(doc);
    }
    return null;
  }

  // Quotation operations
  static Future<String> addQuotation(Quotation quotation) async {
    final docRef = await _quotationsCollection.add(quotation.toFirestore());
    return docRef.id;
  }

  static Future<void> updateQuotation(Quotation quotation) async {
    await _quotationsCollection.doc(quotation.id).update(quotation.toFirestore());
  }

  static Future<void> deleteQuotation(String quotationId) async {
    await _quotationsCollection.doc(quotationId).delete();
  }

  static Stream<List<Quotation>> getQuotations() {
    return _quotationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quotation.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Quotation>> getQuotationsByBook(String bookId) {
    return _quotationsCollection
        .where('bookId', isEqualTo: bookId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quotation.fromFirestore(doc))
            .toList());
  }

  static Stream<List<Quotation>> searchQuotations(String query) {
    return _quotationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quotation.fromFirestore(doc))
            .where((quotation) => quotation.matchesSearch(query))
            .toList());
  }

  static Stream<List<Quotation>> getQuotationsByHashtag(String hashtag) {
    return _quotationsCollection
        .where('hashtags', arrayContains: hashtag)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Quotation.fromFirestore(doc))
            .toList());
  }

  // Search operations
  static Stream<List<Book>> searchBooks(String query) {
    return _booksCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Book.fromFirestore(doc))
            .where((book) => 
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.author.toLowerCase().contains(query.toLowerCase()))
            .toList());
  }

  // Get all unique hashtags
  static Future<List<String>> getAllHashtags() async {
    final quotations = await _quotationsCollection.get();
    final allHashtags = <String>{};
    
    for (var doc in quotations.docs) {
      final quotation = Quotation.fromFirestore(doc);
      allHashtags.addAll(quotation.hashtags);
    }
    
    return allHashtags.toList()..sort();
  }
}
