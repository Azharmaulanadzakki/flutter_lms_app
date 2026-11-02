import 'package:equatable/equatable.dart';

import 'course.dart';
import 'course_item.dart';
import 'course_material.dart';
import 'course_progress.dart';
import 'progress_overview.dart';
import 'quiz_test.dart';
import 'user_entity.dart';

/// Progress satu siswa pada satu course (untuk admin).
class StudentProgressRecord extends Equatable {
  const StudentProgressRecord({required this.userId, required this.progress});

  final String userId;
  final CourseProgress progress;

  @override
  List<Object?> get props => [userId, progress];
}

/// Satu baris pada daftar course admin.
class AdminCourseRow extends Equatable {
  const AdminCourseRow({
    required this.course,
    required this.materialCount,
    required this.publishedMaterialCount,
  });

  final Course course;
  final int materialCount;
  final int publishedMaterialCount;

  @override
  List<Object?> get props => [course, materialCount, publishedMaterialCount];
}

class AdminTestInfo extends Equatable {
  const AdminTestInfo({required this.test, required this.questionCount});

  final QuizTest test;

  /// Jumlah soal di bank soal test ini (aktif maupun tidak).
  final int questionCount;

  @override
  List<Object?> get props => [test, questionCount];
}

class AdminCourseDetail extends Equatable {
  const AdminCourseDetail({
    required this.course,
    required this.materials,
    required this.tests,
  });

  final Course course;
  final List<CourseMaterial> materials;
  final List<AdminTestInfo> tests;

  AdminTestInfo? testOf(TestType type) {
    for (final t in tests) {
      if (t.test.type == type) return t;
    }
    return null;
  }

  @override
  List<Object?> get props => [course, materials, tests];
}

class StudentSummary extends Equatable {
  const StudentSummary({required this.user, required this.overview});

  final UserEntity user;
  final ProgressOverview overview;

  @override
  List<Object?> get props => [user, overview];
}

/// Statistik satu course untuk seluruh siswa.
class CourseStats extends Equatable {
  const CourseStats({
    required this.course,
    required this.studentCount,
    required this.startedCount,
    required this.completedCount,
    required this.averagePercent,
    this.averagePre,
    this.averagePost,
    this.averageImprovement,
  });

  final Course course;
  final int studentCount;
  final int startedCount;
  final int completedCount;
  final double averagePercent;
  final double? averagePre;
  final double? averagePost;
  final double? averageImprovement;

  @override
  List<Object?> get props => [
        course,
        studentCount,
        startedCount,
        completedCount,
        averagePercent,
        averagePre,
        averagePost,
        averageImprovement,
      ];
}

/// Ringkasan seluruh kelas: dipakai Dashboard, tab Siswa, dan tab Progress.
class ClassOverview extends Equatable {
  const ClassOverview({required this.students, required this.courseStats});

  final List<StudentSummary> students;
  final List<CourseStats> courseStats;

  int get studentCount => students.length;
  int get activeCourseCount => courseStats.length;

  double get averagePercent {
    if (students.isEmpty) return 0;
    final total =
        students.fold<double>(0, (sum, s) => sum + s.overview.overallPercent);
    return total / students.length;
  }

  int get completedCourses =>
      students.fold<int>(0, (sum, s) => sum + s.overview.completedCount);

  double? get averagePre => _avg([
        for (final s in students)
          for (final i in s.overview.items) i.progress?.preTestScore,
      ]);

  double? get averagePost => _avg([
        for (final s in students)
          for (final i in s.overview.items) i.progress?.postTestScore,
      ]);

  double? get averageImprovement {
    final deltas = <double>[];
    for (final s in students) {
      for (final CourseItem i in s.overview.items) {
        final pre = i.progress?.preTestScore;
        final post = i.progress?.postTestScore;
        if (pre != null && post != null) deltas.add(post - pre);
      }
    }
    return _avg(deltas);
  }

  /// Lima siswa yang terakhir masuk.
  List<StudentSummary> get recentlyActive {
    final list = students.where((s) => s.user.lastLogin != null).toList()
      ..sort((a, b) => b.user.lastLogin!.compareTo(a.user.lastLogin!));
    return list.take(5).toList();
  }

  static double? _avg(Iterable<double?> values) {
    final list = values.whereType<double>().toList();
    if (list.isEmpty) return null;
    return list.reduce((a, b) => a + b) / list.length;
  }

  @override
  List<Object?> get props => [students, courseStats];
}