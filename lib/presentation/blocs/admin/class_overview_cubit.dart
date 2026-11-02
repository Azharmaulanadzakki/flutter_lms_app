import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/usecases/admin/admin_overview_usecases.dart';
import 'admin_status.dart';

class ClassOverviewState extends Equatable {
  const ClassOverviewState({
    this.status = AdminLoadStatus.initial,
    this.overview,
    this.error,
  });

  final AdminLoadStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final ClassOverview? overview;
  final String? error;

  ClassOverviewState copyWith({
    AdminLoadStatus? status,
    ClassOverview? overview,
    String? error,
  }) {
    return ClassOverviewState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, overview, error];
}

class ClassOverviewCubit extends Cubit<ClassOverviewState> {
  ClassOverviewCubit(this._getOverview) : super(const ClassOverviewState());

  final GetClassOverviewUseCase _getOverview;

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
          error: 'Gagal memuat data kelas. Coba lagi.',
        ),
      );
    }
  }
}
