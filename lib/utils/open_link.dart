import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in an in-app browser, falling back to the phone's browser.
/// Returns false if nothing could open it.
Future<bool> openLink(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return false;

  for (final mode in [
    LaunchMode.inAppBrowserView,
    LaunchMode.externalApplication,
    LaunchMode.platformDefault,
  ]) {
    try {
      if (await launchUrl(uri, mode: mode)) return true;
    } catch (_) {
      // Try the next mode.
    }
  }
  return false;
}
