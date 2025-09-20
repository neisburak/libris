import 'package:cloud_firestore/cloud_firestore.dart';
import 'source.dart' as models;

class Quotation {
  final String id;
  final String sourceId;
  final String sourceTitle;
  final String sourceAuthor;
  final models.SourceType sourceType;
  final String content;
  final int? pageNumber;
  final String? timestamp; // For videos, podcasts, etc.
  final List<String> hashtags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? note;

  Quotation({
    required this.id,
    required this.sourceId,
    required this.sourceTitle,
    required this.sourceAuthor,
    required this.sourceType,
    required this.content,
    this.pageNumber,
    this.timestamp,
    required this.hashtags,
    required this.createdAt,
    required this.updatedAt,
    this.note,
  });

  factory Quotation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Quotation(
      id: doc.id,
      sourceId: data['sourceId'] ?? '',
      sourceTitle: data['sourceTitle'] ?? '',
      sourceAuthor: data['sourceAuthor'] ?? '',
      sourceType: models.SourceType.values.firstWhere(
        (e) => e.toString() == 'SourceType.${data['sourceType']}',
        orElse: () => models.SourceType.other,
      ),
      content: data['content'] ?? '',
      pageNumber: data['pageNumber'],
      timestamp: data['timestamp'],
      hashtags: List<String>.from(data['hashtags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sourceId': sourceId,
      'sourceTitle': sourceTitle,
      'sourceAuthor': sourceAuthor,
      'sourceType': sourceType.toString().split('.').last,
      'content': content,
      'pageNumber': pageNumber,
      'timestamp': timestamp,
      'hashtags': hashtags,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'note': note,
    };
  }

  Quotation copyWith({
    String? id,
    String? sourceId,
    String? sourceTitle,
    String? sourceAuthor,
    models.SourceType? sourceType,
    String? content,
    int? pageNumber,
    String? timestamp,
    List<String>? hashtags,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? note,
  }) {
    return Quotation(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourceAuthor: sourceAuthor ?? this.sourceAuthor,
      sourceType: sourceType ?? this.sourceType,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      timestamp: timestamp ?? this.timestamp,
      hashtags: hashtags ?? this.hashtags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      note: note ?? this.note,
    );
  }

  String get hashtagsString {
    return hashtags.map((tag) => '#$tag').join(' ');
  }

  String get sourceTypeIcon {
    switch (sourceType) {
      case models.SourceType.book:
        return '📖';
      case models.SourceType.video:
        return '🎥';
      case models.SourceType.article:
        return '📄';
      case models.SourceType.podcast:
        return '🎧';
      case models.SourceType.website:
        return '🌐';
      case models.SourceType.other:
        return '📝';
    }
  }

  String get sourceTypeDisplayName {
    switch (sourceType) {
      case models.SourceType.book:
        return 'Book';
      case models.SourceType.video:
        return 'Video';
      case models.SourceType.article:
        return 'Article';
      case models.SourceType.podcast:
        return 'Podcast';
      case models.SourceType.website:
        return 'Website';
      case models.SourceType.other:
        return 'Other';
    }
  }

  String get locationInfo {
    if (pageNumber != null) {
      return 'Page $pageNumber';
    } else if (timestamp != null) {
      return 'At $timestamp';
    }
    return '';
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return content.toLowerCase().contains(lowerQuery) ||
        sourceTitle.toLowerCase().contains(lowerQuery) ||
        sourceAuthor.toLowerCase().contains(lowerQuery) ||
        hashtags.any((tag) => tag.toLowerCase().contains(lowerQuery));
  }
}
