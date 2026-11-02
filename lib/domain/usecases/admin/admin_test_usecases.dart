import '../../../core/errors/failures.dart';
import '../../entities/quiz_test.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/question_admin_repository.dart';

/// Data awal untuk form test. ID test selalu `{courseId}-pre` atau
/// `{courseId}-post`, jadi tiap course punya paling banyak satu test per tipe.
class GetTestFormUseCase {
  const GetTestFormUseCase(this._admin);

  final AdminRepository _admin;

  Future<QuizTest> call({
    required String courseId,
    required TestType type,
  }) async {
    final id = '$courseId-${type.value}';

    final existing = await _admin.getTest(id);
    if (existing != null) return existing;

    final course = await _admin.getCourse(courseId);
    return QuizTest(
      id: id,
      courseId: courseId,
      type: type,
      title: '${type.label}: ${course.title}',
      questionCount: 0,
      durationMinutes: 0,
      isActive: false,
    );
  }
}

class SaveTestUseCase {
  const SaveTestUseCase(this._admin, this._questions);

  final AdminRepository _admin;
  final QuestionAdminRepository _questions;

  Future<void> call(QuizTest test) async {
    final title = test.title.trim();
    if (title.isEmpty) throw const Failure('Judul test wajib diisi.');
    if (test.questionCount < 0) {
      throw const Failure('Jumlah soal tidak boleh negatif.');
    }
    if (test.durationMinutes < 0 || test.durationMinutes > 300) {
      throw const Failure('Durasi harus antara 0 dan 300 menit.');
    }

    if (test.isActive && await _questions.countActiveQuestions(test.id) == 0) {
      throw const Failure(
        'Test belum punya soal aktif. Tambahkan atau aktifkan soal dulu '
        'sebelum mengaktifkan test.',
      );
    }

    await _admin.saveTest(QuizTest(
      id: test.id,
      courseId: test.courseId,
      type: test.type,
      title: title,
      questionCount: test.questionCount,
      durationMinutes: test.durationMinutes,
      isActive: test.isActive,
    ));
  }
}

class SetTestActiveUseCase {
  const SetTestActiveUseCase(this._admin, this._questions);

  final AdminRepository _admin;
  final QuestionAdminRepository _questions;

  Future<void> call(String testId, bool active) async {
    if (active && await _questions.countActiveQuestions(testId) == 0) {
      throw const Failure(
        'Test belum punya soal aktif. Tambahkan atau aktifkan soal dulu '
        'sebelum mengaktifkan test.',
      );
    }
    await _admin.setTestActive(testId, active);
  }
}

/// Test hanya bisa dihapus jika sudah tidak punya soal.
class DeleteTestUseCase {
  const DeleteTestUseCase(this._admin);

  final AdminRepository _admin;

  Future<void> call(String testId) async {
    final count = await _admin.countQuestions(testId);
    if (count > 0) {
      throw Failure(
        'Test masih punya $count soal. Hapus soalnya dulu, atau nonaktifkan test saja.',
      );
    }
    await _admin.deleteTest(testId);
  }
}