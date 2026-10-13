import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/quiz_test.dart';

class QuizTestModel extends QuizTest {
  const QuizTestModel({
    required super.id,
    required super.courseId,
    required super.type,
    required super.title,
    required super.questionCount,
    required super.durationMinutes,
  });

  factory QuizTestModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return QuizTestModel(
      id: doc.id,
      courseId: (d['courseId'] as String?) ?? '',
      type: testTypeFromValue(d['type'] as String?),
      title: (d['title'] as String?) ?? '',
      questionCount: (d['questionCount'] as num?)?.toInt() ?? 0,
      durationMinutes: (d['durationMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}