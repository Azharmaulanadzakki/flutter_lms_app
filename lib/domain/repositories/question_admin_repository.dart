import '../entities/admin_question.dart';
import '../entities/quiz_test.dart';

abstract class QuestionAdminRepository {
  Future<List<QuizTest>> getAllTests();
  Future<QuizTest?> getTest(String testId);

  /// testId -> jumlah soal (semua dan aktif).
  Future<Map<String, QuestionCount>> getQuestionCounts();

  Future<int> countActiveQuestions(String testId);

  /// Jumlah percobaan siswa pada test.
  Future<int> countAttempts(String testId);

  /// Semua soal test (aktif dan nonaktif) lengkap dengan kuncinya, terurut.
  Future<List<AdminQuestion>> getQuestions(String testId);
  Future<AdminQuestion> getQuestion(String questionId);

  /// Soal dan kunci ditulis dalam satu batch. Mengembalikan ID soal.
  /// Jika `question.id` kosong, soal baru dibuat.
  Future<String> saveQuestion(AdminQuestion question);

  Future<void> setActive(String questionId, bool active);

  /// Menghapus soal beserta kunci jawabannya.
  Future<void> deleteQuestion(String questionId);

  /// Menyimpan urutan baru: indeks 0 menjadi urutan 1, dan seterusnya.
  Future<void> reorder(List<String> orderedIds);
}
