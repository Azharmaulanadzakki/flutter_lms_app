import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/admin_question.dart';
import '../../../domain/usecases/questions/question_usecases.dart';
import 'admin_status.dart';

// ---------- Ringkasan semua test (tab Soal) ----------

class QuestionOverviewState extends Equatable {
  const QuestionOverviewState({
    this.status = AdminLoadStatus.initial,
    this.overview,
    this.error,
  });

  final AdminLoadStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final QuestionOverview? overview;
  final String? error;

  QuestionOverviewState copyWith({
    AdminLoadStatus? status,
    QuestionOverview? overview,
    String? error,
  }) {
    return QuestionOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, overview, error];
}

class QuestionOverviewCubit extends Cubit<QuestionOverviewState> {
  QuestionOverviewCubit(this._getOverview)
    : super(const QuestionOverviewState());

  final GetQuestionOverviewUseCase _getOverview;

  Future<void> load() async {
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final overview = await _getOverview();
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.success, overview: overview));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.failure,
          error: 'Gagal memuat daftar soal. Coba lagi.',
        ),
      );
    }
  }
}

// ---------- Daftar soal satu test ----------

class QuestionListState extends Equatable {
  const QuestionListState({
    this.status = AdminLoadStatus.initial,
    this.data,
    this.isBusy = false,
    this.loadError,
    this.error,
    this.info,
  });

  final AdminLoadStatus status;
  final QuestionListData? data;

  /// True saat sebuah aksi (aktifkan, hapus, urutkan) sedang berjalan.
  final bool isBusy;

  /// Error yang menggantikan seluruh halaman (gagal memuat).
  final String? loadError;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;
  final String? info;

  QuestionListState copyWith({
    AdminLoadStatus? status,
    QuestionListData? data,
    bool? isBusy,
    String? loadError,
    String? error,
    String? info,
  }) {
    return QuestionListState(
      status: status ?? this.status,
      data: data ?? this.data,
      isBusy: isBusy ?? this.isBusy,
      loadError: loadError,
      error: error,
      info: info,
    );
  }

  @override
  List<Object?> get props => [status, data, isBusy, loadError, error, info];
}

class QuestionListCubit extends Cubit<QuestionListState> {
  QuestionListCubit({
    required GetQuestionListUseCase getList,
    required SetQuestionActiveUseCase setActive,
    required DuplicateQuestionUseCase duplicate,
    required DeleteQuestionUseCase delete,
    required ReorderQuestionsUseCase reorder,
  }) : _getList = getList,
       _setActive = setActive,
       _duplicate = duplicate,
       _delete = delete,
       _reorder = reorder,
       super(const QuestionListState());

  final GetQuestionListUseCase _getList;
  final SetQuestionActiveUseCase _setActive;
  final DuplicateQuestionUseCase _duplicate;
  final DeleteQuestionUseCase _delete;
  final ReorderQuestionsUseCase _reorder;

  String _testId = '';

  Future<void> load(String testId) async {
    _testId = testId;
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final data = await _getList(testId);
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.success, data: data));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        state.copyWith(status: AdminLoadStatus.failure, loadError: f.message),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.failure,
          loadError: 'Gagal memuat soal. Coba lagi.',
        ),
      );
    }
  }

  Future<void> reload() => load(_testId);

  Future<void> setActive(AdminQuestion q, bool active) => _act(
    () => _setActive(q, active),
    info: active ? 'Soal diaktifkan.' : 'Soal dinonaktifkan.',
  );

  Future<void> duplicate(String questionId) => _act(
    () => _duplicate(questionId),
    info: 'Soal diduplikasi sebagai nonaktif. Edit lalu aktifkan.',
  );

  Future<void> delete(AdminQuestion q) =>
      _act(() => _delete(q), info: 'Soal dihapus.');

  /// Memindahkan soal. Tampilan diperbarui langsung, lalu urutan disimpan.
  Future<void> reorder(int oldIndex, int newIndex) async {
    final data = state.data;
    if (data == null || state.isBusy) return;

    var target = newIndex;
    if (target > oldIndex) target -= 1;
    if (target == oldIndex) return;

    final list = [...data.questions];
    final moved = list.removeAt(oldIndex);
    list.insert(target, moved);

    final renumbered = [
      for (var i = 0; i < list.length; i++) list[i].copyWith(order: i + 1),
    ];

    emit(
      state.copyWith(data: data.copyWith(questions: renumbered), isBusy: true),
    );

    try {
      await _reorder([for (final q in renumbered) q.id]);
      if (isClosed) return;
      emit(state.copyWith(isBusy: false));
    } on Failure catch (f) {
      await _recover(f.message);
    } catch (_) {
      await _recover('Gagal menyimpan urutan. Coba lagi.');
    }
  }

  /// Mengembalikan tampilan ke data di server setelah penyimpanan gagal.
  Future<void> _recover(String message) async {
    try {
      final data = await _getList(_testId);
      if (isClosed) return;
      emit(state.copyWith(isBusy: false, data: data, error: message));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(isBusy: false, error: message));
    }
  }

  /// Menjalankan aksi, lalu memuat ulang daftar (tanpa layar loading penuh).
  Future<void> _act(
    Future<void> Function() action, {
    required String info,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));

    try {
      await action();
      final data = await _getList(_testId);
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: false,
          status: AdminLoadStatus.success,
          data: data,
          info: info,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(isBusy: false, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(isBusy: false, error: 'Terjadi kesalahan. Coba lagi.'),
      );
    }
  }
}
