import 'dart:math';

import '../../../core/errors/failures.dart';
import '../../../core/utils/media_links.dart';
import '../../entities/course_material.dart';
import '../../repositories/admin_repository.dart';

/// Data awal untuk form materi: materi yang diedit, atau materi kosong
/// (urutan otomatis, belum dipublikasikan) jika [materialId] null.
class GetMaterialFormUseCase {
  const GetMaterialFormUseCase(this._admin);

  final AdminRepository _admin;

  Future<CourseMaterial> call({
    required String courseId,
    String? materialId,
  }) async {
    if (materialId != null) return _admin.getMaterial(materialId);

    final existing = await _admin.getMaterials(courseId);
    final nextOrder =
        existing.isEmpty ? 1 : existing.map((m) => m.order).reduce(max) + 1;

    return CourseMaterial(
      id: '',
      courseId: courseId,
      title: '',
      content: '',
      type: MaterialKind.text,
      mediaUrl: '',
      order: nextOrder,
      isPublished: false,
    );
  }
}

class SaveMaterialUseCase {
  const SaveMaterialUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(CourseMaterial material) async {
    final title = material.title.trim();
    final content = material.content.trim();
    final url = material.mediaUrl.trim();

    if (title.isEmpty) throw const Failure('Judul materi wajib diisi.');
    if (material.order < 1) throw const Failure('Urutan minimal 1.');

    switch (material.type) {
      case MaterialKind.text:
        if (material.isPublished && content.isEmpty) {
          throw const Failure('Isi materi wajib diisi sebelum dipublikasikan.');
        }
      case MaterialKind.video:
        if (url.isEmpty) {
          if (material.isPublished) {
            throw const Failure('Link video wajib diisi sebelum dipublikasikan.');
          }
        } else if (extractYoutubeId(url) == null) {
          throw const Failure(
            'Link YouTube tidak valid. Contoh: https://www.youtube.com/watch?v=xxxxxxxxxxx',
          );
        }
      case MaterialKind.pdf:
        if (url.isEmpty) {
          if (material.isPublished) {
            throw const Failure('Link PDF wajib diisi sebelum dipublikasikan.');
          }
        } else if (!isValidHttpUrl(url)) {
          throw const Failure(
            'Link PDF tidak valid. Gunakan alamat yang diawali https://',
          );
        }
    }

    await _admin.saveMaterial(CourseMaterial(
      id: material.id,
      courseId: material.courseId,
      title: title,
      content: content,
      type: material.type,
      mediaUrl: url,
      order: material.order,
      isPublished: material.isPublished,
    ));
  }
}

class SetMaterialPublishedUseCase {
  const SetMaterialPublishedUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(String materialId, bool published) =>
      _admin.setMaterialPublished(materialId, published);
}

class DeleteMaterialUseCase {
  const DeleteMaterialUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(String materialId) => _admin.deleteMaterial(materialId);
}