import 'package:equatable/equatable.dart';

import 'question.dart';
import 'quiz_test.dart';
import 'test_attempt.dart';

/// Test beserta percobaan milik siswa (jika sudah ada).
class TestOverview extends Equatable {
  const TestOverview({required this.test, this.attempt, this.lockMessage});

  final QuizTest test;
  final TestAttempt? attempt;

  /// Terisi jika test belum bisa dibuka (syarat belum terpenuhi).
  final String? lockMessage;

  @override
  List<Object?> get props => [test, attempt, lockMessage];
}

/// Sesi pengerjaan: percobaan dan soal yang akan dikerjakan.
class TestSession extends Equatable {
  const TestSession({required this.attempt, required this.questions});

  final TestAttempt attempt;
  final List<Question> questions;

  @override
  List<Object?> get props => [attempt, questions];
}