import '../../entities/course_progress.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import 'progress_calculator.dart';

/// Menyimpan skor post-test ke progress course, menghitung ulang persentase,
/// dan menandai course selesai jika persentase mencapai 100.
/// Aman dipanggil ulang dengan skor yang sama.
class RecordPostTestScoreUseCase {
  const RecordPostTestScoreUseCase(
    this._courses,
    this._progress,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final CourseRepository _courses;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  /// Mengembalikan progress terbaru.
  Future<CourseProgress> call({
    required String userId,
    required String courseId,
    required double score,
  }) async {
    final course = await _courses.getCourseById(courseId);
    final materials = await _courses.getPublishedMaterials(courseId);
    final all = await _progress.getUserProgress(userId);
    final weights = await _settings.getProgressWeights();
    final base = all[courseId] ?? CourseProgress(courseId: courseId);
    final now = DateTime.now();

    var updated = base.copyWith(postTestCompleted: true, postTestScore: score);
    final percent = _calculator.percentage(
      progress: updated,
      totalMaterials: materials.length,
      hasGame: course.hasGame,
      weights: weights,
    );
    final reachedEnd = percent >= 100;

    updated = updated.copyWith(
      progressPercentage: percent,
      startedAt: base.startedAt ?? now,
      completedAt: base.completedAt ?? (reachedEnd ? now : null),
    );

    await _progress.savePostTestProgress(
      userId: userId,
      progress: updated,
      setStartedAt: base.startedAt == null,
      setCompletedAt: base.completedAt == null && reachedEnd,
    );

    return updated;
  }
}