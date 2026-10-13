import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/question.dart';

class QuestionModel extends Question {
  const QuestionModel({
    required super.id,
    required super.testId,
    required super.courseId,
    required super.text,
    required super.options,
    required super.points,
    required super.order,
  });

  factory QuestionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    final points = (d['points'] as num?)?.toInt() ?? 1;
    return QuestionModel(
      id: doc.id,
      testId: (d['testId'] as String?) ?? '',
      courseId: (d['courseId'] as String?) ?? '',
      text: (d['question'] as String?) ?? '',
      options:
          (d['options'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      points: points < 1 ? 1 : points,
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class QuestionKeyModel extends QuestionKey {
  const QuestionKeyModel({
    required super.questionId,
    required super.correctIndex,
    required super.explanation,
  });

  factory QuestionKeyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return QuestionKeyModel(
      questionId: doc.id,
      correctIndex: (d['correctIndex'] as num?)?.toInt() ?? -1,
      explanation: (d['explanation'] as String?) ?? '',
    );
  }
}