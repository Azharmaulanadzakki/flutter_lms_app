import '../../core/errors/failure_guard.dart';
import '../../domain/entities/admin_question.dart';
import '../../domain/entities/quiz_test.dart';
import '../../domain/repositories/question_admin_repository.dart';
import '../datasources/question_admin_remote_datasource.dart';

class QuestionAdminRepositoryImpl implements QuestionAdminRepository {
  QuestionAdminRepositoryImpl(this._remote);

  final QuestionAdminRemoteDataSource _remote;

  @override
  Future<List<QuizTest>> getAllTests() =>
      guardFirebase<List<QuizTest>>(_remote.getAllTests);

  @override
  Future<QuizTest?> getTest(String testId) =>
      guardFirebase<QuizTest?>(() => _remote.getTest(testId));

  @override
  Future<Map<String, QuestionCount>> getQuestionCounts() =>
      guardFirebase<Map<String, QuestionCount>>(_remote.getQuestionCounts);

  @override
  Future<int> countActiveQuestions(String testId) =>
      guardFirebase<int>(() => _remote.countActiveQuestions(testId));

  @override
  Future<int> countAttempts(String testId) =>
      guardFirebase<int>(() => _remote.countAttempts(testId));

  @override
  Future<List<AdminQuestion>> getQuestions(String testId) =>
      guardFirebase<List<AdminQuestion>>(() => _remote.getQuestions(testId));

  @override
  Future<AdminQuestion> getQuestion(String questionId) =>
      guardFirebase<AdminQuestion>(() => _remote.getQuestion(questionId));

  @override
  Future<String> saveQuestion(AdminQuestion question) =>
      guardFirebase<String>(() => _remote.saveQuestion(question));

  @override
  Future<void> setActive(String questionId, bool active) =>
      guardFirebase<void>(() => _remote.setActive(questionId, active));

  @override
  Future<void> deleteQuestion(String questionId) =>
      guardFirebase<void>(() => _remote.deleteQuestion(questionId));

  @override
  Future<void> reorder(List<String> orderedIds) =>
      guardFirebase<void>(() => _remote.reorder(orderedIds));
}
