import 'dart:async';

import 'package:chatbot_firebase/controllers/chat_controller.dart';
import 'package:chatbot_firebase/models/chat_message.dart';
import 'package:chatbot_firebase/models/reply_piece.dart';
import 'package:chatbot_firebase/repository/chatbot_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for Gemini, so the tests run without Firebase or a network.
/// Each test queues up the replies and decides when their pieces arrive.
class FakeRepository implements ChatbotRepository {
  final List<String> sent = [];
  int conversationsStarted = 0;

  /// Replies for the next calls to [sendMessage], used one per call.
  final List<Stream<ReplyPiece>> replies = [];

  @override
  void startConversation() => conversationsStarted++;

  @override
  Stream<ReplyPiece> sendMessage(String text) {
    sent.add(text);
    return replies.removeAt(0);
  }
}

/// A reply that arrives in these pieces of text.
Stream<ReplyPiece> say(List<String> pieces) =>
    Stream.fromIterable([for (final piece in pieces) ReplyPiece(piece)]);

/// The error Gemini sends when too many people are using it at once.
Stream<ReplyPiece> busy() => Stream.error(
  Exception(
    'FirebaseAIException: Server Error [500]: "This model is currently '
    'experiencing high demand. Spikes in demand are usually temporary."',
  ),
);

void main() {
  late FakeRepository repository;
  late ChatController chat;

  // Let pieces that were added to a stream reach the controller.
  Future<void> letPiecesArrive() => Future<void>.delayed(Duration.zero);

  setUp(() {
    repository = FakeRepository();
    chat = ChatController(repository: repository, retryDelay: Duration.zero);
  });

  tearDown(() => chat.dispose());

  test('sends the text to Gemini and shows the reply', () async {
    repository.replies.add(say(['Hi! How can I help?']));

    await chat.sendUserMessage('Hello');

    expect(repository.sent, ['Hello']);
    expect(chat.messages.map((m) => m.text), ['Hello', 'Hi! How can I help?']);
    expect(chat.messages.map((m) => m.isUser), [true, false]);
    expect(chat.isBotReplying, isFalse);
  });

  test('joins streamed pieces into one bubble', () async {
    repository.replies.add(say(['7 times ', '6 is ', '42.']));

    await chat.sendUserMessage('What is 7 times 6?');

    expect(chat.messages.map((m) => m.text), [
      'What is 7 times 6?',
      '7 times 6 is 42.',
    ]);
  });

  test('shows "thinking" only until the first words arrive', () async {
    final pieces = StreamController<ReplyPiece>();
    repository.replies.add(pieces.stream);

    final sending = chat.sendUserMessage('Hello');
    expect(chat.isThinking, isTrue);

    pieces.add(const ReplyPiece('Hi'));
    await letPiecesArrive();
    expect(chat.isThinking, isFalse);
    expect(chat.messages.last.text, 'Hi');
    // Gemini is still writing, so the input stays locked.
    expect(chat.isBotReplying, isTrue);

    await pieces.close();
    await sending;
    expect(chat.isBotReplying, isFalse);
  });

  test('keeps "thinking" until the first real words arrive', () async {
    final pieces = StreamController<ReplyPiece>();
    repository.replies.add(pieces.stream);

    final sending = chat.sendUserMessage('Hello');
    pieces.add(const ReplyPiece(''));
    await letPiecesArrive();

    expect(chat.isThinking, isTrue);
    expect(chat.messages, hasLength(1)); // No empty bot bubble.

    await pieces.close();
    await sending;
  });

  test('ignores a new message while the bot is still replying', () async {
    final pieces = StreamController<ReplyPiece>();
    repository.replies.add(pieces.stream);

    final sending = chat.sendUserMessage('First');
    await chat.sendUserMessage('Second');

    expect(repository.sent, ['First']);
    await pieces.close();
    await sending;
  });

  test('lists the web pages Gemini used under its answer', () async {
    const apple = ChatCitation(title: 'apple.com', url: 'https://apple.com');
    repository.replies.add(
      Stream.fromIterable([
        const ReplyPiece('The iPhone 17 came out in September.'),
        const ReplyPiece(
          '',
          citations: [apple],
          citedQuotes: [
            (quote: 'The iPhone 17 came out in September.', numbers: [1]),
          ],
          searchSuggestions: '<div>chips</div>',
        ),
      ]),
    );

    await chat.sendUserMessage("What's the latest iPhone?");

    final answer = chat.messages.last;
    expect(answer.text, 'The iPhone 17 came out in September. [1]');
    expect(answer.citations, [apple]);
    expect(answer.searchSuggestions, '<div>chips</div>');
  });

  test('turns common Firebase errors into a next step', () async {
    // Error text (as Firebase reports it) → what the banner should point to.
    const cases = {
      '[firebase_app_check/unknown] Error returned from API. code: 403 '
              'body: App attestation failed.':
          'debug token',
      'This model models/gemini-2.5-flash is no longer available to new '
              'users.':
          'AppConfig.model',
      // What Google Search grounding returns on the free (Spark) plan.
      'You exceeded your current quota, please check your plan and billing '
              'details.':
          'Blaze',
      'Failed host lookup: firebasevertexai.googleapis.com':
          'Failed host lookup',
    };

    for (final MapEntry(key: error, value: hint) in cases.entries) {
      repository.replies.add(Stream.error(Exception(error)));

      await chat.sendUserMessage('Hello');

      expect(chat.errorMessage, contains(hint), reason: error);
      expect(chat.isBotReplying, isFalse, reason: error);
    }
  });

  test('asks again when Gemini is busy, then shows the reply', () async {
    repository.replies.addAll([busy(), busy(), say(['Hi!'])]);

    await chat.sendUserMessage('Hello');

    expect(repository.sent, ['Hello', 'Hello', 'Hello']);
    expect(chat.messages.map((m) => m.text), ['Hello', 'Hi!']);
    expect(chat.errorMessage, isNull);
  });

  test('gives up after two retries with a friendly message', () async {
    repository.replies.addAll([busy(), busy(), busy()]);

    await chat.sendUserMessage('Hello');

    expect(repository.sent, hasLength(3));
    expect(chat.errorMessage, contains('busy'));
    expect(chat.errorMessage, isNot(contains('Server Error')));
    expect(chat.isBotReplying, isFalse);
  });

  test('does not retry errors that asking again will not fix', () async {
    repository.replies.add(Stream.error(Exception('App attestation failed.')));

    await chat.sendUserMessage('Hello');

    expect(repository.sent, hasLength(1));
  });

  test('does not retry once the reply has started', () async {
    // Asking again now would mix two different answers in one bubble.
    final pieces = StreamController<ReplyPiece>();
    repository.replies.add(pieces.stream);

    final sending = chat.sendUserMessage('Hello');
    pieces.add(const ReplyPiece('Hel'));
    await letPiecesArrive();
    pieces.addError(Exception('This model is experiencing high demand.'));
    await sending;

    expect(repository.sent, hasLength(1));
    expect(chat.messages.last.text, 'Hel');
    expect(chat.errorMessage, contains('busy'));
  });

  test('a new conversation clears the screen and Gemini\'s memory', () async {
    repository.replies.add(say(['Hi!']));
    await chat.sendUserMessage('Hello');

    chat.startConversation();

    expect(chat.messages, isEmpty);
    expect(repository.conversationsStarted, 1);
  });
}
