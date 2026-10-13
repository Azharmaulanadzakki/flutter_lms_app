import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/course_progress.dart';
import '../models/course_progress_model.dart';

abstract class ProgressRemoteDataSource {
  Future<Map<String, CourseProgressModel>> getUserProgress(String userId);

  Future<void> saveMaterialProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  });

  Future<void> savePreTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
  });

  Future<void> savePostTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  });
}

class ProgressRemoteDataSourceImpl implements ProgressRemoteDataSource {
  ProgressRemoteDataSourceImpl(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String userId, String courseId) =>
      _db
          .collection(FirestorePaths.courseProgress)
          .doc(FirestorePaths.progressId(userId, courseId));

  @override
  Future<Map<String, CourseProgressModel>> getUserProgress(
    String userId,
  ) async {
    final snap = await _db
        .collection(FirestorePaths.courseProgress)
        .where('userId', isEqualTo: userId)
        .get();

    final result = <String, CourseProgressModel>{};
    for (final doc in snap.docs) {
      final model = CourseProgressModel.fromFirestore(doc);
      if (model.courseId.isNotEmpty) result[model.courseId] = model;
    }
    return result;
  }

  @override
  Future<void> saveMaterialProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  }) {
    // merge: true -> field lain (nilai test, status game) tidak tertimpa.
    return _ref(userId, progress.courseId).set(
      {
        'userId': userId,
        'courseId': progress.courseId,
        'completedMaterialIds': progress.completedMaterialIds,
        'materialProgress': progress.materialProgress,
        'progressPercentage': progress.progressPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
        if (setStartedAt) 'startedAt': FieldValue.serverTimestamp(),
        if (setCompletedAt) 'completedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> savePreTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
  }) {
    return _ref(userId, progress.courseId).set(
      {
        'userId': userId,
        'courseId': progress.courseId,
        'preTestCompleted': true,
        'preTestScore': progress.preTestScore,
        'progressPercentage': progress.progressPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
        if (setStartedAt) 'startedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  @override
  Future<void> savePostTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  }) {
    return _ref(userId, progress.courseId).set(
      {
        'userId': userId,
        'courseId': progress.courseId,
        'postTestCompleted': true,
        'postTestScore': progress.postTestScore,
        'progressPercentage': progress.progressPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
        if (setStartedAt) 'startedAt': FieldValue.serverTimestamp(),
        if (setCompletedAt) 'completedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}