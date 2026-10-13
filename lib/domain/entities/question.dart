import 'package:equatable/equatable.dart';

/// Soal untuk siswa. Tidak memuat kunci jawaban.
class Question extends Equatable {
  const Question({
    required this.id,
    required this.testId,
    required this.courseId,
    required this.text,
    required this.options,
    required this.points,
    required this.order,
  });

  final String id;
  final String testId;
  final String courseId;
  final String text;
  final List<String> options;
  final int points;
  final int order;

  @override
  List<Object?> get props =>
      [id, testId, courseId, text, options, points, order];
}

/// Kunci jawaban. Hanya terbaca setelah siswa mengirim jawaban.
class QuestionKey extends Equatable {
  const QuestionKey({
    required this.questionId,
    required this.correctIndex,
    required this.explanation,
  });

  final String questionId;
  final int correctIndex;
  final String explanation;

  @override
  List<Object?> get props => [questionId, correctIndex, explanation];
}