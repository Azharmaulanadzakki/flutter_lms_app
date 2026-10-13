import 'package:url_launcher/url_launcher.dart';

/// Membuka link di aplikasi luar (browser / YouTube).
/// Mengembalikan false jika gagal.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url.trim());
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}