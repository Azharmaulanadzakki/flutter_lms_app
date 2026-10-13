import '../../entities/course_detail.dart';
import '../../entities/course_item.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/settings_repository.dart';
import '../progress/progress_calculator.dart';

class GetCourseDetailUseCase {
  const GetCourseDetailUseCase(
    this._courses,
    this._progress,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final CourseRepository _courses;
  final ProgressRepository _progress;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  Future<CourseDetail> call({
    required String userId,
    required String courseId,
  }) async {
    final course = await _courses.getCourseById(courseId);
    final materials = await _courses.getPublishedMaterials(courseId);
    final raw = (await _progress.getUserProgress(userId))[courseId];
    final weights = await _settings.getProgressWeights();

    return CourseDetail(
      item: CourseItem(
        course: course,
        materialCount: materials.length,
        progress: raw == null
            ? null
            : _calculator.withPercentage(
                progress: raw,
                totalMaterials: materials.length,
                hasGame: course.hasGame,
                weights: weights,
              ),
      ),
      materials: materials,
    );
  }
}