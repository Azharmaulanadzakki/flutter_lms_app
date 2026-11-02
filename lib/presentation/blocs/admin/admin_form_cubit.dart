import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';

enum AdminFormStatus { loading, ready, saving, saved, failure }

class AdminFormState<T> extends Equatable {
  const AdminFormState({
    this.status = AdminFormStatus.loading,
    this.initial,
    this.loadError,
    this.error,
  });

  final AdminFormStatus status;

  /// Data awal form (data yang diedit, atau data kosong untuk entri baru).
  final T? initial;

  /// Error yang menggantikan seluruh form (gagal memuat).
  final String? loadError;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;

  AdminFormState<T> copyWith({
    AdminFormStatus? status,
    T? initial,
    String? loadError,
    String? error,
  }) {
    return AdminFormState<T>(
      status: status ?? this.status,
      initial: initial ?? this.initial,
      loadError: loadError,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, initial, loadError, error];
}

/// Cubit form generik: memuat data awal, lalu menyimpan nilai [T].
class AdminFormCubit<T> extends Cubit<AdminFormState<T>> {
  AdminFormCubit({
    required Future<T> Function() load,
    required Future<void> Function(T value) save,
  }) : _load = load,
       _save = save,
       super(AdminFormState<T>());

  final Future<T> Function() _load;
  final Future<void> Function(T value) _save;

  Future<void> init() async {
    emit(AdminFormState<T>());
    try {
      final value = await _load();
      if (isClosed) return;
      emit(AdminFormState<T>(status: AdminFormStatus.ready, initial: value));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        AdminFormState<T>(
          status: AdminFormStatus.failure,
          loadError: f.message,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        AdminFormState<T>(
          status: AdminFormStatus.failure,
          loadError: 'Gagal memuat data. Coba lagi.',
        ),
      );
    }
  }

  Future<void> submit(T value) async {
    if (state.status == AdminFormStatus.saving) return;
    emit(state.copyWith(status: AdminFormStatus.saving));

    try {
      await _save(value);
      if (isClosed) return;
      emit(state.copyWith(status: AdminFormStatus.saved));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminFormStatus.ready, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminFormStatus.ready,
          error: 'Gagal menyimpan. Coba lagi.',
        ),
      );
    }
  }
}
