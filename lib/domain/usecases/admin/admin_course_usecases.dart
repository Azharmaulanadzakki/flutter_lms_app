import 'dart:math';

import '../../../core/errors/failures.dart';
import '../../../core/utils/media_links.dart';
import '../../entities/admin_entities.dart';
import '../../entities/course.dart';
import '../../repositories/admin_repository.dart';

class GetAdminCoursesUseCase {
  const GetAdminCoursesUseCase(this._admin);

  final AdminRepository _admin;

  Future<List<AdminCourseRow>> call() async {
    final courses = await _admin.getAllCourses();
    final materials = await _admin.getAllMaterials();

    final total = <String, int>{};
    final published = <String, int>{};
    for (final m in materials) {
      total[m.courseId] = (total[m.courseId] ?? 0) + 1;
      if (m.isPublished) {
        published[m.courseId] = (published[m.courseId] ?? 0) + 1;
      }
    }

    return [
      for (final c in courses)
        AdminCourseRow(
          course: c,
          materialCount: total[c.id] ?? 0,
          publishedMaterialCount: published[c.id] ?? 0,
        ),
    ];
  }
}

class GetAdminCourseDetailUseCase {
  const GetAdminCourseDetailUseCase(this._admin);

  final AdminRepository _admin;

  Future<AdminCourseDetail> call(String courseId) async {
    final course = await _admin.getCourse(courseId);
    final materials = await _admin.getMaterials(courseId);
    final tests = await _admin.getTests(courseId);

    final infos = <AdminTestInfo>[];
    for (final t in tests) {
      infos.add(
        AdminTestInfo(
          test: t,
          questionCount: await _admin.countQuestions(t.id),
        ),
      );
    }

    return AdminCourseDetail(
      course: course,
      materials: materials,
      tests: infos,
    );
  }
}

/// Data awal untuk form course: course yang diedit, atau course kosong
/// (urutan otomatis, belum dipublikasikan) jika [courseId] null.
class GetCourseFormUseCase {
  const GetCourseFormUseCase(this._admin);

  final AdminRepository _admin;

  Future<Course> call(String? courseId) async {
    if (courseId != null) return _admin.getCourse(courseId);

    final courses = await _admin.getAllCourses();
    final nextOrder = courses.isEmpty
        ? 1
        : courses.map((c) => c.order).reduce(max) + 1;

    return Course(
      id: '',
      title: '',
      description: '',
      thumbnailUrl: '',
      level: SaveCourseUseCase.levels.first,
      duration: 30,
      order: nextOrder,
      isPublished: false,
    );
  }
}

class SaveCourseUseCase {
  const SaveCourseUseCase(this._admin);

  final AdminRepository _admin;

  static const levels = ['Dasar', 'Menengah', 'Lanjut'];

  Future<String> call(Course course) async {
    final title = course.title.trim();
    if (title.isEmpty) throw const Failure('Judul course wajib diisi.');
    if (course.duration < 1) throw const Failure('Durasi minimal 1 menit.');
    if (course.order < 1) throw const Failure('Urutan minimal 1.');

    final thumb = course.thumbnailUrl.trim();
    if (thumb.isNotEmpty && !isValidHttpUrl(thumb)) {
      throw const Failure(
        'URL thumbnail tidak valid. Gunakan alamat yang diawali https://',
      );
    }

    final objectives = [
      for (final o in course.objectives)
        if (o.trim().isNotEmpty) o.trim(),
    ];

    return _admin.saveCourse(
      Course(
        id: course.id,
        title: title,
        description: course.description.trim(),
        thumbnailUrl: thumb,
        level: levels.contains(course.level) ? course.level : levels.first,
        duration: course.duration,
        order: course.order,
        objectives: objectives,
        hasGame: course.hasGame,
        missionIds: course.hasGame ? course.missionIds : const [],
        isPublished: course.isPublished,
      ),
    );
  }
}

class SetCoursePublishedUseCase {
  const SetCoursePublishedUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(String courseId, bool published) =>
      _admin.setCoursePublished(courseId, published);
}

/// Course hanya bisa dihapus jika sudah tidak punya materi dan test.
class DeleteCourseUseCase {
  const DeleteCourseUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(String courseId) async {
    final materials = await _admin.getMaterials(courseId);
    if (materials.isNotEmpty) {
      throw Failure(
        'Course masih punya ${materials.length} materi. '
        'Hapus materinya dulu, atau sembunyikan course saja.',
      );
    }

    final tests = await _admin.getTests(courseId);
    if (tests.isNotEmpty) {
      throw Failure(
        'Course masih punya ${tests.length} test. '
        'Hapus testnya dulu, atau sembunyikan course saja.',
      );
    }

    await _admin.deleteCourse(courseId);
  }
}
