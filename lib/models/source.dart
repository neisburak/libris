import 'package:cloud_firestore/cloud_firestore.dart';

enum SourceType { book, video, article, podcast, website, other }

enum SourceStatus { notStarted, inProgress, completed, paused, abandoned }

class Source {
  final String id;
  final List<String> groupIds;
  final SourceType type;
  final String title;
  final String source; // Author/Creator
  final String? url;
  final String? notes;
  final SourceStatus status;
  final DateTime? startDate;
  final DateTime? finishDate;
  final DateTime createdAt;

  Source({
    required this.id,
    required this.groupIds,
    required this.type,
    required this.title,
    required this.source,
    this.url,
    this.notes,
    required this.status,
    this.startDate,
    this.finishDate,
    required this.createdAt,
  });

  factory Source.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Source(
      id: doc.id,
      groupIds: data['groupIds'] != null 
          ? List<String>.from(data['groupIds'])
          : (data['groupId'] != null ? [data['groupId']] : []), // Backward compatibility
      type: SourceType.values.firstWhere(
        (e) => e.toString() == 'SourceType.${data['type']}',
        orElse: () => SourceType.other,
      ),
      title: data['title'] ?? '',
      source: data['source'] ?? '',
      url: data['url'],
      notes: data['notes'],
      status: SourceStatus.values.firstWhere(
        (e) => e.toString() == 'SourceStatus.${data['status']}',
        orElse: () => SourceStatus.notStarted,
      ),
      startDate: data['startDate'] != null 
          ? (data['startDate'] as Timestamp).toDate() 
          : null,
      finishDate: data['finishDate'] != null 
          ? (data['finishDate'] as Timestamp).toDate() 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'groupIds': groupIds,
      'type': type.toString().split('.').last,
      'title': title,
      'source': source,
      'url': url,
      'notes': notes,
      'status': status.toString().split('.').last,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'finishDate': finishDate != null ? Timestamp.fromDate(finishDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Source copyWith({
    String? id,
    List<String>? groupIds,
    SourceType? type,
    String? title,
    String? source,
    String? url,
    String? notes,
    SourceStatus? status,
    DateTime? startDate,
    DateTime? finishDate,
    DateTime? createdAt,
  }) {
    return Source(
      id: id ?? this.id,
      groupIds: groupIds ?? this.groupIds,
      type: type ?? this.type,
      title: title ?? this.title,
      source: source ?? this.source,
      url: url ?? this.url,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      finishDate: finishDate ?? this.finishDate,
      createdAt: createdAt ?? this.createdAt,
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

  String get statusDisplayName {
    switch (status) {
      case SourceStatus.notStarted:
        return 'Not Started';
      case SourceStatus.inProgress:
        return 'In Progress';
      case SourceStatus.completed:
        return 'Completed';
      case SourceStatus.paused:
        return 'Paused';
      case SourceStatus.abandoned:
        return 'Abandoned';
    }
  }

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasNotes => notes != null && notes!.isNotEmpty;
  bool get isCompleted => status == SourceStatus.completed;
  bool get isInProgress => status == SourceStatus.inProgress;
  bool get hasGroups => groupIds.isNotEmpty;
  bool isInGroup(String groupId) => groupIds.contains(groupId);
  
  // Helper methods for group management
  Source addToGroup(String groupId) {
    if (groupIds.contains(groupId)) return this;
    return copyWith(groupIds: [...groupIds, groupId]);
  }
  
  Source removeFromGroup(String groupId) {
    if (!groupIds.contains(groupId)) return this;
    return copyWith(groupIds: groupIds.where((id) => id != groupId).toList());
  }
  
  Source setGroups(List<String> newGroupIds) {
    return copyWith(groupIds: newGroupIds);
  }
}
