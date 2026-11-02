import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_material.dart';
import '../../domain/entities/progress_weights.dart';
import '../../domain/entities/quiz_test.dart';
import '../models/course_material_model.dart';
import '../models/course_model.dart';
import '../models/course_progress_model.dart';
import '../models/quiz_test_model.dart';
import '../models/user_model.dart';

/// Operasi Firestore khusus admin. Rules menolak semua operasi ini
/// untuk akun yang bukan admin.
class AdminRemoteDataSource {
  AdminRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  FieldValue get _now => FieldValue.serverTimestamp();

  // ---------- Siswa dan progress ----------

  Future<List<UserModel>> getStudents() async {
    final snap = await _col(FirestorePaths.users)
        .where('role', isEqualTo: 'student')
        .get();

    return snap.docs.map(UserModel.fromFirestore).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<UserModel> getUser(String uid) async {
    final snap = await _col(FirestorePaths.users).doc(uid).get();
    if (!snap.exists) throw const Failure('Siswa tidak ditemukan.');
    return UserModel.fromFirestore(snap);
  }

  Future<List<StudentProgressRecord>> getAllProgress() async {
    final snap = await _col(FirestorePaths.courseProgress).get();

    final result = <StudentProgressRecord>[];
    for (final doc in snap.docs) {
      final userId = (doc.data()['userId'] as String?) ?? '';
      if (userId.isEmpty) continue;
      result.add(
        StudentProgressRecord(
          userId: userId,
          progress: CourseProgressModel.fromFirestore(doc),
        ),
      );
    }
    return result;
  }

  // ---------- Course ----------

  Future<List<CourseModel>> getAllCourses() async {
    final snap = await _col(FirestorePaths.courses).get();
    return snap.docs.map(CourseModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<CourseModel> getCourse(String courseId) async {
    final snap = await _col(FirestorePaths.courses).doc(courseId).get();
    if (!snap.exists) throw const Failure('Course tidak ditemukan.');
    return CourseModel.fromFirestore(snap);
  }

  Future<String> saveCourse(Course c) async {
    final data = <String, dynamic>{
      'title': c.title,
      'description': c.description,
      'thumbnailUrl': c.thumbnailUrl,
      'level': c.level,
      'duration': c.duration,
      'order': c.order,
      'objectives': c.objectives,
      'hasGame': c.hasGame,
      'missionIds': c.missionIds,
      'isPublished': c.isPublished,
      'updatedAt': _now,
    };

    if (c.id.isEmpty) {
      final ref = _col(FirestorePaths.courses).doc();
      await ref.set({...data, 'createdAt': _now});
      return ref.id;
    }

    await _col(FirestorePaths.courses).doc(c.id).update(data);
    return c.id;
  }

  Future<void> setCoursePublished(String courseId, bool published) {
    return _col(FirestorePaths.courses)
        .doc(courseId)
        .update({'isPublished': published, 'updatedAt': _now});
  }

  Future<void> deleteCourse(String courseId) =>
      _col(FirestorePaths.courses).doc(courseId).delete();

  // ---------- Materi ----------

  Future<List<CourseMaterialModel>> getAllMaterials() async {
    final snap = await _col(FirestorePaths.materials).get();
    return snap.docs.map(CourseMaterialModel.fromFirestore).toList();
  }

  Future<List<CourseMaterialModel>> getMaterials(String courseId) async {
    final snap = await _col(FirestorePaths.materials)
        .where('courseId', isEqualTo: courseId)
        .get();
    return snap.docs.map(CourseMaterialModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<CourseMaterialModel> getMaterial(String materialId) async {
    final snap = await _col(FirestorePaths.materials).doc(materialId).get();
    if (!snap.exists) throw const Failure('Materi tidak ditemukan.');
    return CourseMaterialModel.fromFirestore(snap);
  }

  Future<void> saveMaterial(CourseMaterial m) async {
    final data = <String, dynamic>{
      'courseId': m.courseId,
      'title': m.title,
      'content': m.content,
      'type': m.type.name,
      'mediaUrl': m.mediaUrl,
      'order': m.order,
      'isPublished': m.isPublished,
      'updatedAt': _now,
    };

    if (m.id.isEmpty) {
      await _col(FirestorePaths.materials)
          .doc()
          .set({...data, 'createdAt': _now});
      return;
    }
    await _col(FirestorePaths.materials).doc(m.id).update(data);
  }

  Future<void> setMaterialPublished(String materialId, bool published) {
    return _col(FirestorePaths.materials)
        .doc(materialId)
        .update({'isPublished': published, 'updatedAt': _now});
  }

  Future<void> deleteMaterial(String materialId) =>
      _col(FirestorePaths.materials).doc(materialId).delete();

  // ---------- Test ----------

  Future<List<QuizTestModel>> getTests(String courseId) async {
    final snap = await _col(FirestorePaths.tests)
        .where('courseId', isEqualTo: courseId)
        .get();
    return snap.docs.map(QuizTestModel.fromFirestore).toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));
  }

  Future<QuizTestModel?> getTest(String testId) async {
    final snap = await _col(FirestorePaths.tests).doc(testId).get();
    if (!snap.exists) return null;
    return QuizTestModel.fromFirestore(snap);
  }

  Future<int> countQuestions(String testId) async {
    final snap = await _col(FirestorePaths.questions)
        .where('testId', isEqualTo: testId)
        .get();
    return snap.docs.length;
  }

  Future<void> saveTest(QuizTest t) async {
    final ref = _col(FirestorePaths.tests).doc(t.id);
    final existing = await ref.get();

    await ref.set({
      'courseId': t.courseId,
      'type': t.type.value,
      'title': t.title,
      'questionCount': t.questionCount,
      'durationMinutes': t.durationMinutes,
      'isActive': t.isActive,
      'updatedAt': _now,
      if (!existing.exists) 'createdAt': _now,
    }, SetOptions(merge: true));
  }

  Future<void> setTestActive(String testId, bool active) {
    return _col(FirestorePaths.tests)
        .doc(testId)
        .update({'isActive': active, 'updatedAt': _now});
  }

  Future<void> deleteTest(String testId) =>
      _col(FirestorePaths.tests).doc(testId).delete();

  // ---------- Pengaturan ----------

  Future<void> saveProgressWeights(ProgressWeights w) {
    return _col(FirestorePaths.settings)
        .doc(FirestorePaths.progressWeightsDoc)
        .set({
          'preTest': w.preTest,
          'materials': w.materials,
          'game': w.game,
          'postTest': w.postTest,
          'updatedAt': _now,
        });
  }
}
