import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class ArDownloadException implements Exception {
  ArDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Mengunduh berkas (model, marker) ke folder cache aplikasi.
/// Nama berkas di Supabase unik, jadi cache aman dipakai ulang.
class ArAssetCache {
  ArAssetCache._();

  static Future<Directory> _cacheDir() async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/ar_cache');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _fileNameFor(String url) {
    final uri = Uri.parse(url);
    final last = uri.pathSegments.isEmpty ? 'file' : uri.pathSegments.last;
    final safe = last.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return '${url.hashCode.toUnsigned(32).toRadixString(16)}_$safe';
  }

  static Future<File> fetch(
    String url, {
    void Function(double? fraction)? onProgress,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArDownloadException('Link tidak valid: $url');
    }

    final dir = await _cacheDir();
    final target = File('${dir.path}/${_fileNameFor(url)}');
    if (await target.exists() && await target.length() > 0) {
      onProgress?.call(1);
      return target;
    }

    final part = File('${target.path}.part');
    final client = http.Client();

    try {
      final response =
          await client.send(http.Request('GET', uri)).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw ArDownloadException(_httpMessage(response.statusCode, uri));
      }

      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = part.openWrite();
      try {
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 30))) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(
            total > 0 ? (received / total).clamp(0.0, 1.0).toDouble() : null,
          );
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      await part.rename(target.path);
      return target;
    } on ArDownloadException {
      await _deleteQuietly(part);
      rethrow;
    } on TimeoutException {
      await _deleteQuietly(part);
      throw ArDownloadException(
        'Unduhan terhenti (tidak ada data selama 30 detik). Periksa internet.',
      );
    } catch (e) {
      await _deleteQuietly(part);
      throw ArDownloadException(
        'Tidak bisa mengunduh dari ${uri.host}. Periksa internet dan link file. ($e)',
      );
    } finally {
      client.close();
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  static Future<void> delete(File file) => _deleteQuietly(file);

  /// Berkas GLB selalu diawali empat byte "glTF".
  static Future<bool> looksLikeGlb(File file) async {
    try {
      final raf = await file.open();
      try {
        final head = await raf.read(4);
        return head.length == 4 &&
            head[0] == 0x67 &&
            head[1] == 0x6C &&
            head[2] == 0x54 &&
            head[3] == 0x46;
      } finally {
        await raf.close();
      }
    } catch (_) {
      return false;
    }
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _httpMessage(int code, Uri uri) {
    switch (code) {
      case 404:
        return 'File tidak ditemukan (404) di ${uri.host}. Periksa link atau unggah ulang.';
      case 401:
      case 403:
        return 'Akses ke file ditolak ($code). Pastikan file bersifat publik.';
      default:
        return 'Server ${uri.host} menjawab HTTP $code.';
    }
  }
}