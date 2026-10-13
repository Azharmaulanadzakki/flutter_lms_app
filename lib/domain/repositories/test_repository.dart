import '../entities/question.dart';
import '../entities/quiz_test.dart';
import '../entities/test_attempt.dart';

abstract class TestRepository {
  /// Test aktif untuk course, atau null jika belum ada.
  Future<QuizTest?> getActiveTest({
    required String courseId,
    required TestType type,
  });

  /// Percobaan siswa pada test, atau null jika belum pernah.
  Future<TestAttempt?> getAttempt({
    required String userId,
    required String testId,
  });

  /// Soal aktif milik test, terurut berdasarkan `order`.
  Future<List<Question>> getActiveQuestions(String testId);

  Future<TestAttempt> createAttempt({
    required String userId,
    required QuizTest test,
    required List<String> questionIds,
  });

  Future<void> submitAnswers({
    required TestAttempt attempt,
    required Map<String, int> answers,
  });

  /// Kunci jawaban. Hanya berhasil setelah jawaban dikirim.
  Future<Map<String, QuestionKey>> getKeys(List<String> questionIds);

  Future<void> saveGrade({
    required TestAttempt attempt,
    required double score,
    required int correct,
    required int wrong,
  });
}