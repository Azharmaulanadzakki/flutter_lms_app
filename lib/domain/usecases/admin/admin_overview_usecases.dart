import '../../../core/errors/failures.dart';
import '../../entities/admin_entities.dart';
import '../../entities/course.dart';
import '../../entities/course_item.dart';
import '../../entities/course_progress.dart';
import '../../entities/progress_overview.dart';
import '../../entities/progress_weights.dart';
import '../../entities/user_entity.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/settings_repository.dart';
import '../progress/progress_calculator.dart';

/// Ringkasan seluruh kelas dalam beberapa query saja (bukan satu per siswa).
/// Persentase progress dihitung dengan bobot terbaru, sama seperti tampilan siswa.
class GetClassOverviewUseCase {
  const GetClassOverviewUseCase(
    this._admin,
    this._courses,
    this._settings, [
    this._calculator = const ProgressCalculator(),
  ]);

  final AdminRepository _admin;
  final CourseRepository _courses;
  final SettingsRepository _settings;
  final ProgressCalculator _calculator;

  Future<ClassOverview> call() async {
    final students = await _admin.getStudents();
    final courses = await _courses.getPublishedCourses();
    final counts = await _courses.getPublishedMaterialCounts();
    final weights = await _settings.getProgressWeights();
    final records = await _admin.getAllProgress();

    final byUser = <String, Map<String, CourseProgress>>{};
    for (final r in records) {
      byUser.putIfAbsent(r.userId, () => {})[r.progress.courseId] = r.progress;
    }

    final summaries = <StudentSummary>[];
    for (final student in students) {
      final mine = byUser[student.uid] ?? const <String, CourseProgress>{};

      final items = [
        for (final c in courses)
          CourseItem(
            course: c,
            materialCount: counts[c.id] ?? 0,
            progress: mine[c.id] == null
                ? null
                : _calculator.withPercentage(
                    progress: mine[c.id]!,
                    totalMaterials: counts[c.id] ?? 0,
                    hasGame: c.hasGame,
                    weights: weights,
                  ),
          ),
      ];

      summaries.add(
        StudentSummary(
          user: student,
          overview: ProgressOverview(items: items, history: const []),
        ),
      );
    }

    return ClassOverview(
      students: summaries,
      courseStats: [for (final c in courses) _statsFor(c, summaries)],
    );
  }

  CourseStats _statsFor(Course course, List<StudentSummary> students) {
    final items = <CourseItem>[];
    for (final s in students) {
      for (final i in s.overview.items) {
        if (i.course.id == course.id) {
          items.add(i);
          break;
        }
      }
    }

    double? average(Iterable<double> values) {
      final list = values.toList();
      if (list.isEmpty) return null;
      return list.reduce((a, b) => a + b) / list.length;
    }

    final deltas = <double>[];
    for (final i in items) {
      final pre = i.progress?.preTestScore;
      final post = i.progress?.postTestScore;
      if (pre != null && post != null) deltas.add(post - pre);
    }

    return CourseStats(
      course: course,
      studentCount: items.length,
      startedCount: items
          .where((i) => i.status != CourseStatus.notStarted)
          .length,
      completedCount: items
          .where((i) => i.status == CourseStatus.completed)
          .length,
      averagePercent: items.isEmpty
          ? 0
          : items.fold<int>(0, (sum, i) => sum + i.percentage) / items.length,
      averagePre: average(
        items.map((i) => i.progress?.preTestScore).whereType<double>(),
      ),
      averagePost: average(
        items.map((i) => i.progress?.postTestScore).whereType<double>(),
      ),
      averageImprovement: average(deltas),
    );
  }
}

class GetStudentUseCase {
  const GetStudentUseCase(this._admin);

  final AdminRepository _admin;

  Future<UserEntity> call(String uid) => _admin.getUser(uid);
}

class GetProgressWeightsUseCase {
  const GetProgressWeightsUseCase(this._settings);

  final SettingsRepository _settings;

  Future<ProgressWeights> call() => _settings.getProgressWeights();
}

class SaveProgressWeightsUseCase {
  const SaveProgressWeightsUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(ProgressWeights weights) async {
    final values = [
      weights.preTest,
      weights.materials,
      weights.game,
      weights.postTest,
    ];

    for (final v in values) {
      if (v.isNaN || v.isInfinite || v < 0) {
        throw const Failure(
          'Bobot harus berupa angka dan tidak boleh negatif.',
        );
      }
    }
    if (values.fold<double>(0, (a, b) => a + b) <= 0) {
      throw const Failure('Total bobot harus lebih dari 0.');
    }

    await _admin.saveProgressWeights(weights);
  }
}
