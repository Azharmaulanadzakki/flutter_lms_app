import '../entities/course_progress.dart';

abstract class ProgressRepository {
  /// courseId -> progress milik [userId].
  Future<Map<String, CourseProgress>> getUserProgress(String userId);

  /// Menyimpan progress materi. Field lain di dokumen tidak disentuh.
  Future<void> saveMaterialProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  });

  /// Menyimpan hasil pre-test dan persentase terbaru.
  Future<void> savePreTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
  });

  /// Menyimpan hasil post-test dan persentase terbaru.
  Future<void> savePostTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  });
}