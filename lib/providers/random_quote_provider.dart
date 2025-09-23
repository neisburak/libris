import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quote.dart';
import '../providers/quotation_provider.dart';

/// Provider for getting a random quote
final randomQuoteProvider = Provider<Quote?>((ref) {
  final quotes = ref.watch(filteredQuotesProvider);
  
  if (quotes.isEmpty) return null;
  
  // Get a random quote from the list
  final random = DateTime.now().millisecondsSinceEpoch % quotes.length;
  return quotes[random];
});

/// Provider for getting a random quote with refresh capability
final randomQuoteWithRefreshProvider = StateNotifierProvider<RandomQuoteNotifier, Quote?>((ref) {
  return RandomQuoteNotifier(ref);
});

class RandomQuoteNotifier extends StateNotifier<Quote?> {
  final Ref _ref;
  
  RandomQuoteNotifier(this._ref) : super(null) {
    _loadRandomQuote();
  }
  
  void _loadRandomQuote() {
    final quotes = _ref.read(filteredQuotesProvider);
    
    if (quotes.isEmpty) {
      state = null;
      return;
    }
    
    // Get a random quote from the list
    final random = DateTime.now().millisecondsSinceEpoch % quotes.length;
    state = quotes[random];
  }
  
  void refreshRandomQuote() {
    _loadRandomQuote();
  }
}
