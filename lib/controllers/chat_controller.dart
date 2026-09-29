import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/chat_message.dart';
import '../models/reply_piece.dart';
import '../repository/chatbot_repository.dart';

/// The brain of the chat screen.
///
/// It keeps the conversation state, asks [ChatbotRepository] to talk to
/// Gemini, and calls `notifyListeners()` whenever something changes so the
/// screen redraws.
class ChatController extends ChangeNotifier {
  ChatController({
    ChatbotRepository? repository,
    this.retryDelay = const Duration(seconds: 2),
  }) : _repository = repository ?? ChatbotRepository();

  final ChatbotRepository _repository;

  /// How long to wait before asking again when Gemini is too busy.
  final Duration retryDelay;

  /// How many times to ask again before showing an error.
  static const maxRetries = 2;

  // ── State the screen reads ───────────────────────────────────────────────
  final List<ChatMessage> _messages = [];
  bool _isBotReplying = false;
  String? _errorMessage;
  bool _disposed = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  String? get errorMessage => _errorMessage;
  String get botName => AppConfig.botName;

  /// True from sending until the reply is complete. Locks the input bar.
  bool get isBotReplying => _isBotReplying;

  /// True until the first words of the reply arrive: shows "thinking...".
  bool get isThinking => _isBotReplying && _messages.last.isUser;

  /// Step 1: clear the screen and start a fresh conversation.
  /// Used by the "New conversation" button.
  void startConversation() {
    _repository.startConversation();
    _messages.clear();
    _errorMessage = null;
    _notify();
  }

  /// Step 2: show the user's message, then Gemini's reply as it arrives.
  Future<void> sendUserMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isBotReplying) return;

    _messages.add(ChatMessage.fromUser(trimmed));
    _isBotReplying = true;
    _errorMessage = null;
    _notify();

    try {
      await _getReply(trimmed);
    } catch (e) {
      _errorMessage = _describe(e);
    }

    _isBotReplying = false;
    _notify();
  }

  /// Adds Gemini's reply to the chat, piece by piece. If Gemini is too busy
  /// to start answering, waits [retryDelay] and asks again, up to
  /// [maxRetries] times, before giving up.
  Future<void> _getReply(String text, {int retriesLeft = maxRetries}) async {
    try {
      ReplyPiece? sources;
      await for (final piece in _repository.sendMessage(text)) {
        _addToReply(piece.text);
        // With Google Search on, a piece lists the web pages used. Keep the
        // newest, and add it once the whole answer is on screen.
        if (piece.hasSources) sources = piece;
      }
      if (sources != null) _addSources(sources);
    } catch (e) {
      // Only ask again while no words are on screen, or two different
      // answers would end up mixed in one bubble.
      if (_isBusy(e) && isThinking && retriesLeft > 0) {
        await Future<void>.delayed(retryDelay);
        return _getReply(text, retriesLeft: retriesLeft - 1);
      }
      rethrow;
    }
  }

  /// The first words start the bot's bubble; later pieces make it longer.
  void _addToReply(String more) {
    if (more.isEmpty) return; // e.g. a piece that only lists sources
    if (_messages.last.isUser) {
      _messages.add(ChatMessage.fromBot(more));
    } else {
      _messages.last = _messages.last.append(more);
    }
    _notify();
  }

  /// Numbers the quotes that came from web pages and lists those pages.
  void _addSources(ReplyPiece sources) {
    if (_messages.last.isUser) return; // No answer to attach them to.
    _messages.last = _messages.last.withSources(sources);
    _notify();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Gemini turns requests away when too many people use it at once.
  bool _isBusy(Object error) {
    final text = '$error';
    return text.contains('high demand') || text.contains('overloaded');
  }

  /// Turns the errors people hit most often into a next step.
  String _describe(Object error) {
    final text = '$error';
    if (text.contains('App attestation failed')) {
      return 'App Check blocked this device. Register its debug token in the '
          'Firebase console (see README → Troubleshooting).';
    }
    if (_isBusy(error)) {
      return 'Gemini is very busy right now. Wait a few seconds, then send '
          'your message again.';
    }
    if (text.contains('exceeded your current quota')) {
      return 'This Firebase project has no Gemini quota left for that. The '
          'free tier has a daily limit (it resets at midnight Pacific time) '
          'and doesn\'t include Google Search. For more, upgrade the project '
          'to the Blaze (pay-as-you-go) plan.';
    }
    if (text.contains('models/') &&
        (text.contains('no longer available') || text.contains('not found'))) {
      return 'Gemini can\'t use the model "${AppConfig.model}". Pick a '
          'supported one in AppConfig.model, then hot reload (r).';
    }
    return 'Something went wrong: $text';
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
