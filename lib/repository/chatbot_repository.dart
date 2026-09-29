import 'package:firebase_ai/firebase_ai.dart';

import '../config/app_config.dart';
import '../config/demo_config.dart';
import '../models/chat_citation.dart';
import '../models/reply_piece.dart';

/// Talks to Gemini through Firebase AI Logic.
///
///   Step 1  startConversation()  Starts a fresh chat (no network call)
///   Step 2  sendMessage()        Sends what the user typed, returns the reply
///
/// Firebase handles the rest: `firebase_options.dart` says which project to
/// use, and App Check proves each request really comes from this app.
class ChatbotRepository {
  /// Everything said so far, so Gemini can refer back to earlier messages.
  final List<Content> _history = [];

  /// Step 1: forget the old conversation and start a new one.
  void startConversation() => _history.clear();

  /// Step 2: send [text] and get Gemini's reply back, piece by piece.
  ///
  /// With `DemoConfig.useStreaming` on, pieces arrive while Gemini is still
  /// writing. With it off, the whole reply arrives as one piece.
  Stream<ReplyPiece> sendMessage(String text) async* {
    // Set up for every message, so changes to AppConfig and DemoConfig
    // apply straight after a hot reload (r).
    final model = FirebaseAI.googleAI().generativeModel(
      model: AppConfig.model,
      systemInstruction: Content.system(AppConfig.systemPrompt),
      // Google Search on: Gemini may search the web, then list its sources.
      tools: DemoConfig.useGoogleSearch ? [Tool.googleSearch()] : null,
    );
    final chat = model.startChat(history: [..._history]);
    final message = Content.text(text);

    if (DemoConfig.useStreaming) {
      await for (final chunk in chat.sendMessageStream(message)) {
        yield _toPiece(chunk);
      }
    } else {
      yield _toPiece(await chat.sendMessage(message));
    }

    // Remember this exchange, so the next message can refer back to it.
    _history
      ..clear()
      ..addAll(chat.history);
  }

  /// Turns Gemini's response into a ReplyPiece. With Google Search on, it
  /// also lists the web pages the answer came from.
  ReplyPiece _toPiece(GenerateContentResponse response) {
    final grounding = response.candidates.firstOrNull?.groundingMetadata;
    if (grounding == null) return ReplyPiece(response.text ?? '');

    return ReplyPiece(
      response.text ?? '',
      citations: [
        for (final chunk in grounding.groundingChunks)
          ChatCitation(
            title: chunk.web?.title ?? 'Source',
            url: chunk.web?.uri ?? '',
          ),
      ],
      citedQuotes: [
        for (final support in grounding.groundingSupports)
          (
            quote: support.segment.text,
            numbers: [for (final i in support.groundingChunkIndices) i + 1],
          ),
      ],
      searchSuggestions: grounding.searchEntryPoint?.renderedContent,
    );
  }
}
