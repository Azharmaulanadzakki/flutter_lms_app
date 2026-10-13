import '../../entities/course_progress.dart';
import '../../entities/progress_weights.dart';

class ProgressCalculator {
  const ProgressCalculator();

  /// Hasil 0 sampai 100. Bobot game dibuang jika course tidak punya game,
  /// bobot materi dibuang jika tidak ada materi, lalu sisanya dinormalkan.
  double percentage({
    required CourseProgress progress,
    required int totalMaterials,
    required bool hasGame,
    ProgressWeights weights = ProgressWeights.defaults,
  }) {
    final wMaterials = totalMaterials > 0 ? weights.materials : 0.0;
    final wGame = hasGame ? weights.game : 0.0;
    final total = weights.preTest + wMaterials + wGame + weights.postTest;
    if (total <= 0) return 0;

    var earned = 0.0;
    if (progress.preTestCompleted) earned += weights.preTest;
    if (totalMaterials > 0) {
      final ratio =
          (progress.materialProgress / totalMaterials).clamp(0.0, 1.0).toDouble();
      earned += wMaterials * ratio;
    }
    if (hasGame && progress.gameCompleted) earned += wGame;
    if (progress.postTestCompleted) earned += weights.postTest;

    return (earned / total * 100).clamp(0.0, 100.0).toDouble();
  }

  /// Salinan [progress] dengan persentase dihitung ulang memakai [weights].
  /// Dipakai saat membaca data, supaya perubahan bobot langsung berlaku.
  CourseProgress withPercentage({
    required CourseProgress progress,
    required int totalMaterials,
    required bool hasGame,
    ProgressWeights weights = ProgressWeights.defaults,
  }) {
    return progress.copyWith(
      progressPercentage: percentage(
        progress: progress,
        totalMaterials: totalMaterials,
        hasGame: hasGame,
        weights: weights,
      ),
    );
  }
}