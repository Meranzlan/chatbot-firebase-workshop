/// Which AI the app talks to, and how it behaves.
class AppConfig {
  /// Shown in the app bar, the typing indicator and the disclaimer.
  static const String botName = 'AI Assistant';

  /// Shown under the bot name.
  static const String poweredBy = 'Gemini · Firebase AI Logic';

  /// The Gemini model that writes the replies. Google retires old models, so
  /// if you see "model is no longer available", pick a current one from
  /// https://firebase.google.com/docs/ai-logic/models and hot reload (`r`).
  static const String model = 'gemini-3.8-flash';

  /// Instructions Gemini follows in every reply: its personality.
  /// Change it, then hot reload (`r`); the next message uses it.
  static const String systemPrompt =
      'You are a helpful assistant. Answer briefly and politely. '
      'Reply in the same language the user writes in.';
}
