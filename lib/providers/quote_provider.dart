import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../services/quote_data_service.dart';

/// Provider for all quotes
final quoteProvider = StreamProvider<List<Quote>>((ref) {
  return QuoteDataService.getQuotesStream();
});

/// Provider for quotes by source ID
final quotesBySourceProvider = StreamProvider.family<List<Quote>, String>((ref, sourceId) {
  return QuoteDataService.getQuotesBySourceStream(sourceId);
});

/// Provider for quotes by hashtag
final quotesByHashtagProvider = StreamProvider.family<List<Quote>, String>((ref, hashtag) {
  return QuoteDataService.getQuotesByHashtagStream(hashtag);
});

/// Provider for all hashtags
final hashtagsProvider = FutureProvider<List<String>>((ref) {
  return QuoteDataService.getAllHashtags();
});
