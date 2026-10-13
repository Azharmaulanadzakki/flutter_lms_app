import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/progress_overview.dart';
import '../../../domain/usecases/progress/get_progress_overview.dart';

part 'progress_event.dart';
part 'progress_state.dart';

class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  ProgressBloc(this._getOverview) : super(const ProgressState()) {
    on<ProgressRequested>(_onRequested);
  }

  final GetProgressOverviewUseCase _getOverview;

  Future<void> _onRequested(
    ProgressRequested event,
    Emitter<ProgressState> emit,
  ) async {
    emit(state.copyWith(status: ProgressStatus.loading));
    try {
      final overview = await _getOverview(event.userId);
      emit(state.copyWith(status: ProgressStatus.success, overview: overview));
    } on Failure catch (f) {
      emit(state.copyWith(status: ProgressStatus.failure, error: f.message));
    } catch (_) {
      emit(state.copyWith(
        status: ProgressStatus.failure,
        error: 'Gagal memuat progress. Coba lagi.',
      ));
    }
  }
}