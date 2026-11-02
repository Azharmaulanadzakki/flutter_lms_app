import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/ar_item.dart';
import '../../../domain/usecases/ar/ar_usecases.dart';

enum ArLoadStatus { initial, loading, success, failure }

// ---------- Daftar model AR untuk siswa ----------

class ArListState extends Equatable {
  const ArListState({
    this.status = ArLoadStatus.initial,
    this.items,
    this.error,
  });

  final ArLoadStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final List<ArItem>? items;
  final String? error;

  ArListState copyWith({
    ArLoadStatus? status,
    List<ArItem>? items,
    String? error,
  }) {
    return ArListState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}

class ArListCubit extends Cubit<ArListState> {
  ArListCubit(this._getItems) : super(const ArListState());

  final GetPublishedArItemsUseCase _getItems;

  Future<void> load() async {
    emit(state.copyWith(status: ArLoadStatus.loading));
    try {
      final items = await _getItems();
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
          error: 'Gagal memuat model AR. Coba lagi.',
        ),
      );
    }
  }
}

// ---------- Satu model AR (untuk halaman scan) ----------

class ArItemState extends Equatable {
  const ArItemState({
    this.status = ArLoadStatus.initial,
    this.item,
    this.error,
  });

  final ArLoadStatus status;
  final ArItem? item;
  final String? error;

  @override
  List<Object?> get props => [status, item, error];
}

class ArItemCubit extends Cubit<ArItemState> {
  ArItemCubit(this._getItem) : super(const ArItemState());

  final GetArItemUseCase _getItem;

  Future<void> load(String id) async {
    emit(const ArItemState(status: ArLoadStatus.loading));
    try {
      final item = await _getItem(id);
      if (isClosed) return;
      emit(ArItemState(status: ArLoadStatus.success, item: item));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(ArItemState(status: ArLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        const ArItemState(
          status: ArLoadStatus.failure,
          error: 'Gagal memuat model AR. Coba lagi.',
        ),
      );
    }
  }
}
