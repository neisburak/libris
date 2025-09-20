import 'package:cloud_firestore/cloud_firestore.dart';

enum ReadingStatus { read, reading, willRead }

class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverUrl;
  final ReadingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? totalPages;
  final int? currentPage;
  final double? rating;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.totalPages,
    this.currentPage,
    this.rating,
  });

  factory Book.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Book(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      description: data['description'],
      coverUrl: data['coverUrl'],
      status: ReadingStatus.values.firstWhere(
        (e) => e.toString() == 'ReadingStatus.${data['status']}',
        orElse: () => ReadingStatus.willRead,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      totalPages: data['totalPages'],
      currentPage: data['currentPage'],
      rating: data['rating']?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'totalPages': totalPages,
      'currentPage': currentPage,
      'rating': rating,
    };
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    ReadingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? totalPages,
    int? currentPage,
    double? rating,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      rating: rating ?? this.rating,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ReadingStatus.read:
        return 'Read';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.willRead:
        return 'Will Read';
    }
  }

  double get progressPercentage {
    if (totalPages == null || currentPage == null || totalPages == 0) {
      return 0.0;
    }
    return (currentPage! / totalPages! * 100).clamp(0.0, 100.0);
  }
}
