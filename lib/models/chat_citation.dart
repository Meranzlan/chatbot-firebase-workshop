/// A web page Gemini used for its answer (Grounding with Google Search).
class ChatCitation {
  const ChatCitation({required this.title, required this.url});

  /// Usually the site's name, e.g. "apple.com".
  final String title;

  /// Link to the page.
  final String url;
}
