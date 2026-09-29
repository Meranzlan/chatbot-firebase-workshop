import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../utils/open_link.dart';

/// Google's "search suggestions" chips, shown under every answer that used
/// Google Search. Google's rules say to show its ready-made HTML exactly as
/// provided, so it's drawn in a small web view. A tapped chip opens the
/// Google results page in the browser, full size.
/// You don't need to read this file to follow the chatbot flow.
class SearchSuggestions extends StatefulWidget {
  const SearchSuggestions({super.key, required this.html});

  final String html;

  @override
  State<SearchSuggestions> createState() => _SearchSuggestionsState();
}

class _SearchSuggestionsState extends State<SearchSuggestions> {
  late final WebViewController _web;

  /// Replaced with the real height once the chips have been drawn.
  double _height = 60;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            // Loading our own page: let it through.
            if (!request.url.startsWith('http')) {
              return NavigationDecision.navigate;
            }
            // A tapped chip: open Google in the browser instead.
            openLink(request.url);
            return NavigationDecision.prevent;
          },
          onPageFinished: (_) => _fitHeight(),
        ),
      )
      ..loadHtmlString(_page(widget.html));
  }

  Future<void> _fitHeight() async {
    final result = await _web.runJavaScriptReturningResult(
      'document.body.scrollHeight',
    );
    final height = double.tryParse('$result');
    if (height != null && height > 0 && mounted) {
      setState(() => _height = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: WebViewWidget(
        controller: _web,
        // Sideways swipes scroll the chips; up and down still scroll the chat.
        gestureRecognizers: {
          Factory<HorizontalDragGestureRecognizer>(
            HorizontalDragGestureRecognizer.new,
          ),
        },
      ),
    );
  }
}

/// Puts Google's snippet in a page as wide as the phone.
String _page(String html) =>
    '<!DOCTYPE html><html><head>'
    '<meta name="viewport" content="width=device-width, initial-scale=1">'
    '<style>body { margin: 0; }</style>'
    '</head><body>$html</body></html>';
