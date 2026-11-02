/// Mengubah link halaman file GitHub menjadi link langsung (raw).
/// Link lain dikembalikan apa adanya (hanya dirapikan spasinya).
String normalizeAssetUrl(String raw) {
  final url = raw.trim();
  final match =
      RegExp(r'^https://github\.com/([^/]+)/([^/]+)/blob/(.+)$').firstMatch(url);
  if (match == null) return url;

  final tail = match.group(3)!.split('?').first.split('#').first;
  return 'https://raw.githubusercontent.com/${match.group(1)}/${match.group(2)}/$tail';
}

const _blockedHosts = [
  'drive.google.com',
  'docs.google.com',
  'dropbox.com',
  'sketchfab.com',
];

/// Mengembalikan pesan error, atau null jika link valid.
/// [extension] contoh: '.mind' atau '.glb'.
String? validateAssetUrl(
  String raw, {
  required String label,
  required String extension,
}) {
  final url = normalizeAssetUrl(raw);
  if (url.isEmpty) return '$label wajib diisi';

  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return '$label tidak valid';
  if (uri.scheme != 'https') return '$label harus diawali https://';

  final host = uri.host.toLowerCase();
  if (_blockedHosts.any(host.contains)) {
    return '$label tidak bisa memakai Google Drive, Dropbox, atau Sketchfab. '
        'Gunakan GitHub (lihat panduan)';
  }
  if (!uri.path.toLowerCase().endsWith(extension)) {
    return '$label harus berupa file $extension';
  }
  return null;
}

/// Untuk link opsional (misalnya gambar marker). Kosong dianggap valid.
String? validateOptionalUrl(String raw, {required String label}) {
  final url = normalizeAssetUrl(raw);
  if (url.isEmpty) return null;

  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty || uri.scheme != 'https') {
    return '$label harus diawali https://';
  }
  return null;
}