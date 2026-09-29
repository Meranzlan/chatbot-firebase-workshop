import 'package:chatbot_firebase/models/chat_message.dart';
import 'package:chatbot_firebase/models/reply_piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const apple = ChatCitation(title: 'apple.com', url: 'https://apple.com');
  const verge = ChatCitation(title: 'theverge.com', url: 'https://theverge.com');

  test('withSources numbers each quote with the pages it came from', () {
    final message = ChatMessage.fromBot(
      'The iPhone 17 came out in September. It has a new camera.',
    );

    final withSources = message.withSources(
      const ReplyPiece(
        '',
        citations: [apple, verge],
        citedQuotes: [
          (quote: 'The iPhone 17 came out in September.', numbers: [1, 2]),
          (quote: 'It has a new camera.', numbers: [2]),
        ],
        searchSuggestions: '<div>chips</div>',
      ),
    );

    expect(
      withSources.text,
      'The iPhone 17 came out in September. [1][2] It has a new camera. [2]',
    );
    expect(withSources.citations, [apple, verge]);
    expect(withSources.searchSuggestions, '<div>chips</div>');
  });

  test('withSources leaves the text alone when a quote is not found', () {
    final message = ChatMessage.fromBot('Hello there.');

    final withSources = message.withSources(
      const ReplyPiece(
        '',
        citations: [apple],
        citedQuotes: [(quote: 'Something else.', numbers: [1])],
      ),
    );

    expect(withSources.text, 'Hello there.');
    expect(withSources.citations, [apple]);
  });
}
