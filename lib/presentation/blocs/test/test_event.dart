part of 'test_bloc.dart';

sealed class TestEvent extends Equatable {
  const TestEvent();

  @override
  List<Object?> get props => [];
}

/// Membuka halaman test: memuat test dan percobaan siswa.
final class TestOpened extends TestEvent {
  const TestOpened({
    required this.userId,
    required this.courseId,
    required this.type,
  });

  final String userId;
  final String courseId;
  final TestType type;

  @override
  List<Object?> get props => [userId, courseId, type];
}

final class TestBeginPressed extends TestEvent {
  const TestBeginPressed();
}

final class TestOptionSelected extends TestEvent {
  const TestOptionSelected({required this.questionId, required this.optionIndex});

  final String questionId;
  final int optionIndex;

  @override
  List<Object?> get props => [questionId, optionIndex];
}

final class TestIndexChanged extends TestEvent {
  const TestIndexChanged(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

/// [auto] true jika dikirim otomatis karena waktu habis.
final class TestSubmitPressed extends TestEvent {
  const TestSubmitPressed({this.auto = false});

  final bool auto;

  @override
  List<Object?> get props => [auto];
}

final class TestTicked extends TestEvent {
  const TestTicked();
}