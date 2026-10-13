import 'package:equatable/equatable.dart';

import 'course_item.dart';

class DashboardData extends Equatable {
  const DashboardData({required this.items});

  /// Sudah terurut berdasarkan `order` course.
  final List<CourseItem> items;

  double get overallProgress {
    if (items.isEmpty) return 0;
    final total = items.fold<int>(0, (sum, i) => sum + i.percentage);
    return total / items.length;
  }

  int get completedCount =>
      items.where((i) => i.status == CourseStatus.completed).length;

  int get inProgressCount =>
      items.where((i) => i.status == CourseStatus.inProgress).length;

  /// Course yang sedang berjalan (terbaru). Jika tidak ada,
  /// course pertama yang belum dimulai.
  CourseItem? get continueCourse {
    final running =
        items.where((i) => i.status == CourseStatus.inProgress).toList();
    if (running.isNotEmpty) {
      running.sort((a, b) => _stamp(b).compareTo(_stamp(a)));
      return running.first;
    }
    for (final i in items) {
      if (i.status == CourseStatus.notStarted) return i;
    }
    return null;
  }

  List<CourseItem> get recommended {
    final current = continueCourse;
    return items
        .where((i) =>
            i.status == CourseStatus.notStarted &&
            i.course.id != current?.course.id)
        .take(3)
        .toList();
  }

  /// Nilai post-test terbaru, atau null jika belum ada.
  double? get latestScore {
    final scored =
        items.where((i) => i.progress?.postTestScore != null).toList();
    if (scored.isEmpty) return null;
    scored.sort((a, b) => _stamp(b).compareTo(_stamp(a)));
    return scored.first.progress!.postTestScore;
  }

  static DateTime _stamp(CourseItem i) =>
      i.progress?.completedAt ??
      i.progress?.startedAt ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  List<Object?> get props => [items];
}