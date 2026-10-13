import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/quiz_test.dart';
import '../../domain/entities/test_attempt.dart';

class TestAttemptModel extends TestAttempt {
  const TestAttemptModel({
    required super.id,
    required super.userId,
    required super.courseId,
    required super.testId,
    required super.type,
    required super.status,
    required super.questionIds,
    super.answers,
    super.timeLimitSeconds,
    super.score,
    super.correctCount,
    super.wrongCount,
    super.startedAt,
    super.submittedAt,
    super.completedAt,
  });

  factory TestAttemptModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    DateTime? fallbackStart,
  }) {
    final d = doc.data() ?? <String, dynamic>{};

    final answers = <String, int>{};
    final rawAnswers = d['answers'];
    if (rawAnswers is Map) {
      rawAnswers.forEach((key, value) {
        if (value is num) answers[key.toString()] = value.toInt();
      });
    }

    return TestAttemptModel(
      id: doc.id,
      userId: (d['userId'] as String?) ?? '',
      courseId: (d['courseId'] as String?) ?? '',
      testId: (d['testId'] as String?) ?? '',
      type: testTypeFromValue(d['testType'] as String?),
      status: _parseStatus(d['status'] as String?),
      questionIds:
          (d['questionIds'] as List?)?.whereType<String>().toList() ?? const [],
      answers: answers,
      timeLimitSeconds: (d['timeLimitSeconds'] as num?)?.toInt() ?? 0,
      score: (d['score'] as num?)?.toDouble(),
      correctCount: (d['correctAnswer'] as num?)?.toInt() ?? 0,
      wrongCount: (d['wrongAnswer'] as num?)?.toInt() ?? 0,
      startedAt: (d['startedAt'] as Timestamp?)?.toDate() ?? fallbackStart,
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  static AttemptStatus _parseStatus(String? value) {
    switch (value) {
      case 'submitted':
        return AttemptStatus.submitted;
      case 'graded':
        return AttemptStatus.graded;
      default:
        return AttemptStatus.inProgress;
    }
  }
}