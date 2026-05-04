import 'dart:html' as html;

void openUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    html.window.open(url, '_blank');
  }
}
