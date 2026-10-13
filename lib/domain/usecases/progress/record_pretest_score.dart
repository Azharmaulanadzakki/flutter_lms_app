import '../../entities/course_progress.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import 'progress_calculator.dart';

/// Menyimpan skor pre-test ke progress course dan menghitung ulang
/// persentase. Aman dipanggil ulang dengan skor yang sama.
class RecordPreTestScoreUseCase {
  const RecordPreTestScoreUseCase(
    this._courses,
    this._progress,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final CourseRepository _courses;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  Future<void> call({
    required String userId,
    required String courseId,
    required double score,
  }) async {
    final course = await _courses.getCourseById(courseId);
    final materials = await _courses.getPublishedMaterials(courseId);
    final all = await _progress.getUserProgress(userId);
    final weights = await _settings.getProgressWeights();
    final base = all[courseId] ?? CourseProgress(courseId: courseId);

    var updated = base.copyWith(preTestCompleted: true, preTestScore: score);
    final percent = _calculator.percentage(
      progress: updated,
      totalMaterials: materials.length,
      hasGame: course.hasGame,
      weights: weights,
    );
    updated = updated.copyWith(
      progressPercentage: percent,
      startedAt: base.startedAt ?? DateTime.now(),
    );

    await _progress.savePreTestProgress(
      userId: userId,
      progress: updated,
      setStartedAt: base.startedAt == null,
    );
  }
}