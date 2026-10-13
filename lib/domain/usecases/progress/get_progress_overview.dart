import '../../entities/course_item.dart';
import '../../entities/progress_overview.dart';
import '../../entities/quiz_test.dart';
import '../../entities/test_attempt.dart';
import '../../repositories/history_repository.dart';
import '../course/get_course_items.dart';

/// Ringkasan progress semua course + riwayat pembelajaran.
class GetProgressOverviewUseCase {
  const GetProgressOverviewUseCase(this._getCourseItems, this._history);

  final GetCourseItemsUseCase _getCourseItems;
  final HistoryRepository _history;

  Future<ProgressOverview> call(String userId) async {
    final items = await _getCourseItems(userId);
    final attempts = await _history.getGradedAttempts(userId);
    final byCourse = {for (final i in items) i.course.id: i};

    final history = <HistoryEntry>[];

    for (final item in items) {
      final p = item.progress;
      if (p == null) continue;

      final started = p.startedAt;
      if (started != null) {
        history.add(HistoryEntry(
          type: HistoryType.courseStarted,
          courseId: item.course.id,
          courseTitle: item.course.title,
          at: started,
        ));
      }

      final completed = p.completedAt;
      if (completed != null) {
        history.add(HistoryEntry(
          type: HistoryType.courseCompleted,
          courseId: item.course.id,
          courseTitle: item.course.title,
          at: completed,
        ));
      }
    }

    for (final a in attempts) {
      final at = a.completedAt;
      final item = byCourse[a.courseId];
      if (a.status != AttemptStatus.graded || at == null || item == null) {
        continue;
      }
      history.add(HistoryEntry(
        type: a.type == TestType.pre ? HistoryType.preTest : HistoryType.postTest,
        courseId: item.course.id,
        courseTitle: item.course.title,
        at: at,
        score: a.score,
      ));
    }

    // Terbaru di atas. Jika waktunya sama, "course selesai" tampil di atas post-test.
    history.sort((a, b) {
      final byTime = b.at.compareTo(a.at);
      return byTime != 0 ? byTime : b.type.index.compareTo(a.type.index);
    });

    return ProgressOverview(items: items, history: history);
  }
}