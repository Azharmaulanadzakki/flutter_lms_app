part of 'test_bloc.dart';

enum TestStatus {
  loading,
  unavailable,
  ready,
  inProgress,
  submitting,
  result,
  failure,
}

class TestState extends Equatable {
  const TestState({
    this.status = TestStatus.loading,
    this.overview,
    this.attempt,
    this.questions = const [],
    this.answers = const {},
    this.index = 0,
    this.remainingSeconds,
    this.result,
    this.isBusy = false,
    this.message,
    this.error,
  });

  final TestStatus status;
  final TestOverview? overview;
  final TestAttempt? attempt;
  final List<Question> questions;

  /// questionId -> indeks pilihan.
  final Map<String, int> answers;
  final int index;

  /// Sisa waktu dalam detik. Null jika tanpa timer.
  final int? remainingSeconds;
  final TestResult? result;

  /// True saat tombol Mulai sedang diproses.
  final bool isBusy;

  /// Pesan untuk layar kosong atau gagal.
  final String? message;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;

  TestState copyWith({
    TestStatus? status,
    TestOverview? overview,
    TestAttempt? attempt,
    List<Question>? questions,
    Map<String, int>? answers,
    int? index,
    int? remainingSeconds,
    TestResult? result,
    bool? isBusy,
    String? message,
    String? error,
  }) {
    return TestState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      attempt: attempt ?? this.attempt,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      index: index ?? this.index,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      result: result ?? this.result,
      isBusy: isBusy ?? this.isBusy,
      message: message ?? this.message,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        overview,
        attempt,
        questions,
        answers,
        index,
        remainingSeconds,
        result,
        isBusy,
        message,
        error,
      ];
}