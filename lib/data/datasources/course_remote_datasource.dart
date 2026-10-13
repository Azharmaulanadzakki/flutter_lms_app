import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/failures.dart';
import '../models/course_material_model.dart';
import '../models/course_model.dart';

abstract class CourseRemoteDataSource {
  Future<List<CourseModel>> getPublishedCourses();
  Future<Map<String, int>> getPublishedMaterialCounts();
  Future<CourseModel> getCourseById(String courseId);
  Future<List<CourseMaterialModel>> getPublishedMaterials(String courseId);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  CourseRemoteDataSourceImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<List<CourseModel>> getPublishedCourses() async {
    // Diurutkan di sisi aplikasi supaya tidak butuh composite index.
    final snap = await _db
        .collection(FirestorePaths.courses)
        .where('isPublished', isEqualTo: true)
        .get();

    final list = snap.docs.map(CourseModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  @override
  Future<Map<String, int>> getPublishedMaterialCounts() async {
    final snap = await _db
        .collection(FirestorePaths.materials)
        .where('isPublished', isEqualTo: true)
        .get();

    final counts = <String, int>{};
    for (final doc in snap.docs) {
      final courseId = doc.data()['courseId'] as String?;
      if (courseId == null) continue;
      counts[courseId] = (counts[courseId] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<CourseModel> getCourseById(String courseId) async {
    final snap =
        await _db.collection(FirestorePaths.courses).doc(courseId).get();
    final data = snap.data();
    if (!snap.exists || data == null || data['isPublished'] != true) {
      throw const Failure('Course tidak tersedia.');
    }
    return CourseModel.fromFirestore(snap);
  }

  @override
  Future<List<CourseMaterialModel>> getPublishedMaterials(
    String courseId,
  ) async {
    final snap = await _db
        .collection(FirestorePaths.materials)
        .where('courseId', isEqualTo: courseId)
        .where('isPublished', isEqualTo: true)
        .get();

    final list = snap.docs.map(CourseMaterialModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}