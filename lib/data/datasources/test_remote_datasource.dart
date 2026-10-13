import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/question_model.dart';
import '../models/quiz_test_model.dart';
import '../models/test_attempt_model.dart';

abstract class TestRemoteDataSource {
  Future<QuizTestModel?> getActiveTest(String courseId, String type);
  Future<TestAttemptModel?> getAttempt(String attemptId);
  Future<List<QuestionModel>> getActiveQuestions(String testId);

  Future<TestAttemptModel> createAttempt({
    required String attemptId,
    required String userId,
    required String courseId,
    required String testId,
    required String type,
    required List<String> questionIds,
    required int timeLimitSeconds,
  });

  Future<void> submitAnswers(String attemptId, Map<String, int> answers);
  Future<Map<String, QuestionKeyModel>> getKeys(List<String> questionIds);

  Future<void> saveGrade({
    required String attemptId,
    required double score,
    required int correct,
    required int wrong,
  });
}

class TestRemoteDataSourceImpl implements TestRemoteDataSource {
  TestRemoteDataSourceImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<QuizTestModel?> getActiveTest(String courseId, String type) async {
    final snap = await _db
        .collection(FirestorePaths.tests)
        .where('courseId', isEqualTo: courseId)
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return QuizTestModel.fromFirestore(snap.docs.first);
  }

  @override
  Future<TestAttemptModel?> getAttempt(String attemptId) async {
    final snap =
        await _db.collection(FirestorePaths.testAttempts).doc(attemptId).get();
    if (!snap.exists) return null;
    return TestAttemptModel.fromFirestore(snap);
  }

  @override
  Future<List<QuestionModel>> getActiveQuestions(String testId) async {
    final snap = await _db
        .collection(FirestorePaths.questions)
        .where('testId', isEqualTo: testId)
        .where('isActive', isEqualTo: true)
        .get();

    // Diurutkan di sisi aplikasi supaya tidak butuh composite index.
    final list = snap.docs.map(QuestionModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  @override
  Future<TestAttemptModel> createAttempt({
    required String attemptId,
    required String userId,
    required String courseId,
    required String testId,
    required String type,
    required List<String> questionIds,
    required int timeLimitSeconds,
  }) async {
    final ref = _db.collection(FirestorePaths.testAttempts).doc(attemptId);

    await ref.set({
      'userId': userId,
      'courseId': courseId,
      'testId': testId,
      'testType': type,
      'questionIds': questionIds,
      'status': 'in_progress',
      'timeLimitSeconds': timeLimitSeconds,
      'startedAt': FieldValue.serverTimestamp(),
    });

    // Baca ulang dari server supaya startedAt berisi waktu server yang asli.
    final snap = await ref.get(const GetOptions(source: Source.server));
    return TestAttemptModel.fromFirestore(snap, fallbackStart: DateTime.now());
  }

  @override
  Future<void> submitAnswers(String attemptId, Map<String, int> answers) {
    return _db.collection(FirestorePaths.testAttempts).doc(attemptId).update({
      'status': 'submitted',
      'answers': answers,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, QuestionKeyModel>> getKeys(
    List<String> questionIds,
  ) async {
    final snaps = await Future.wait(
      questionIds.map(
        (id) => _db.collection(FirestorePaths.questionKeys).doc(id).get(),
      ),
    );

    final result = <String, QuestionKeyModel>{};
    for (final snap in snaps) {
      if (snap.exists) result[snap.id] = QuestionKeyModel.fromFirestore(snap);
    }
    return result;
  }

  @override
  Future<void> saveGrade({
    required String attemptId,
    required double score,
    required int correct,
    required int wrong,
  }) {
    return _db.collection(FirestorePaths.testAttempts).doc(attemptId).update({
      'status': 'graded',
      'score': score,
      'correctAnswer': correct,
      'wrongAnswer': wrong,
      'completedAt': FieldValue.serverTimestamp(),
    });
  }
}