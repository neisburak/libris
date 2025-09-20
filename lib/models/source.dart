import 'package:cloud_firestore/cloud_firestore.dart';

enum SourceType { book, video, article, podcast, website, other }

class Source {
  final String id;
  final String title;
  final String author;
  final SourceType type;
  final String? description;
  final String? coverUrl;
  final String? url;
  final int? totalPages;
  final int? currentPage;
  final String? duration; // For videos, podcasts, etc.
  final double? rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Source({
    required this.id,
    required this.title,
    required this.author,
    required this.type,
    this.description,
    this.coverUrl,
    this.url,
    this.totalPages,
    this.currentPage,
    this.duration,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Source.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Source(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      type: SourceType.values.firstWhere(
        (e) => e.toString() == 'SourceType.${data['type']}',
        orElse: () => SourceType.other,
      ),
      description: data['description'],
      coverUrl: data['coverUrl'],
      url: data['url'],
      totalPages: data['totalPages'],
      currentPage: data['currentPage'],
      duration: data['duration'],
      rating: data['rating']?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'author': author,
      'type': type.toString().split('.').last,
      'description': description,
      'coverUrl': coverUrl,
      'url': url,
      'totalPages': totalPages,
      'currentPage': currentPage,
      'duration': duration,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Source copyWith({
    String? id,
    String? title,
    String? author,
    SourceType? type,
    String? description,
    String? coverUrl,
    String? url,
    int? totalPages,
    int? currentPage,
    String? duration,
    double? rating,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Source(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      type: type ?? this.type,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      url: url ?? this.url,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      duration: duration ?? this.duration,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get typeDisplayName {
    switch (type) {
      case SourceType.book:
        return 'Book';
      case SourceType.video:
        return 'Video';
      case SourceType.article:
        return 'Article';
      case SourceType.podcast:
        return 'Podcast';
      case SourceType.website:
        return 'Website';
      case SourceType.other:
        return 'Other';
    }
  }

  String get typeIcon {
    switch (type) {
      case SourceType.book:
        return '📖';
      case SourceType.video:
        return '🎥';
      case SourceType.article:
        return '📄';
      case SourceType.podcast:
        return '🎧';
      case SourceType.website:
        return '🌐';
      case SourceType.other:
        return '📝';
    }
  }

  double get progressPercentage {
    if (totalPages == null || currentPage == null || totalPages == 0) {
      return 0.0;
    }
    return (currentPage! / totalPages! * 100).clamp(0.0, 100.0);
  }

  bool get hasProgress => totalPages != null && currentPage != null;
  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasDuration => duration != null && duration!.isNotEmpty;
}
