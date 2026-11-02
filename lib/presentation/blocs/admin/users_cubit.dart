import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/usecases/users/user_usecases.dart';
import 'admin_status.dart';

class UsersState extends Equatable {
  const UsersState({
    this.status = AdminLoadStatus.initial,
    this.users,
    this.isBusy = false,
    this.error,
    this.info,
  });

  final AdminLoadStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final List<UserEntity>? users;

  /// True saat sebuah aksi (nonaktifkan, reset password) sedang berjalan.
  final bool isBusy;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;
  final String? info;

  UsersState copyWith({
    AdminLoadStatus? status,
    List<UserEntity>? users,
    bool? isBusy,
    String? error,
    String? info,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      info: info,
    );
  }

  @override
  List<Object?> get props => [status, users, isBusy, error, info];
}

class UsersCubit extends Cubit<UsersState> {
  UsersCubit({
    required GetAllUsersUseCase getAll,
    required SetUserActiveUseCase setActive,
    required SendUserPasswordResetUseCase sendReset,
  }) : _getAll = getAll,
       _setActive = setActive,
       _sendReset = sendReset,
       super(const UsersState());

  final GetAllUsersUseCase _getAll;
  final SetUserActiveUseCase _setActive;
  final SendUserPasswordResetUseCase _sendReset;

  Future<void> load() async {
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final users = await _getAll();
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.success, users: users));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.failure,
          error: 'Gagal memuat daftar pengguna. Coba lagi.',
        ),
      );
    }
  }

  Future<void> setActive({
    required String actorUid,
    required String uid,
    required bool active,
  }) => _act(
    () => _setActive(actorUid: actorUid, uid: uid, active: active),
    info: active ? 'Akun diaktifkan.' : 'Akun dinonaktifkan.',
    reload: true,
  );

  Future<void> sendReset(String email) => _act(
    () => _sendReset(email),
    info: 'Email reset password dikirim ke $email.',
    reload: false,
  );

  /// Menjalankan aksi, lalu (opsional) memuat ulang daftar tanpa layar loading penuh.
  Future<void> _act(
    Future<void> Function() action, {
    required String info,
    required bool reload,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));

    try {
      await action();
      final users = reload ? await _getAll() : state.users;
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: false,
          status: AdminLoadStatus.success,
          users: users,
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
