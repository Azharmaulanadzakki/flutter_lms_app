import 'package:equatable/equatable.dart';

import 'course_item.dart';

enum HistoryType { courseStarted, preTest, postTest, courseCompleted }

/// Satu baris riwayat pembelajaran.
class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.type,
    required this.courseId,
    required this.courseTitle,
    required this.at,
    this.score,
  });

  final HistoryType type;
  final String courseId;
  final String courseTitle;
  final DateTime at;

  /// Nilai, untuk pre-test dan post-test.
  final double? score;

  @override
  List<Object?> get props => [type, courseId, courseTitle, at, score];
}

/// Ringkasan progress seluruh course beserta riwayatnya.
class ProgressOverview extends Equatable {
  const ProgressOverview({required this.items, required this.history});

  final List<CourseItem> items;

  /// Terbaru di atas.
  final List<HistoryEntry> history;

  double get overallPercent {
    if (items.isEmpty) return 0;
    final total = items.fold<int>(0, (sum, i) => sum + i.percentage);
    return total / items.length;
  }

  int get completedCount =>
      items.where((i) => i.status == CourseStatus.completed).length;

  double? get averagePre =>
      _average([for (final i in items) i.progress?.preTestScore]);

  double? get averagePost =>
      _average([for (final i in items) i.progress?.postTestScore]);

  /// Rata-rata (post-test - pre-test) pada course yang punya keduanya.
  double? get averageImprovement {
    final deltas = <double>[];
    for (final i in items) {
      final pre = i.progress?.preTestScore;
      final post = i.progress?.postTestScore;
      if (pre != null && post != null) deltas.add(post - pre);
    }
    return _average(deltas);
  }

  static double? _average(Iterable<double?> values) {
    final list = values.whereType<double>().toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  List<Object?> get props => [items, history];
}
