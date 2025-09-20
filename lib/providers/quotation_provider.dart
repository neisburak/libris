import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quotation.dart';
import '../models/source.dart' as models;
import '../services/firebase_service.dart';

// Quotations stream provider
final quotationsProvider = StreamProvider<List<Quotation>>((ref) {
  return FirebaseService.getQuotations();
});

// Quotations by source provider
final quotationsBySourceProvider = StreamProvider.family<List<Quotation>, String>((ref, sourceId) {
  return FirebaseService.getQuotationsBySource(sourceId);
});

// Quotations by source type provider
final quotationsBySourceTypeProvider = StreamProvider.family<List<Quotation>, models.SourceType>((ref, sourceType) {
  return FirebaseService.getQuotationsBySourceType(sourceType);
});

// Search provider
final quotationSearchProvider = StateProvider<String>((ref) => '');

final searchedQuotationsProvider = StreamProvider<List<Quotation>>((ref) {
  final searchQuery = ref.watch(quotationSearchProvider);
  if (searchQuery.isEmpty) {
    return FirebaseService.getQuotations();
  }
  return FirebaseService.searchQuotations(searchQuery);
});

// Hashtag search provider
final hashtagSearchProvider = StateProvider<String>((ref) => '');

final quotationsByHashtagProvider = StreamProvider<List<Quotation>>((ref) {
  final hashtag = ref.watch(hashtagSearchProvider);
  if (hashtag.isEmpty) {
    return FirebaseService.getQuotations();
  }
  return FirebaseService.getQuotationsByHashtag(hashtag);
});

// All hashtags provider
final allHashtagsProvider = FutureProvider<List<String>>((ref) {
  return FirebaseService.getAllHashtags();
});

// Quotation operations provider
final quotationOperationsProvider = Provider<QuotationOperations>((ref) {
  return QuotationOperations();
});

class QuotationOperations {
  Future<String> addQuotation(Quotation quotation) async {
    return await FirebaseService.addQuotation(quotation);
  }

  Future<void> updateQuotation(Quotation quotation) async {
    await FirebaseService.updateQuotation(quotation);
  }

  Future<void> deleteQuotation(String quotationId) async {
    await FirebaseService.deleteQuotation(quotationId);
  }
}
