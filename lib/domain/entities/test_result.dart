import 'package:equatable/equatable.dart';

import 'question.dart';
import 'test_attempt.dart';

/// Satu soal beserta jawaban siswa dan kuncinya, untuk review.
class GradedQuestion extends Equatable {
  const GradedQuestion({
    required this.question,
    required this.selectedIndex,
    required this.correctIndex,
    required this.explanation,
  });

  final Question question;

  /// null jika tidak dijawab.
  final int? selectedIndex;
  final int correctIndex;
  final String explanation;

  bool get isAnswered => selectedIndex != null;
  bool get isCorrect => selectedIndex == correctIndex;

  @override
  List<Object?> get props =>
      [question, selectedIndex, correctIndex, explanation];
}

class TestResult extends Equatable {
  const TestResult({
    required this.attempt,
    required this.items,
    this.preTestScore,
    this.courseCompleted = false,
  });

  final TestAttempt attempt;
  final List<GradedQuestion> items;

  /// Hanya untuk post-test: nilai pre-test course yang sama.
  final double? preTestScore;

  /// Hanya untuk post-test: true jika course kini selesai.
  final bool courseCompleted;

  double get score => attempt.score ?? 0;
  int get correctCount => attempt.correctCount;
  int get wrongCount => attempt.wrongCount;

  @override
  List<Object?> get props => [attempt, items, preTestScore, courseCompleted];
}