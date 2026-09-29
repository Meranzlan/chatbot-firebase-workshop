/// =============================================================================
/// LIVE DEMO FEATURE TOGGLES
///
/// Flip any value between `true` and `false`, then press `r` (Hot Reload)
/// to show a "before vs after" of that feature.
/// =============================================================================
class DemoConfig {
  /// 1. Streaming: Gemini's reply appears word by word while it is being
  /// written (true), or all at once when it is finished (false).
  static const bool useStreaming = false;

  /// 2. Grounding with Google Search: Gemini can search Google for fresh
  /// facts and shows the pages it used (true), or answers only from what it
  /// learned in training (false). Try "What's the latest iPhone?" both ways.
  static const bool useGoogleSearch = false;

  /// 3. Timestamps (`10:46`) inside chat bubbles.
  static const bool showTimestamp = true;

  /// 4. "Copy" button on bot replies.
  static const bool showCopyButton = true;

  /// 5. 👍 / 👎 buttons on bot replies.
  static const bool showFeedbackActions = false;

  /// 6. Four suggested prompt cards on the empty welcome screen.
  static const bool showSuggestedPrompts = false;

  /// 7. "Powered by …" disclaimer under the input bar.
  static const bool showDisclaimerFooter = false;

  /// 8. Sparkle icon inside the input bar.
  static const bool showInputSparkle = false;

  /// 9. "AI Assistant is thinking..." label next to the typing animation.
  static const bool showTypingText = true;

  /// 10. Typing animation: `flutter_spinkit` wave (true) or Flutter's
  /// built-in spinner (false).
  static const bool useSpinKitWave = true;
}
