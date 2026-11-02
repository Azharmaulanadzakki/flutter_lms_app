import 'dart:typed_data';

import '../../../core/errors/failures.dart';
import '../../entities/ar_asset_kind.dart';
import '../../repositories/ar_storage_repository.dart';

class UploadArAssetUseCase {
  const UploadArAssetUseCase(this._repo);

  final ArStorageRepository _repo;

  Future<String> call({
    required Uint8List bytes,
    required String fileName,
    required ArAssetKind kind,
  }) async {
    final ext = _extensionOf(fileName);
    if (!kind.extensions.contains(ext)) {
      final allowed = kind.extensions.map((e) => '.$e').join(' / ');
      throw Failure('File ${kind.label} harus berekstensi $allowed.');
    }
    if (bytes.isEmpty) throw const Failure('File kosong.');
    if (bytes.length > kind.maxBytes) {
      throw Failure(
        'Ukuran file ${_mb(bytes.length)} melebihi batas ${_mb(kind.maxBytes)} untuk ${kind.label}.',
      );
    }
    if (kind == ArAssetKind.model && !_isGlb(bytes)) {
      throw const Failure(
        'File ini bukan GLB yang valid (isinya tidak diawali "glTF"). '
        'Di Sketchfab pilih format "glTF Binary (.glb)".',
      );
    }

    final path =
        '${kind.folder}/${DateTime.now().millisecondsSinceEpoch}_${_safeName(fileName)}';
    return _repo.upload(
      bytes: bytes,
      objectPath: path,
      contentType: kind.contentTypeFor(ext),
    );
  }

  static String _extensionOf(String name) {
    final dot = name.lastIndexOf('.');
    return dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static bool _isGlb(Uint8List b) =>
      b.length >= 4 &&
      b[0] == 0x67 &&
      b[1] == 0x6C &&
      b[2] == 0x54 &&
      b[3] == 0x46;

  static String _safeName(String name) {
    final lower = name.toLowerCase();
    final dot = lower.lastIndexOf('.');
    final base = dot > 0 ? lower.substring(0, dot) : lower;
    final ext = dot > 0 ? lower.substring(dot + 1) : '';

    var cleaned = base
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    if (cleaned.isEmpty) cleaned = 'file';
    if (cleaned.length > 40) cleaned = cleaned.substring(0, 40);
    return ext.isEmpty ? cleaned : '$cleaned.$ext';
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
