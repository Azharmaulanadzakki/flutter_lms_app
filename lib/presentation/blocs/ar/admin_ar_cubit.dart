import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/ar_item.dart';
import '../../../domain/usecases/ar/ar_usecases.dart';
import 'ar_cubits.dart';

class AdminArState extends Equatable {
  const AdminArState({
    this.status = ArLoadStatus.initial,
    this.items,
    this.isBusy = false,
    this.error,
    this.info,
  });

  final ArLoadStatus status;
  final List<ArItem>? items;

  /// True saat sebuah aksi (publish, hapus) sedang berjalan.
  final bool isBusy;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;
  final String? info;

  AdminArState copyWith({
    ArLoadStatus? status,
    List<ArItem>? items,
    bool? isBusy,
    String? error,
    String? info,
  }) {
    return AdminArState(
      status: status ?? this.status,
      items: items ?? this.items,
      isBusy: isBusy ?? this.isBusy,
      error: error,
      info: info,
    );
  }

  @override
  List<Object?> get props => [status, items, isBusy, error, info];
}

class AdminArCubit extends Cubit<AdminArState> {
  AdminArCubit({
    required GetAllArItemsUseCase getAll,
    required SetArItemPublishedUseCase setPublished,
    required DeleteArItemUseCase deleteItem,
  }) : _getAll = getAll,
       _setPublished = setPublished,
       _deleteItem = deleteItem,
       super(const AdminArState());

  final GetAllArItemsUseCase _getAll;
  final SetArItemPublishedUseCase _setPublished;
  final DeleteArItemUseCase _deleteItem;

  Future<void> load() async {
    emit(state.copyWith(status: ArLoadStatus.loading));
    try {
      final items = await _getAll();
      if (isClosed) return;
      emit(state.copyWith(status: ArLoadStatus.success, items: items));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: ArLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: ArLoadStatus.failure,
          error: 'Gagal memuat daftar model AR. Coba lagi.',
        ),
      );
    }
  }

  Future<void> setPublished(String id, bool published) => _act(
    () => _setPublished(id, published),
    info: published ? 'Model AR dipublikasikan.' : 'Model AR disembunyikan.',
  );

  Future<void> delete(String id) =>
      _act(() => _deleteItem(id), info: 'Model AR dihapus.');

  /// Menjalankan aksi, lalu memuat ulang daftar (tanpa layar loading penuh).
  Future<void> _act(Future<void> Function() action, {String? info}) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));

    try {
      await action();
      final items = await _getAll();
      if (isClosed) return;
      emit(
        state.copyWith(
          isBusy: false,
          status: ArLoadStatus.success,
          items: items,
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
