import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../services/quote_data_service.dart';

// Quotes stream provider
final quotesProvider = StreamProvider<List<Quote>>((ref) {
  return QuoteDataService.getQuotesStream();
});

// Quotes by source provider
final quotesBySourceProvider = StreamProvider.family<List<Quote>, String>((ref, sourceId) {
  return QuoteDataService.getQuotesBySourceStream(sourceId);
});

// Search provider
final quoteSearchProvider = StateProvider<String>((ref) => '');

// Filtered quotes provider
final filteredQuotesProvider = Provider<List<Quote>>((ref) {
  final searchQuery = ref.watch(quoteSearchProvider);
  final quotesAsync = ref.watch(quotesProvider);
  
  return quotesAsync.when(
    data: (quotes) {
      if (searchQuery.isEmpty) return quotes;
      
      final lowerQuery = searchQuery.toLowerCase();
      return quotes.where((quote) {
        return quote.matchesSearch(lowerQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Hashtag search provider
final hashtagSearchProvider = StateProvider<String>((ref) => '');

final quotesByHashtagProvider = StreamProvider<List<Quote>>((ref) {
  final hashtag = ref.watch(hashtagSearchProvider);
  if (hashtag.isEmpty) {
    return QuoteDataService.getQuotesStream();
  }
  return QuoteDataService.getQuotesByHashtagStream(hashtag);
});

// All hashtags provider
final allHashtagsProvider = FutureProvider<List<String>>((ref) {
  return QuoteDataService.getAllHashtags();
});

// Quote operations provider
final quoteOperationsProvider = Provider<QuoteOperations>((ref) {
  return QuoteOperations();
});

class QuoteOperations {
  Future<String> addQuote(Quote quote) async {
    return await QuoteDataService.addQuote(quote);
  }

  Future<void> updateQuote(Quote quote) async {
    await QuoteDataService.updateQuote(quote);
  }

  Future<void> deleteQuote(String quoteId) async {
    await QuoteDataService.deleteQuote(quoteId);
  }
}