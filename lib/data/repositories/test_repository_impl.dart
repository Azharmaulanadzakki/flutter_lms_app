import '../../core/constants/firestore_paths.dart';
import '../../core/errors/failure_guard.dart';
import '../../domain/entities/question.dart';
import '../../domain/entities/quiz_test.dart';
import '../../domain/entities/test_attempt.dart';
import '../../domain/repositories/test_repository.dart';
import '../datasources/test_remote_datasource.dart';

class TestRepositoryImpl implements TestRepository {
  TestRepositoryImpl(this._remote);

  final TestRemoteDataSource _remote;

  @override
  Future<QuizTest?> getActiveTest({
    required String courseId,
    required TestType type,
  }) =>
      guardFirebase<QuizTest?>(
        () => _remote.getActiveTest(courseId, type.value),
      );

  @override
  Future<TestAttempt?> getAttempt({
    required String userId,
    required String testId,
  }) =>
      guardFirebase<TestAttempt?>(
        () => _remote.getAttempt(FirestorePaths.attemptId(userId, testId)),
      );

  @override
  Future<List<Question>> getActiveQuestions(String testId) =>
      guardFirebase<List<Question>>(() => _remote.getActiveQuestions(testId));

  @override
  Future<TestAttempt> createAttempt({
    required String userId,
    required QuizTest test,
    required List<String> questionIds,
  }) =>
      guardFirebase<TestAttempt>(
        () => _remote.createAttempt(
          attemptId: FirestorePaths.attemptId(userId, test.id),
          userId: userId,
          courseId: test.courseId,
          testId: test.id,
          type: test.type.value,
          questionIds: questionIds,
          timeLimitSeconds: test.durationMinutes * 60,
        ),
      );

  @override
  Future<void> submitAnswers({
    required TestAttempt attempt,
    required Map<String, int> answers,
  }) =>
      guardFirebase(() => _remote.submitAnswers(attempt.id, answers));

  @override
  Future<Map<String, QuestionKey>> getKeys(List<String> questionIds) =>
      guardFirebase<Map<String, QuestionKey>>(
        () => _remote.getKeys(questionIds),
      );

  @override
  Future<void> saveGrade({
    required TestAttempt attempt,
    required double score,
    required int correct,
    required int wrong,
  }) =>
      guardFirebase(
        () => _remote.saveGrade(
          attemptId: attempt.id,
          score: score,
          correct: correct,
          wrong: wrong,
        ),
      );
}