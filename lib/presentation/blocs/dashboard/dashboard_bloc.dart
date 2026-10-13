import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/dashboard_data.dart';
import '../../../domain/usecases/course/get_dashboard_data.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._getDashboardData) : super(const DashboardState()) {
    on<DashboardRequested>(_onRequested);
  }

  final GetDashboardDataUseCase _getDashboardData;

  Future<void> _onRequested(
    DashboardRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    try {
      final data = await _getDashboardData(event.userId);
      emit(state.copyWith(status: DashboardStatus.success, data: data));
    } on Failure catch (f) {
      emit(state.copyWith(status: DashboardStatus.failure, error: f.message));
    } catch (_) {
      emit(state.copyWith(
        status: DashboardStatus.failure,
        error: 'Gagal memuat dashboard. Coba lagi.',
      ));
    }
  }
}