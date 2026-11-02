import 'dart:typed_data';

import '../../../core/errors/failures.dart';
import '../../../core/utils/media_links.dart';
import '../../entities/branding.dart';
import '../../repositories/ar_storage_repository.dart';
import '../../repositories/branding_repository.dart';

/// Dipakai aplikasi saat start. Tidak pernah gagal: jika branding tidak bisa
/// dibaca, aplikasi memakai nama dan logo bawaan.
class GetBrandingUseCase {
  const GetBrandingUseCase(this._repo);

  final BrandingRepository _repo;

  Future<Branding> call() async {
    try {
      return await _repo.getBranding();
    } catch (_) {
      return Branding.defaults;
    }
  }
}

/// Dipakai form admin. Gagal membaca berarti error, bukan nilai bawaan,
/// supaya menyimpan tidak menimpa logo yang sudah ada.
class GetBrandingFormUseCase {
  const GetBrandingFormUseCase(this._repo);

  final BrandingRepository _repo;

  Future<Branding> call() => _repo.getBranding();
}

class SaveBrandingUseCase {
  const SaveBrandingUseCase(this._repo);

  final BrandingRepository _repo;

  /// Mengembalikan nilai yang sudah dirapikan dan disimpan.
  Future<Branding> call(Branding input) async {
    final name = input.appName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) throw const Failure('Nama aplikasi wajib diisi.');
    if (name.length > 40) {
      throw const Failure(
        'Nama aplikasi terlalu panjang (maksimal 40 karakter).',
      );
    }

    final logo = input.logoUrl.trim();
    if (logo.isNotEmpty && !isValidHttpUrl(logo)) {
      throw const Failure(
        'Link logo tidak valid. Gunakan alamat yang diawali https://',
      );
    }

    final cleaned = Branding(appName: name, logoUrl: logo);
    await _repo.saveBranding(cleaned);
    return cleaned;
  }
}

class UploadBrandingLogoUseCase {
  const UploadBrandingLogoUseCase(this._storage);

  final ArStorageRepository _storage;

  static const _maxBytes = 2 * 1024 * 1024;

  Future<String> call({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dot = fileName.lastIndexOf('.');
    final ext = dot < 0 ? '' : fileName.substring(dot + 1).toLowerCase();

    if (ext == 'svg') {
      throw const Failure(
        'Format SVG belum didukung. Ekspor logo ke PNG (disarankan latar transparan).',
      );
    }
    if (!const ['png', 'jpg', 'jpeg', 'webp'].contains(ext)) {
      throw const Failure('Logo harus berformat PNG, JPG, atau WebP.');
    }
    if (bytes.isEmpty) throw const Failure('File kosong.');
    if (bytes.length > _maxBytes) {
      throw Failure(
        'Ukuran logo ${(bytes.length / (1024 * 1024)).toStringAsFixed(1)} MB '
        'melebihi batas 2 MB.',
      );
    }
    if (!_looksLikeImage(bytes, ext)) {
      throw const Failure('Isi file bukan gambar yang valid.');
    }

    final contentType = ext == 'png'
        ? 'image/png'
        : ext == 'webp'
        ? 'image/webp'
        : 'image/jpeg';

    return _storage.upload(
      bytes: bytes,
      objectPath: 'branding/${DateTime.now().millisecondsSinceEpoch}_logo.$ext',
      contentType: contentType,
    );
  }

  static bool _looksLikeImage(Uint8List b, String ext) {
    if (b.length < 12) return false;
    switch (ext) {
      case 'png':
        return b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;
      case 'webp':
        return b[0] == 0x52 &&
            b[1] == 0x49 &&
            b[2] == 0x46 &&
            b[3] == 0x46 &&
            b[8] == 0x57 &&
            b[9] == 0x45 &&
            b[10] == 0x42 &&
            b[11] == 0x50;
      default:
        return b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF;
    }
  }
}
