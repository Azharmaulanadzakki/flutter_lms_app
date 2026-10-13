import 'package:equatable/equatable.dart';

import 'quiz_test.dart';

enum AttemptStatus { inProgress, submitted, graded }

class TestAttempt extends Equatable {
  const TestAttempt({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.testId,
    required this.type,
    required this.status,
    required this.questionIds,
    this.answers = const {},
    this.timeLimitSeconds = 0,
    this.score,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.startedAt,
    this.submittedAt,
    this.completedAt,
  });

  final String id;
  final String userId;
  final String courseId;
  final String testId;
  final TestType type;
  final AttemptStatus status;

  /// Soal yang terpilih, sesuai urutan acak.
  final List<String> questionIds;

  /// questionId -> indeks pilihan yang dipilih.
  final Map<String, int> answers;

  /// 0 = tanpa batas waktu.
  final int timeLimitSeconds;
  final double? score;
  final int correctCount;
  final int wrongCount;
  final DateTime? startedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;

  bool get hasTimer => timeLimitSeconds > 0;

  /// Batas akhir pengerjaan, atau null jika tanpa timer.
  DateTime? get deadline {
    final start = startedAt;
    if (!hasTimer || start == null) return null;
    return start.add(Duration(seconds: timeLimitSeconds));
  }

  TestAttempt copyWith({
    AttemptStatus? status,
    Map<String, int>? answers,
    double? score,
    int? correctCount,
    int? wrongCount,
    DateTime? completedAt,
  }) {
    return TestAttempt(
      id: id,
      userId: userId,
      courseId: courseId,
      testId: testId,
      type: type,
      status: status ?? this.status,
      questionIds: questionIds,
      answers: answers ?? this.answers,
      timeLimitSeconds: timeLimitSeconds,
      score: score ?? this.score,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      startedAt: startedAt,
      submittedAt: submittedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        courseId,
        testId,
        type,
        status,
        questionIds,
        answers,
        timeLimitSeconds,
        score,
        correctCount,
        wrongCount,
        startedAt,
        submittedAt,
        completedAt,
      ];
}