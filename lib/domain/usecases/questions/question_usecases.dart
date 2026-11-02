import 'dart:math';

import '../../../core/errors/failures.dart';
import '../../entities/admin_question.dart';
import '../../repositories/admin_repository.dart';
import '../../repositories/question_admin_repository.dart';

/// Mencegah test yang sedang aktif kehilangan soal aktif terakhirnya.
Future<void> _guardLastActive(
  QuestionAdminRepository repo, {
  required String testId,
  required String questionId,
}) async {
  final test = await repo.getTest(testId);
  if (test == null || !test.isActive) return;

  final questions = await repo.getQuestions(testId);
  final othersActive = questions
      .where((q) => q.id != questionId && q.isActive)
      .length;

  if (othersActive == 0) {
    throw const Failure(
      'Test ini sedang aktif dan soal ini adalah satu-satunya soal aktif. '
      'Nonaktifkan test dulu, atau tambahkan soal aktif lain.',
    );
  }
}

class GetQuestionOverviewUseCase {
  const GetQuestionOverviewUseCase(this._admin, this._questions);

  final AdminRepository _admin;
  final QuestionAdminRepository _questions;

  Future<QuestionOverview> call() async {
    final courses = await _admin.getAllCourses();
    final tests = await _questions.getAllTests();
    final counts = await _questions.getQuestionCounts();

    final byCourse = <String, List<TestQuestionSummary>>{};
    for (final t in tests) {
      byCourse
          .putIfAbsent(t.courseId, () => <TestQuestionSummary>[])
          .add(
            TestQuestionSummary(
              test: t,
              count: counts[t.id] ?? const QuestionCount(),
            ),
          );
    }

    final groups = <CourseQuestionGroup>[];
    for (final c in courses) {
      final list = (byCourse[c.id] ?? <TestQuestionSummary>[]).toList()
        ..sort((a, b) => a.test.type.index.compareTo(b.test.type.index));
      groups.add(CourseQuestionGroup(course: c, tests: list));
    }

    return QuestionOverview(groups: groups);
  }
}

class GetQuestionListUseCase {
  const GetQuestionListUseCase(this._admin, this._questions);

  final AdminRepository _admin;
  final QuestionAdminRepository _questions;

  Future<QuestionListData> call(String testId) async {
    final test = await _questions.getTest(testId);
    if (test == null) throw const Failure('Test tidak ditemukan.');

    final questions = await _questions.getQuestions(testId);
    final attempts = await _questions.countAttempts(testId);

    var courseTitle = '';
    try {
      courseTitle = (await _admin.getCourse(test.courseId)).title;
    } catch (_) {
      // Judul course hanya pelengkap tampilan.
    }

    return QuestionListData(
      test: test,
      courseTitle: courseTitle,
      questions: questions,
      attemptCount: attempts,
    );
  }
}

/// Data awal form: soal yang diedit, atau soal kosong (urutan otomatis,
/// belum punya kunci) jika [questionId] null.
class GetQuestionFormUseCase {
  const GetQuestionFormUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<AdminQuestion> call({
    required String testId,
    String? questionId,
  }) async {
    if (questionId != null) {
      final q = await _repo.getQuestion(questionId);
      if (q.testId != testId) {
        throw const Failure('Soal ini bukan milik test tersebut.');
      }
      return q;
    }

    final test = await _repo.getTest(testId);
    if (test == null) throw const Failure('Test tidak ditemukan.');

    final all = await _repo.getQuestions(testId);
    final nextOrder = all.isEmpty ? 1 : all.map((q) => q.order).reduce(max) + 1;

    return AdminQuestion(
      id: '',
      testId: testId,
      courseId: test.courseId,
      text: '',
      options: const ['', '', '', ''],
      correctIndex: -1,
      explanation: '',
      points: 1,
      order: nextOrder,
      isActive: true,
    );
  }
}

class SaveQuestionUseCase {
  const SaveQuestionUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<String> call(AdminQuestion q) async {
    final text = q.text.trim();
    if (text.isEmpty) throw const Failure('Pertanyaan wajib diisi.');
    if (text.length > 1000) {
      throw const Failure(
        'Pertanyaan terlalu panjang (maksimal 1000 karakter).',
      );
    }

    final options = [for (final o in q.options) o.trim()];
    if (options.length != 4) {
      throw const Failure('Soal harus punya empat pilihan (A sampai D).');
    }
    for (var i = 0; i < options.length; i++) {
      if (options[i].isEmpty) {
        throw Failure('Pilihan ${optionLetter(i)} wajib diisi.');
      }
      if (options[i].length > 300) {
        throw Failure(
          'Pilihan ${optionLetter(i)} terlalu panjang (maksimal 300 karakter).',
        );
      }
    }
    if (options.map((o) => o.toLowerCase()).toSet().length != options.length) {
      throw const Failure(
        'Ada pilihan yang sama. Setiap pilihan harus berbeda.',
      );
    }

    if (q.correctIndex < 0 || q.correctIndex >= options.length) {
      throw const Failure('Pilih jawaban yang benar.');
    }

    final explanation = q.explanation.trim();
    if (explanation.length > 2000) {
      throw const Failure(
        'Pembahasan terlalu panjang (maksimal 2000 karakter).',
      );
    }
    if (q.points < 1 || q.points > 100) {
      throw const Failure('Poin harus antara 1 dan 100.');
    }

    // Menonaktifkan soal aktif lewat form harus tunduk pada aturan yang sama
    // dengan tombol Nonaktifkan.
    if (!q.isNew && !q.isActive) {
      final existing = await _repo.getQuestion(q.id);
      if (existing.isActive) {
        await _guardLastActive(_repo, testId: q.testId, questionId: q.id);
      }
    }

    return _repo.saveQuestion(
      AdminQuestion(
        id: q.id,
        testId: q.testId,
        courseId: q.courseId,
        text: text,
        options: options,
        correctIndex: q.correctIndex,
        explanation: explanation,
        points: q.points,
        order: q.order,
        isActive: q.isActive,
      ),
    );
  }
}

class SetQuestionActiveUseCase {
  const SetQuestionActiveUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<void> call(AdminQuestion q, bool active) async {
    if (active && !q.hasKey) {
      throw const Failure(
        'Soal belum punya kunci jawaban. Edit soal dan pilih jawaban yang benar.',
      );
    }
    if (!active && q.isActive) {
      await _guardLastActive(_repo, testId: q.testId, questionId: q.id);
    }
    await _repo.setActive(q.id, active);
  }
}

/// Menyalin soal sebagai soal NONAKTIF di urutan paling akhir.
class DuplicateQuestionUseCase {
  const DuplicateQuestionUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<String> call(String questionId) async {
    final source = await _repo.getQuestion(questionId);
    final all = await _repo.getQuestions(source.testId);
    final nextOrder = all.isEmpty ? 1 : all.map((q) => q.order).reduce(max) + 1;

    return _repo.saveQuestion(
      source.copyWith(id: '', order: nextOrder, isActive: false),
    );
  }
}

class DeleteQuestionUseCase {
  const DeleteQuestionUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<void> call(AdminQuestion q) async {
    if (q.isActive) {
      await _guardLastActive(_repo, testId: q.testId, questionId: q.id);
    }
    await _repo.deleteQuestion(q.id);
  }
}

class ReorderQuestionsUseCase {
  const ReorderQuestionsUseCase(this._repo);

  final QuestionAdminRepository _repo;

  Future<void> call(List<String> orderedIds) => _repo.reorder(orderedIds);
}
