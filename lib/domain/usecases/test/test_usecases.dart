import 'dart:math';

import '../../../core/errors/failures.dart';
import '../../entities/course_item.dart';
import '../../entities/question.dart';
import '../../entities/quiz_test.dart';
import '../../entities/test_attempt.dart';
import '../../entities/test_overview.dart';
import '../../entities/test_result.dart';
import '../../repositories/course_repository.dart';
import '../../repositories/progress_repository.dart';
import '../../repositories/test_repository.dart';
import '../progress/record_posttest_score.dart';
import '../progress/record_pretest_score.dart';
import 'test_grader.dart';

/// Test aktif + percobaan siswa. Null jika course belum punya test.
/// Untuk post-test yang belum pernah dimulai, syarat pembukaan dicek di sini.
class GetTestOverviewUseCase {
  const GetTestOverviewUseCase(this._tests, this._courses, this._progress);

  final TestRepository _tests;
  final CourseRepository _courses;
  final ProgressRepository _progress;

  Future<TestOverview?> call({
    required String userId,
    required String courseId,
    required TestType type,
  }) async {
    final test = await _tests.getActiveTest(courseId: courseId, type: type);
    if (test == null) return null;

    final attempt = await _tests.getAttempt(userId: userId, testId: test.id);

    String? lockMessage;
    if (type == TestType.post && attempt == null) {
      final course = await _courses.getCourseById(courseId);
      final materials = await _courses.getPublishedMaterials(courseId);
      final progress = (await _progress.getUserProgress(userId))[courseId];

      final item = CourseItem(
        course: course,
        materialCount: materials.length,
        progress: progress,
      );
      final lock = item.postTestLock;
      if (lock != PostTestLock.none) lockMessage = lock.message;
    }

    return TestOverview(test: test, attempt: attempt, lockMessage: lockMessage);
  }
}

/// Soal milik sebuah attempt, sesuai urutan yang tersimpan.
class GetAttemptQuestionsUseCase {
  const GetAttemptQuestionsUseCase(this._tests);

  final TestRepository _tests;

  Future<List<Question>> call(TestAttempt attempt) async {
    final pool = await _tests.getActiveQuestions(attempt.testId);
    final byId = {for (final q in pool) q.id: q};
    return [
      for (final id in attempt.questionIds)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }
}

/// Memulai test baru (soal diacak) atau melanjutkan sesi yang belum selesai.
class BeginTestUseCase {
  BeginTestUseCase(this._tests, [Random? random])
      : _random = random ?? Random();

  final TestRepository _tests;
  final Random _random;

  Future<TestSession> call({
    required String userId,
    required TestOverview overview,
  }) async {
    final test = overview.test;
    final existing = overview.attempt;
    final pool = await _tests.getActiveQuestions(test.id);

    // Melanjutkan sesi yang belum selesai.
    if (existing != null) {
      if (existing.status != AttemptStatus.inProgress) {
        throw const Failure('Test ini sudah dikerjakan.');
      }
      final byId = {for (final q in pool) q.id: q};
      final questions = [
        for (final id in existing.questionIds)
          if (byId.containsKey(id)) byId[id]!,
      ];
      if (questions.isEmpty) {
        throw const Failure('Soal untuk test ini tidak tersedia.');
      }
      return TestSession(attempt: existing, questions: questions);
    }

    // Sesi baru.
    if (overview.lockMessage != null) {
      throw Failure('${test.type.label} belum bisa dibuka. ${overview.lockMessage}.');
    }
    if (pool.isEmpty) {
      throw const Failure('Soal untuk test ini belum tersedia.');
    }

    final shuffled = [...pool]..shuffle(_random);
    final take = test.questionCount > 0
        ? min(test.questionCount, shuffled.length)
        : shuffled.length;
    final picked = shuffled.take(take).toList();

    final attempt = await _tests.createAttempt(
      userId: userId,
      test: test,
      questionIds: [for (final q in picked) q.id],
    );
    return TestSession(attempt: attempt, questions: picked);
  }
}

/// Mengirim jawaban. Status attempt menjadi `submitted`.
class SubmitAnswersUseCase {
  const SubmitAnswersUseCase(this._tests);

  final TestRepository _tests;

  Future<TestAttempt> call({
    required TestAttempt attempt,
    required Map<String, int> answers,
  }) async {
    await _tests.submitAnswers(attempt: attempt, answers: answers);
    return attempt.copyWith(status: AttemptStatus.submitted, answers: answers);
  }
}

/// Membuka kunci, menghitung nilai, memperbarui progress, lalu
/// menandai attempt sebagai `graded`.
///
/// Urutan sengaja: progress ditulis SEBELUM attempt ditandai graded.
/// Jika langkah ini terputus, attempt tetap `submitted` dan akan dinilai
/// ulang (hasil sama) saat test dibuka lagi.
class GradeTestUseCase {
  const GradeTestUseCase(
    this._tests,
    this._recordPre,
    this._recordPost, [
    this._grader = const TestGrader(),
  ]);

  final TestRepository _tests;
  final RecordPreTestScoreUseCase _recordPre;
  final RecordPostTestScoreUseCase _recordPost;
  final TestGrader _grader;

  Future<TestResult> call({
    required String userId,
    required TestAttempt attempt,
    required List<Question> questions,
  }) async {
    final keys = await _tests.getKeys([for (final q in questions) q.id]);
    final outcome = _grader.grade(
      questions: questions,
      answers: attempt.answers,
      keys: keys,
    );

    double? preScore;
    var completed = false;

    if (attempt.type == TestType.pre) {
      await _recordPre(
        userId: userId,
        courseId: attempt.courseId,
        score: outcome.score,
      );
    } else {
      final progress = await _recordPost(
        userId: userId,
        courseId: attempt.courseId,
        score: outcome.score,
      );
      preScore = progress.preTestScore;
      completed = progress.isCompleted;
    }

    await _tests.saveGrade(
      attempt: attempt,
      score: outcome.score,
      correct: outcome.correct,
      wrong: outcome.wrong,
    );

    return TestResult(
      attempt: attempt.copyWith(
        status: AttemptStatus.graded,
        score: outcome.score,
        correctCount: outcome.correct,
        wrongCount: outcome.wrong,
        completedAt: DateTime.now(),
      ),
      items: outcome.items,
      preTestScore: preScore,
      courseCompleted: completed,
    );
  }
}

/// Hasil untuk attempt yang sudah dikirim atau dinilai.
/// - `submitted`: dinilai sekarang (pemulihan jika penilaian sebelumnya gagal).
/// - `graded`: hanya membangun review dari kunci jawaban.
class GetTestResultUseCase {
  const GetTestResultUseCase(
    this._attemptQuestions,
    this._tests,
    this._progress,
    this._grade, [
    this._grader = const TestGrader(),
  ]);

  final GetAttemptQuestionsUseCase _attemptQuestions;
  final TestRepository _tests;
  final ProgressRepository _progress;
  final GradeTestUseCase _grade;
  final TestGrader _grader;

  Future<TestResult> call({
    required String userId,
    required TestAttempt attempt,
  }) async {
    final questions = await _attemptQuestions(attempt);
    if (questions.isEmpty) {
      throw const Failure('Soal untuk test ini tidak tersedia.');
    }

    if (attempt.status == AttemptStatus.submitted) {
      return _grade(userId: userId, attempt: attempt, questions: questions);
    }

    final keys = await _tests.getKeys([for (final q in questions) q.id]);
    final outcome = _grader.grade(
      questions: questions,
      answers: attempt.answers,
      keys: keys,
    );

    double? preScore;
    var completed = false;
    if (attempt.type == TestType.post) {
      final progress = (await _progress.getUserProgress(userId))[attempt.courseId];
      preScore = progress?.preTestScore;
      completed = progress?.isCompleted ?? false;
    }

    return TestResult(
      attempt: attempt,
      items: outcome.items,
      preTestScore: preScore,
      courseCompleted: completed,
    );
  }
}