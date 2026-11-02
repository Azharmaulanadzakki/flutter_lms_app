import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config/supabase_config.dart';
import '../../core/errors/failures.dart';

class SupabaseStorageDataSource {
  Future<String> upload({
    required Uint8List bytes,
    required String objectPath,
    required String contentType,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      throw const Failure(
        'Supabase belum dikonfigurasi. Isi url dan anonKey di lib/core/config/supabase_config.dart.',
      );
    }

    final key = SupabaseConfig.anonKey;
    final headers = <String, String>{
      'apikey': key,
      'Content-Type': contentType,
      'x-upsert': 'false',
      // Kunci lama berbentuk JWT (diawali eyJ) juga dikirim sebagai Bearer.
      if (key.startsWith('eyJ')) 'Authorization': 'Bearer $key',
    };

    final http.Response response;
    try {
      response = await http
          .post(
            SupabaseConfig.uploadUri(objectPath),
            headers: headers,
            body: bytes,
          )
          .timeout(const Duration(minutes: 5));
    } on TimeoutException {
      throw const Failure(
        'Unggah terlalu lama. Periksa internet atau perkecil ukuran file.',
      );
    } catch (_) {
      throw const Failure(
        'Tidak bisa terhubung ke Supabase. Periksa internet dan alamat project.',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return SupabaseConfig.publicUrl(objectPath);
    }
    throw Failure(_describe(response));
  }

  String _describe(http.Response response) {
    var message = '';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        message = (decoded['message'] ?? decoded['error'] ?? '').toString();
      }
    } catch (_) {
      message = response.body;
    }
    final lower = message.toLowerCase();

    if (lower.contains('row-level security') || response.statusCode == 403) {
      return 'Izin unggah ditolak Supabase. Pastikan policy INSERT untuk bucket '
          '"${SupabaseConfig.bucket}" sudah dibuat dan kunci anon benar.';
    }
    if (response.statusCode == 401 ||
        lower.contains('jwt') ||
        lower.contains('apikey')) {
      return 'Kunci Supabase ditolak. Salin ulang kunci "anon public" dari '
          'Project Settings → API.';
    }
    if (response.statusCode == 404 || lower.contains('bucket not found')) {
      return 'Bucket "${SupabaseConfig.bucket}" tidak ditemukan di Supabase.';
    }
    if (response.statusCode == 413 ||
        lower.contains('too large') ||
        lower.contains('maximum allowed size')) {
      return 'File melebihi batas ukuran bucket Supabase.';
    }
    if (lower.contains('mime')) {
      return 'Tipe file ditolak oleh pengaturan bucket Supabase.';
    }
    return 'Unggah gagal (HTTP ${response.statusCode}): $message';
  }
}
