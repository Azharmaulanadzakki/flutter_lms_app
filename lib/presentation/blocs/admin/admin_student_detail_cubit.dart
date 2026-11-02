import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/progress_overview.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/game/game_result_view.dart';
import '../../../domain/usecases/admin/admin_overview_usecases.dart';
import '../../../domain/usecases/game/game_results_usecases.dart';
import '../../../domain/usecases/progress/get_progress_overview.dart';
import 'admin_status.dart';

class AdminStudentDetailState extends Equatable {
  const AdminStudentDetailState({
    this.status = AdminLoadStatus.initial,
    this.user,
    this.overview,
    this.results = const [],
    this.error,
  });

  final AdminLoadStatus status;
  final UserEntity? user;
  final ProgressOverview? overview;

  /// Hasil simulasi di server. Kosong jika belum ada atau gagal dimuat.
  final List<GameResultView> results;
  final String? error;

  AdminStudentDetailState copyWith({
    AdminLoadStatus? status,
    UserEntity? user,
    ProgressOverview? overview,
    List<GameResultView>? results,
    String? error,
  }) {
    return AdminStudentDetailState(
      status: status ?? this.status,
      user: user ?? this.user,
      overview: overview ?? this.overview,
      results: results ?? this.results,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, user, overview, results, error];
}

class AdminStudentDetailCubit extends Cubit<AdminStudentDetailState> {
  AdminStudentDetailCubit({
    required GetStudentUseCase getStudent,
    required GetProgressOverviewUseCase getOverview,
    required GetStudentGameResultsUseCase getResults,
  }) : _getStudent = getStudent,
       _getOverview = getOverview,
       _getResults = getResults,
       super(const AdminStudentDetailState());

  final GetStudentUseCase _getStudent;
  final GetProgressOverviewUseCase _getOverview;
  final GetStudentGameResultsUseCase _getResults;

  Future<void> load(String uid) async {
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final user = await _getStudent(uid);
      final overview = await _getOverview(uid);

      // Hasil simulasi pelengkap: gagal memuatnya tidak boleh menggagalkan halaman.
      var results = <GameResultView>[];
      try {
        results = await _getResults(uid);
      } catch (_) {}

      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.success,
          user: user,
          overview: overview,
          results: results,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.failure,
          error: 'Gagal memuat data siswa. Coba lagi.',
        ),
      );
    }
  }
}
