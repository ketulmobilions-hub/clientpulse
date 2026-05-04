import 'package:url_launcher/url_launcher.dart';

void openUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
    launchUrl(uri, mode: LaunchMode.externalApplication).ignore();
  }
}
