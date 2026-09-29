import 'chat_citation.dart';
import 'reply_piece.dart';

export 'chat_citation.dart';

/// One bubble in the chat.
class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations = const [],
    this.searchSuggestions,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;

  /// The web pages the answer came from (Google Search on only).
  final List<ChatCitation> citations;

  /// Google's ready-made HTML for the search chips (Google Search on only).
  final String? searchSuggestions;

  /// A message the user typed.
  factory ChatMessage.fromUser(String text) =>
      ChatMessage(text: text, isUser: true, timestamp: DateTime.now());

  /// A reply from the bot.
  factory ChatMessage.fromBot(String text) =>
      ChatMessage(text: text, isUser: false, timestamp: DateTime.now());

  /// This message with [more] text on the end. Used while streaming.
  ChatMessage append(String more) => _copyWith(text: text + more);

  /// This message with the web pages its answer came from: numbers like [1]
  /// after each quote that came from a page, and the pages themselves.
  ChatMessage withSources(ReplyPiece sources) {
    var marked = text;
    var searchFrom = 0;
    for (final (:quote, :numbers) in sources.citedQuotes) {
      final at = quote.isEmpty ? -1 : marked.indexOf(quote, searchFrom);
      if (at < 0 || numbers.isEmpty) continue;

      final end = at + quote.length;
      final label = ' ${numbers.map((n) => '[$n]').join()}';
      marked = marked.substring(0, end) + label + marked.substring(end);
      searchFrom = end + label.length;
    }

    return _copyWith(
      text: marked,
      citations: sources.citations,
      searchSuggestions: sources.searchSuggestions,
    );
  }

  ChatMessage _copyWith({
    required String text,
    List<ChatCitation>? citations,
    String? searchSuggestions,
  }) => ChatMessage(
    text: text,
    isUser: isUser,
    timestamp: timestamp,
    citations: citations ?? this.citations,
    searchSuggestions: searchSuggestions ?? this.searchSuggestions,
  );
}
