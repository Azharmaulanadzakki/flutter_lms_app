import 'package:equatable/equatable.dart';
import 'course.dart';
import 'course_progress.dart';

enum CourseStatus { notStarted, inProgress, completed }

/// Syarat yang belum terpenuhi untuk membuka post-test.
enum PostTestLock { none, preTest, materials, game }

extension PostTestLockX on PostTestLock {
  String get message {
    switch (this) {
      case PostTestLock.none:
        return '';
      case PostTestLock.preTest:
        return 'Kerjakan pre-test dulu';
      case PostTestLock.materials:
        return 'Selesaikan semua materi dulu';
      case PostTestLock.game:
        return 'Selesaikan simulasi 3D dulu';
    }
  }
}

/// Gabungan course + jumlah materi + progress siswa.
class CourseItem extends Equatable {
  const CourseItem({
    required this.course,
    required this.materialCount,
    this.progress,
  });

  final Course course;
  final int materialCount;
  final CourseProgress? progress;

  int get percentage =>
      (progress?.progressPercentage ?? 0).clamp(0, 100).round();

  int get materialsDone => progress?.materialProgress ?? 0;

  CourseStatus get status {
    final p = progress;
    if (p == null) return CourseStatus.notStarted;
    if (p.isCompleted) return CourseStatus.completed;
    if (p.isStarted) return CourseStatus.inProgress;
    return CourseStatus.notStarted;
  }

  /// Syarat pertama yang belum terpenuhi, atau = PostTestLock.none jika semua terpenuhi.
  PostTestLock get postTestLock {
    final p = progress;
    if (!(p?.preTestCompleted ?? false)) return PostTestLock.preTest;

    final allMaterialsDone =
        materialCount == 0 || materialsDone >= materialCount;
    if (!allMaterialsDone) return PostTestLock.materials;

    if (course.hasGame && !(p?.gameCompleted ?? false)) {
      return PostTestLock.game;
    }
    return PostTestLock.none;
  }

  @override
  List<Object?> get props => [course, materialCount, progress];
}