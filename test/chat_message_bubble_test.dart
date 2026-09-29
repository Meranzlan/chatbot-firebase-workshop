import 'package:chatbot_firebase/models/chat_message.dart';
import 'package:chatbot_firebase/views/widgets/chat_message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a numbered chip for each web page the answer used', (
    tester,
  ) async {
    final message = ChatMessage(
      text: 'The iPhone 17 came out in September. [1][2]',
      isUser: false,
      timestamp: DateTime(2026, 9, 29, 11, 42),
      citations: const [
        ChatCitation(title: 'apple.com', url: 'https://apple.com'),
        ChatCitation(title: 'theverge.com', url: 'https://theverge.com'),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChatMessageBubble(message: message)),
      ),
    );

    expect(find.text('apple.com'), findsOneWidget);
    expect(find.text('theverge.com'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });
}
