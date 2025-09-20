import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/source.dart' as models;
import '../services/firebase_service.dart';

class SourceNotifier extends StateNotifier<AsyncValue<List<models.Source>>> {
  SourceNotifier() : super(const AsyncValue.loading()) {
    _loadSources();
  }

  Future<void> _loadSources() async {
    try {
      final sources = await FirebaseService.getSources().first;
      state = AsyncValue.data(sources);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addSource(models.Source source) async {
    try {
      await FirebaseService.addSource(source);
      await _loadSources();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateSource(models.Source source) async {
    try {
      await FirebaseService.updateSource(source);
      await _loadSources();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteSource(String sourceId) async {
    try {
      await FirebaseService.deleteSource(sourceId);
      await _loadSources();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> refresh() async {
    await _loadSources();
  }

  List<models.Source> getSourcesByType(models.SourceType type) {
    return state.when(
      data: (sources) => sources.where((source) => source.type == type).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<models.Source> getSourcesByGroup(String groupId) {
    return state.when(
      data: (sources) => sources.where((source) => source.groupId == groupId).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<models.Source> getSourcesByStatus(models.SourceStatus status) {
    return state.when(
      data: (sources) => sources.where((source) => source.status == status).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  List<models.Source> searchSources(String query) {
    return state.when(
      data: (sources) => sources.where((source) {
        final lowerQuery = query.toLowerCase();
        return source.title.toLowerCase().contains(lowerQuery) ||
            source.source.toLowerCase().contains(lowerQuery) ||
            (source.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }
}

final sourceProvider = StateNotifierProvider<SourceNotifier, AsyncValue<List<models.Source>>>(
  (ref) => SourceNotifier(),
);

// Filtered providers
final bookSourcesProvider = Provider<List<models.Source>>((ref) {
  final sourceNotifier = ref.watch(sourceProvider);
  return sourceNotifier.when(
    data: (sources) => sources.where((source) => source.type == models.SourceType.book).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final videoSourcesProvider = Provider<List<models.Source>>((ref) {
  final sourceNotifier = ref.watch(sourceProvider);
  return sourceNotifier.when(
    data: (sources) => sources.where((source) => source.type == models.SourceType.video).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final articleSourcesProvider = Provider<List<models.Source>>((ref) {
  final sourceNotifier = ref.watch(sourceProvider);
  return sourceNotifier.when(
    data: (sources) => sources.where((source) => source.type == models.SourceType.article).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final podcastSourcesProvider = Provider<List<models.Source>>((ref) {
  final sourceNotifier = ref.watch(sourceProvider);
  return sourceNotifier.when(
    data: (sources) => sources.where((source) => source.type == models.SourceType.podcast).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Search provider
final sourceSearchProvider = StateProvider<String>((ref) => '');

final filteredSourcesProvider = Provider<List<models.Source>>((ref) {
  final searchQuery = ref.watch(sourceSearchProvider);
  final sourceNotifier = ref.watch(sourceProvider);
  
  return sourceNotifier.when(
    data: (sources) {
      if (searchQuery.isEmpty) return sources;
      
      final lowerQuery = searchQuery.toLowerCase();
      return sources.where((source) {
        return source.title.toLowerCase().contains(lowerQuery) ||
            source.source.toLowerCase().contains(lowerQuery) ||
            (source.notes?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
