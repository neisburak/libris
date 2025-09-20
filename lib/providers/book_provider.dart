import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../services/firebase_service.dart';

// Books stream provider
final booksProvider = StreamProvider<List<Book>>((ref) {
  return FirebaseService.getBooks();
});

// Books by status providers
final readBooksProvider = StreamProvider<List<Book>>((ref) {
  return FirebaseService.getBooksByStatus(ReadingStatus.read);
});

final readingBooksProvider = StreamProvider<List<Book>>((ref) {
  return FirebaseService.getBooksByStatus(ReadingStatus.reading);
});

final willReadBooksProvider = StreamProvider<List<Book>>((ref) {
  return FirebaseService.getBooksByStatus(ReadingStatus.willRead);
});

// Book operations provider
final bookOperationsProvider = Provider<BookOperations>((ref) {
  return BookOperations();
});

class BookOperations {
  Future<String> addBook(Book book) async {
    return await FirebaseService.addBook(book);
  }

  Future<void> updateBook(Book book) async {
    await FirebaseService.updateBook(book);
  }

  Future<void> deleteBook(String bookId) async {
    await FirebaseService.deleteBook(bookId);
  }

  Future<Book?> getBookById(String bookId) async {
    return await FirebaseService.getBookById(bookId);
  }
}

// Search provider
final bookSearchProvider = StateProvider<String>((ref) => '');

final searchedBooksProvider = StreamProvider<List<Book>>((ref) {
  final searchQuery = ref.watch(bookSearchProvider);
  if (searchQuery.isEmpty) {
    return FirebaseService.getBooks();
  }
  return FirebaseService.searchBooks(searchQuery);
});
