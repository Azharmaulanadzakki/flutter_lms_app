import 'package:equatable/equatable.dart';

enum TestType { pre, post }

extension TestTypeX on TestType {
  String get value => this == TestType.pre ? 'pre' : 'post';
  String get label => this == TestType.pre ? 'Pre-Test' : 'Post-Test';
}

TestType testTypeFromValue(String? value) =>
    value == 'post' ? TestType.post : TestType.pre;

class QuizTest extends Equatable {
  const QuizTest({
    required this.id,
    required this.courseId,
    required this.type,
    required this.title,
    required this.questionCount,
    required this.durationMinutes,
    this.isActive = true,
  });

  final String id;
  final String courseId;
  final TestType type;
  final String title;

  /// Jumlah soal yang diambil acak. 0 = semua soal.
  final int questionCount;

  /// Batas waktu dalam menit. 0 = tanpa batas waktu.
  final int durationMinutes;
  final bool isActive;

  bool get hasTimer => durationMinutes > 0;

  @override
  List<Object?> get props =>
      [id, courseId, type, title, questionCount, durationMinutes, isActive];
}