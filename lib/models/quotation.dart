import 'package:cloud_firestore/cloud_firestore.dart';

class Quotation {
  final String id;
  final String bookId;
  final String bookTitle;
  final String content;
  final int? pageNumber;
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  Quotation({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.content,
    this.pageNumber,
    required this.hashtags,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory Quotation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quotation(
      id: doc.id,
      bookId: data['bookId'] ?? '',
      bookTitle: data['bookTitle'] ?? '',
      content: data['content'] ?? '',
      pageNumber: data['pageNumber'],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'bookId': bookId,
      'bookTitle': bookTitle,
      'content': content,
      'pageNumber': pageNumber,
      'hashtags': hashtags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'note': note,
    };
  }

  Quotation copyWith({
    String? id,
    String? bookId,
    String? bookTitle,
    String? content,
    int? pageNumber,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return Quotation(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  String get hashtagsString {
    return hashtags.map((tag) => '#$tag').join(' ');
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return content.toLowerCase().contains(lowerQuery) ||
        bookTitle.toLowerCase().contains(lowerQuery) ||
        hashtags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }
}
