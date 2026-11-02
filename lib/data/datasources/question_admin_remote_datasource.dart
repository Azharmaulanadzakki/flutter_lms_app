import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/admin_question.dart';
import '../models/quiz_test_model.dart';

/// Operasi soal khusus admin dan guru. Rules menolak semua operasi tulis ini
/// untuk akun yang bukan staf.
class QuestionAdminRemoteDataSource {
  QuestionAdminRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection(name);

  FieldValue get _now => FieldValue.serverTimestamp();

  Future<List<QuizTestModel>> getAllTests() async {
    final snap = await _col(FirestorePaths.tests).get();
    return snap.docs.map(QuizTestModel.fromFirestore).toList();
  }

  Future<QuizTestModel?> getTest(String testId) async {
    final snap = await _col(FirestorePaths.tests).doc(testId).get();
    if (!snap.exists) return null;
    return QuizTestModel.fromFirestore(snap);
  }

  Future<Map<String, QuestionCount>> getQuestionCounts() async {
    final snap = await _col(FirestorePaths.questions).get();

    final total = <String, int>{};
    final active = <String, int>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final testId = data['testId'] as String?;
      if (testId == null || testId.isEmpty) continue;

      total[testId] = (total[testId] ?? 0) + 1;
      if (data['isActive'] == true) {
        active[testId] = (active[testId] ?? 0) + 1;
      }
    }

    return {
      for (final entry in total.entries)
        entry.key: QuestionCount(
          total: entry.value,
          active: active[entry.key] ?? 0,
        ),
    };
  }

  Future<int> countActiveQuestions(String testId) async {
    final snap = await _col(FirestorePaths.questions)
        .where('testId', isEqualTo: testId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs.length;
  }

  Future<int> countAttempts(String testId) async {
    final snap = await _col(FirestorePaths.testAttempts)
        .where('testId', isEqualTo: testId)
        .get();
    return snap.docs.length;
  }

  AdminQuestion _build(
    String id,
    Map<String, dynamic> data,
    Map<String, dynamic>? key,
  ) {
    final points = (data['points'] as num?)?.toInt() ?? 1;

    return AdminQuestion(
      id: id,
      testId: (data['testId'] as String?) ?? '',
      courseId: (data['courseId'] as String?) ?? '',
      text: (data['question'] as String?) ?? '',
      options:
          (data['options'] as List?)?.map((e) => e.toString()).toList() ??
          const <String>[],
      correctIndex: (key?['correctIndex'] as num?)?.toInt() ?? -1,
      explanation: (key?['explanation'] as String?) ?? '',
      points: points < 1 ? 1 : points,
      order: (data['order'] as num?)?.toInt() ?? 0,
      isActive: (data['isActive'] as bool?) ?? false,
    );
  }

  Future<List<AdminQuestion>> getQuestions(String testId) async {
    final results = await Future.wait([
      _col(FirestorePaths.questions).where('testId', isEqualTo: testId).get(),
      _col(FirestorePaths.questionKeys)
          .where('testId', isEqualTo: testId)
          .get(),
    ]);

    final keys = {for (final d in results[1].docs) d.id: d.data()};

    // Diurutkan di sisi aplikasi supaya tidak butuh composite index.
    final list =
        results[0].docs.map((d) => _build(d.id, d.data(), keys[d.id])).toList()
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
          });
    return list;
  }

  Future<AdminQuestion> getQuestion(String questionId) async {
    final question = await _col(FirestorePaths.questions).doc(questionId).get();
    if (!question.exists) throw const Failure('Soal tidak ditemukan.');

    final key = await _col(FirestorePaths.questionKeys).doc(questionId).get();
    return _build(
      question.id,
      question.data() ?? <String, dynamic>{},
      key.data(),
    );
  }

  Future<String> saveQuestion(AdminQuestion q) async {
    final isNew = q.id.isEmpty;
    final questionRef = isNew
        ? _col(FirestorePaths.questions).doc()
        : _col(FirestorePaths.questions).doc(q.id);
    final keyRef = _col(FirestorePaths.questionKeys).doc(questionRef.id);

    // Teks soal terbaca siswa. Kunci dan pembahasan disimpan terpisah.
    final questionData = <String, dynamic>{
      'testId': q.testId,
      'courseId': q.courseId,
      'question': q.text,
      'options': q.options,
      'points': q.points,
      'order': q.order,
      'isActive': q.isActive,
      'updatedAt': _now,
    };

    final batch = _db.batch();
    if (isNew) {
      batch.set(questionRef, {...questionData, 'createdAt': _now});
    } else {
      batch.update(questionRef, questionData);
    }
    batch.set(keyRef, {
      'testId': q.testId,
      'courseId': q.courseId,
      'correctIndex': q.correctIndex,
      'explanation': q.explanation,
      'updatedAt': _now,
    }, SetOptions(merge: true));
    await batch.commit();

    return questionRef.id;
  }

  Future<void> setActive(String questionId, bool active) {
    return _col(FirestorePaths.questions)
        .doc(questionId)
        .update({'isActive': active, 'updatedAt': _now});
  }

  Future<void> deleteQuestion(String questionId) async {
    final batch = _db.batch()
      ..delete(_col(FirestorePaths.questions).doc(questionId))
      ..delete(_col(FirestorePaths.questionKeys).doc(questionId));
    await batch.commit();
  }

  Future<void> reorder(List<String> orderedIds) async {
    const chunk = 400;

    for (var start = 0; start < orderedIds.length; start += chunk) {
      final end = start + chunk > orderedIds.length
          ? orderedIds.length
          : start + chunk;

      final batch = _db.batch();
      for (var i = start; i < end; i++) {
        batch.update(_col(FirestorePaths.questions).doc(orderedIds[i]), {
          'order': i + 1,
          'updatedAt': _now,
        });
      }
      await batch.commit();
    }
  }
}
