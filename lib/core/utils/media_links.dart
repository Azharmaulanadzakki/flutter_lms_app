/// Mengambil ID video dari berbagai bentuk link YouTube.
/// Mengembalikan null jika link tidak dikenali.
String? extractYoutubeId(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;

  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);
  if (host.startsWith('m.')) host = host.substring(2);

  String? id;
  if (host == 'youtu.be') {
    id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  } else if (host == 'youtube.com' || host == 'youtube-nocookie.com') {
    if (uri.path == '/watch') {
      id = uri.queryParameters['v'];
    } else if (uri.pathSegments.length >= 2 &&
        const {'embed', 'shorts', 'live', 'v'}.contains(uri.pathSegments.first)) {
      id = uri.pathSegments[1];
    }
  }

  if (id == null) return null;
  return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
}

/// Mengambil ID file dari link Google Drive.
String? extractDriveFileId(String url) {
  final match = RegExp(r'/file/d/([A-Za-z0-9_-]+)').firstMatch(url);
  if (match != null) return match.group(1);

  final uri = Uri.tryParse(url.trim());
  if (uri != null && uri.host.contains('drive.google.com')) {
    return uri.queryParameters['id'];
  }
  return null;
}

/// URL yang dibuka di WebView untuk menampilkan PDF.
/// - Link Google Drive: penampil bawaan Drive (file harus
///   dibagikan "Anyone with the link").
/// - URL PDF lain: lewat penampil Google Docs.
String pdfViewerUrl(String url) {
  final id = extractDriveFileId(url);
  if (id != null) return 'https://drive.google.com/file/d/$id/preview';
  return 'https://docs.google.com/gview?embedded=1&url=${Uri.encodeComponent(url.trim())}';
}

/// True jika [url] adalah URL http/https yang valid.
bool isValidHttpUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}