import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/question.dart';
import '../../../domain/entities/quiz_test.dart';
import '../../../domain/entities/test_attempt.dart';
import '../../../domain/entities/test_overview.dart';
import '../../../domain/entities/test_result.dart';
import '../../../domain/usecases/test/test_usecases.dart';

part 'test_event.dart';
part 'test_state.dart';

class TestBloc extends Bloc<TestEvent, TestState> {
  TestBloc({
    required GetTestOverviewUseCase getOverview,
    required BeginTestUseCase begin,
    required SubmitAnswersUseCase submitAnswers,
    required GradeTestUseCase grade,
    required GetTestResultUseCase getResult,
  })  : _getOverview = getOverview,
        _begin = begin,
        _submitAnswers = submitAnswers,
        _grade = grade,
        _getResult = getResult,
        super(const TestState()) {
    on<TestOpened>(_onOpened);
    on<TestBeginPressed>(_onBegin);
    on<TestOptionSelected>(_onOptionSelected);
    on<TestIndexChanged>(_onIndexChanged);
    on<TestSubmitPressed>(_onSubmit);
    on<TestTicked>(_onTicked);
  }

  final GetTestOverviewUseCase _getOverview;
  final BeginTestUseCase _begin;
  final SubmitAnswersUseCase _submitAnswers;
  final GradeTestUseCase _grade;
  final GetTestResultUseCase _getResult;

  String _userId = '';
  Timer? _timer;

  Future<void> _onOpened(TestOpened event, Emitter<TestState> emit) async {
    _userId = event.userId;
    _timer?.cancel();
    emit(const TestState());

    try {
      final overview = await _getOverview(
        userId: event.userId,
        courseId: event.courseId,
        type: event.type,
      );

            if (overview == null) {
        emit(state.copyWith(
          status: TestStatus.unavailable,
          message: 'Belum ada ${event.type.label} untuk course ini.',
        ));
        return;
      }

      // Test yang belum bisa dibuka (syarat belum terpenuhi).
      if (overview.attempt == null && overview.lockMessage != null) {
        emit(state.copyWith(
          status: TestStatus.unavailable,
          message:
              '${event.type.label} belum bisa dibuka. ${overview.lockMessage}.',
        ));
        return;
      }      

      final attempt = overview.attempt;
    
      // Belum pernah mulai, atau ada sesi yang belum selesai.
      if (attempt == null || attempt.status == AttemptStatus.inProgress) {
        emit(state.copyWith(status: TestStatus.ready, overview: overview));
        return;
      }

      // Sudah dikirim atau dinilai: tampilkan hasil.
      final result = await _getResult(userId: event.userId, attempt: attempt);
      emit(state.copyWith(
        status: TestStatus.result,
        overview: overview,
        attempt: result.attempt,
        result: result,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(status: TestStatus.failure, message: f.message));
    } catch (_) {
      emit(state.copyWith(
        status: TestStatus.failure,
        message: 'Gagal memuat test. Coba lagi.',
      ));
    }
  }

  Future<void> _onBegin(
    TestBeginPressed event,
    Emitter<TestState> emit,
  ) async {
    final overview = state.overview;
    if (overview == null || state.isBusy || state.status != TestStatus.ready) {
      return;
    }

    emit(state.copyWith(isBusy: true));
    try {
      final session = await _begin(userId: _userId, overview: overview);
      final attempt = session.attempt;

      emit(state.copyWith(
        status: TestStatus.inProgress,
        isBusy: false,
        attempt: attempt,
        questions: session.questions,
        answers: const {},
        index: 0,
        remainingSeconds: _remainingOf(attempt),
      ));
      _ensureTimer(attempt);
    } on Failure catch (f) {
      emit(state.copyWith(isBusy: false, error: f.message));
    } catch (_) {
      emit(state.copyWith(
        isBusy: false,
        error: 'Gagal memulai test. Coba lagi.',
      ));
    }
  }

  void _onOptionSelected(
    TestOptionSelected event,
    Emitter<TestState> emit,
  ) {
    if (state.status != TestStatus.inProgress) return;
    emit(state.copyWith(
      answers: {...state.answers, event.questionId: event.optionIndex},
    ));
  }

  void _onIndexChanged(TestIndexChanged event, Emitter<TestState> emit) {
    if (state.status != TestStatus.inProgress) return;
    final last = state.questions.length - 1;
    if (last < 0) return;
    emit(state.copyWith(index: event.index.clamp(0, last)));
  }

  Future<void> _onSubmit(
    TestSubmitPressed event,
    Emitter<TestState> emit,
  ) async {
    final attempt = state.attempt;
    if (attempt == null || state.status != TestStatus.inProgress) return;

    _timer?.cancel();
    emit(state.copyWith(status: TestStatus.submitting));

    // Tahap 1: kirim jawaban. Jika gagal, kembali mengerjakan (jawaban utuh).
    final TestAttempt submitted;
    try {
      submitted = await _submitAnswers(attempt: attempt, answers: state.answers);
    } on Failure catch (f) {
      emit(state.copyWith(status: TestStatus.inProgress, error: f.message));
      if (!event.auto) _ensureTimer(attempt);
      return;
    } catch (_) {
      emit(state.copyWith(
        status: TestStatus.inProgress,
        error: 'Gagal mengirim jawaban. Coba lagi.',
      ));
      if (!event.auto) _ensureTimer(attempt);
      return;
    }

    // Tahap 2: nilai. Jika gagal, jawaban sudah aman dan akan dinilai ulang
    // saat test dibuka lagi.
    try {
      final result = await _grade(
        userId: _userId,
        attempt: submitted,
        questions: state.questions,
      );
      emit(state.copyWith(
        status: TestStatus.result,
        attempt: result.attempt,
        result: result,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: TestStatus.failure,
        message: 'Jawabanmu sudah terkirim, tetapi nilai belum tersimpan. ${f.message}',
      ));
    } catch (_) {
      emit(state.copyWith(
        status: TestStatus.failure,
        message: 'Jawabanmu sudah terkirim, tetapi nilai belum tersimpan. Coba lagi.',
      ));
    }
  }

  void _onTicked(TestTicked event, Emitter<TestState> emit) {
    if (state.status != TestStatus.inProgress) return;
    final attempt = state.attempt;
    if (attempt == null) return;

    final remaining = _remainingOf(attempt);
    if (remaining == null) return;

    emit(state.copyWith(remainingSeconds: remaining));

    if (remaining <= 0) {
      _timer?.cancel();
      add(const TestSubmitPressed(auto: true));
    }
  }

  int? _remainingOf(TestAttempt attempt) {
    final deadline = attempt.deadline;
    if (deadline == null) return null;
    final seconds = deadline.difference(DateTime.now()).inSeconds;
    return seconds < 0 ? 0 : seconds;
  }

  void _ensureTimer(TestAttempt attempt) {
    if (!attempt.hasTimer) return;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const TestTicked()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}