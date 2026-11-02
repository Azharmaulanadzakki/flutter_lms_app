import 'package:equatable/equatable.dart';

import 'course.dart';
import 'quiz_test.dart';

/// Huruf pilihan: 0 menjadi A, 1 menjadi B, dan seterusnya.
String optionLetter(int index) => String.fromCharCode(65 + index);

/// Soal beserta kunci jawabannya, untuk admin dan guru.
class AdminQuestion extends Equatable {
  const AdminQuestion({
    required this.id,
    required this.testId,
    required this.courseId,
    required this.text,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.points,
    required this.order,
    required this.isActive,
  });

  /// Kosong untuk soal baru.
  final String id;
  final String testId;
  final String courseId;
  final String text;
  final List<String> options;

  /// Indeks pilihan yang benar. -1 jika kunci belum ada.
  final int correctIndex;
  final String explanation;
  final int points;
  final int order;
  final bool isActive;

  bool get isNew => id.isEmpty;
  bool get hasKey => correctIndex >= 0 && correctIndex < options.length;

  AdminQuestion copyWith({String? id, int? order, bool? isActive}) {
    return AdminQuestion(
      id: id ?? this.id,
      testId: testId,
      courseId: courseId,
      text: text,
      options: options,
      correctIndex: correctIndex,
      explanation: explanation,
      points: points,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    testId,
    courseId,
    text,
    options,
    correctIndex,
    explanation,
    points,
    order,
    isActive,
  ];
}

class QuestionCount extends Equatable {
  const QuestionCount({this.total = 0, this.active = 0});

  final int total;
  final int active;

  @override
  List<Object?> get props => [total, active];
}

class TestQuestionSummary extends Equatable {
  const TestQuestionSummary({required this.test, required this.count});

  final QuizTest test;
  final QuestionCount count;

  @override
  List<Object?> get props => [test, count];
}

class CourseQuestionGroup extends Equatable {
  const CourseQuestionGroup({required this.course, required this.tests});

  final Course course;

  /// Pre-test lalu post-test, hanya yang sudah dibuat.
  final List<TestQuestionSummary> tests;

  @override
  List<Object?> get props => [course, tests];
}

class QuestionOverview extends Equatable {
  const QuestionOverview({required this.groups});

  final List<CourseQuestionGroup> groups;

  @override
  List<Object?> get props => [groups];
}

/// Data halaman daftar soal untuk satu test.
class QuestionListData extends Equatable {
  const QuestionListData({
    required this.test,
    required this.courseTitle,
    required this.questions,
    required this.attemptCount,
  });

  final QuizTest test;
  final String courseTitle;
  final List<AdminQuestion> questions;

  /// Jumlah siswa yang sudah memulai test ini.
  final int attemptCount;

  int get activeCount => questions.where((q) => q.isActive).length;

  QuestionListData copyWith({List<AdminQuestion>? questions}) {
    return QuestionListData(
      test: test,
      courseTitle: courseTitle,
      questions: questions ?? this.questions,
      attemptCount: attemptCount,
    );
  }

  @override
  List<Object?> get props => [test, courseTitle, questions, attemptCount];
}
