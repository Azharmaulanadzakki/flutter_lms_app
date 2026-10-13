import '../../entities/course_item.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../progress/progress_calculator.dart';

/// Semua course + jumlah materi + progress siswa.
/// Persentase progress dihitung ulang dengan bobot terbaru.
/// Dipakai oleh dashboard, daftar course, dan halaman progress.
class GetCourseItemsUseCase {
  const GetCourseItemsUseCase(
    this._courses,
    this._progress,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final CourseRepository _courses;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  Future<List<CourseItem>> call(String userId) async {
    final courses = await _courses.getPublishedCourses();
    final counts = await _courses.getPublishedMaterialCounts();
    final progress = await _progress.getUserProgress(userId);
    final weights = await _settings.getProgressWeights();

    return [
      for (final c in courses)
        CourseItem(
          course: c,
          materialCount: counts[c.id] ?? 0,
          progress: progress[c.id] == null
              ? null
              : _calculator.withPercentage(
                  progress: progress[c.id]!,
                  totalMaterials: counts[c.id] ?? 0,
                  hasGame: c.hasGame,
                  weights: weights,
                ),
        ),
    ];
  }
}