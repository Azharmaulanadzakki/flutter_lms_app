import 'dart:math';

import '../../../core/errors/failures.dart';
import '../../../core/utils/ar_links.dart';
import '../../entities/ar_item.dart';
import '../../repositories/ar_repository.dart';

class GetPublishedArItemsUseCase {
  const GetPublishedArItemsUseCase(this._repo);

  final ArRepository _repo;

  Future<List<ArItem>> call() => _repo.getPublishedItems();
}

class GetAllArItemsUseCase {
  const GetAllArItemsUseCase(this._repo);

  final ArRepository _repo;

  Future<List<ArItem>> call() => _repo.getAllItems();
}

class GetArItemUseCase {
  const GetArItemUseCase(this._repo);

  final ArRepository _repo;

  Future<ArItem> call(String id) => _repo.getItem(id);
}

/// Data awal form: item yang diedit, atau item kosong (urutan otomatis,
/// belum dipublikasikan) jika [id] null.
class GetArFormUseCase {
  const GetArFormUseCase(this._repo);

  final ArRepository _repo;

  Future<ArItem> call(String? id) async {
    if (id != null) return _repo.getItem(id);

    final items = await _repo.getAllItems();
    final nextOrder = items.isEmpty
        ? 1
        : items.map((i) => i.order).reduce(max) + 1;

    return ArItem(
      id: '',
      title: '',
      description: '',
      markerUrl: '',
      modelUrl: '',
      order: nextOrder,
    );
  }
}

class SaveArItemUseCase {
  const SaveArItemUseCase(this._repo);

  final ArRepository _repo;

  Future<String> call(ArItem item) async {
    final title = item.title.trim();
    if (title.isEmpty) throw const Failure('Judul wajib diisi.');

    final modelError = validateAssetUrl(
      item.modelUrl,
      label: 'Link model',
      extension: '.glb',
    );
    if (modelError != null) throw Failure('$modelError.');

    // Marker (.mind) opsional: hanya untuk mode AR marker.
    final markerRaw = item.markerUrl.trim();
    if (markerRaw.isNotEmpty) {
      final markerError = validateAssetUrl(
        markerRaw,
        label: 'Link marker',
        extension: '.mind',
      );
      if (markerError != null) throw Failure('$markerError.');

      if (item.markerImageUrl.trim().isEmpty) {
        throw const Failure(
          'Gambar marker wajib diisi jika memakai marker (.mind), '
          'supaya siswa tahu gambar apa yang harus di-scan.',
        );
      }
    }

    final imageError = validateOptionalUrl(
      item.markerImageUrl,
      label: 'Link gambar marker',
    );
    if (imageError != null) throw Failure('$imageError.');

    if (!item.scale.isFinite || item.scale <= 0 || item.scale > 1000) {
      throw const Failure('Skala harus lebih dari 0 dan maksimal 1000.');
    }
    final numbers = [
      item.offsetY,
      item.rotationX,
      item.rotationY,
      item.rotationZ,
    ];
    if (numbers.any((n) => !n.isFinite)) {
      throw const Failure('Posisi dan rotasi harus berupa angka.');
    }
    if (item.order < 1) throw const Failure('Urutan minimal 1.');

    return _repo.saveItem(
      ArItem(
        id: item.id,
        title: title,
        description: item.description.trim(),
        markerUrl: normalizeAssetUrl(markerRaw),
        modelUrl: normalizeAssetUrl(item.modelUrl),
        markerImageUrl: normalizeAssetUrl(item.markerImageUrl),
        credit: item.credit.trim(),
        scale: item.scale,
        offsetY: item.offsetY,
        rotationX: item.rotationX,
        rotationY: item.rotationY,
        rotationZ: item.rotationZ,
        animate: item.animate,
        order: item.order,
        isPublished: item.isPublished,
      ),
    );
  }
}

class SetArItemPublishedUseCase {
  const SetArItemPublishedUseCase(this._repo);

  final ArRepository _repo;

  Future<void> call(String id, bool published) =>
      _repo.setPublished(id, published);
}

class DeleteArItemUseCase {
  const DeleteArItemUseCase(this._repo);

  final ArRepository _repo;

  Future<void> call(String id) => _repo.deleteItem(id);
}
