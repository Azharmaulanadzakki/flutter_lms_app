import '../../entities/course.dart';
import '../../entities/course_material.dart';
import '../../entities/course_progress.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import 'progress_calculator.dart';

class MarkMaterialCompletedUseCase {
  const MarkMaterialCompletedUseCase(
    this._repository,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final ProgressRepository _repository;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  /// Menandai satu materi selesai, menghitung ulang persentase,
  /// lalu menyimpannya. Mengembalikan progress terbaru.
  Future<CourseProgress> call({
    required String userId,
    required Course course,
    required List<CourseMaterial> materials,
    required String materialId,
    CourseProgress? current,
  }) async {
    final weights = await _settings.getProgressWeights();
    final now = DateTime.now();
    final base = current ?? CourseProgress(courseId: course.id);
    final publishedIds = materials.map((m) => m.id).toSet();

    // Hanya hitung materi yang masih published.
    final done = <String>{
      ...base.completedMaterialIds.where(publishedIds.contains),
      if (publishedIds.contains(materialId)) materialId,
    };

    var updated = base.copyWith(
      completedMaterialIds: done.toList(),
      materialProgress: done.length,
    );

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

    await _repository.saveMaterialProgress(
      userId: userId,
      progress: updated,
      setStartedAt: base.startedAt == null,
      setCompletedAt: base.completedAt == null && reachedEnd,
    );

    return updated;
  }
}