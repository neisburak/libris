import 'package:cloud_firestore/cloud_firestore.dart';

class Quote {
  final String id;
  final String sourceId;
  final String quote;
  final int? pageNumber;
  final List<String> hashtags;
  final DateTime createdAt;

  Quote({
    required this.id,
    required this.sourceId,
    required this.quote,
    this.pageNumber,
    required this.hashtags,
    required this.createdAt,
  });

  factory Quote.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quote(
      id: doc.id,
      sourceId: data['sourceId'] ?? '',
      quote: data['quote'] ?? '',
      pageNumber: data['pageNumber'],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sourceId': sourceId,
      'quote': quote,
      'pageNumber': pageNumber,
      'hashtags': hashtags,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Quote copyWith({
    String? id,
    String? sourceId,
    String? quote,
    int? pageNumber,
    List<String>? hashtags,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      quote: quote ?? this.quote,
      pageNumber: pageNumber ?? this.pageNumber,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get hashtagsString {
    return hashtags.map((tag) => '#$tag').join(' ');
  }

  String get locationInfo {
    if (pageNumber != null) {
      return 'Page $pageNumber';
    }
    return '';
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return quote.toLowerCase().contains(lowerQuery) ||
        hashtags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Quote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Quote(id: $id, sourceId: $sourceId, quote: $quote, pageNumber: $pageNumber, hashtags: $hashtags, createdAt: $createdAt)';
  }
}
