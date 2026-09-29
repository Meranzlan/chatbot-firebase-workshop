import 'chat_citation.dart';

/// One piece of Gemini's reply, as the repository hands it to the controller.
///
/// Most pieces just add more words. With Google Search on, a piece also says
/// which web pages the answer came from.
class ReplyPiece {
  const ReplyPiece(
    this.text, {
    this.citations = const [],
    this.citedQuotes = const [],
    this.searchSuggestions,
  });

  /// More words of the answer.
  final String text;

  /// The web pages Gemini used, numbered 1, 2, 3… in this order.
  final List<ChatCitation> citations;

  /// Which parts of the answer came from which pages, for example
  /// `(quote: 'It came out in September.', numbers: [1, 3])`.
  final List<({String quote, List<int> numbers})> citedQuotes;

  /// Google's ready-made HTML for the "search suggestions" chips.
  final String? searchSuggestions;

  /// True when Gemini searched Google for this answer.
  bool get hasSources => citations.isNotEmpty || searchSuggestions != null;
}
