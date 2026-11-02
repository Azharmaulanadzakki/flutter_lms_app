import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/game/game_sync_usecases.dart';

class GameSyncState extends Equatable {
  const GameSyncState({
    this.pending = 0,
    this.blocked = 0,
    this.syncing = false,
    this.offline = false,
    this.lastError,
  });

  /// Hasil yang menunggu dikirim.
  final int pending;

  /// Hasil yang diblokir karena terlalu sering ditolak server.
  final int blocked;
  final bool syncing;
  final bool offline;
  final String? lastError;

  GameSyncState copyWith({
    int? pending,
    int? blocked,
    bool? syncing,
    bool? offline,
    String? lastError,
    bool clearError = false,
  }) {
    return GameSyncState(
      pending: pending ?? this.pending,
      blocked: blocked ?? this.blocked,
      syncing: syncing ?? this.syncing,
      offline: offline ?? this.offline,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [pending, blocked, syncing, offline, lastError];
}

class GameSyncCubit extends Cubit<GameSyncState> {
  GameSyncCubit(this._summary, this._sync) : super(const GameSyncState());

  final GetOutboxSummaryUseCase _summary;
  final SyncGameResultsUseCase _sync;

  /// Menghitung ulang jumlah antrean, tanpa menyentuh jaringan.
  Future<void> refresh(String userId) async {
    try {
      final s = await _summary(userId);
      if (isClosed) return;
      emit(state.copyWith(pending: s.pending, blocked: s.blocked));
    } catch (_) {
      // Ringkasan hanya pelengkap tampilan.
    }
  }

  /// [manual]: tombol "Kirim sekarang", entri yang diblokir dicoba lagi.
  Future<void> sync(String userId, {bool manual = false}) async {
    if (state.syncing) return;
    emit(state.copyWith(syncing: true, clearError: true));

    try {
      final report = await _sync(userId, retryBlocked: manual);
      if (isClosed) return;

      if (report.skipped) {
        // Sinkronisasi lain sedang berjalan. Cukup segarkan angkanya.
        emit(state.copyWith(syncing: false));
        await refresh(userId);
        return;
      }

      emit(
        state.copyWith(
          syncing: false,
          pending: report.remaining,
          blocked: report.blocked,
          offline: report.offline,
          lastError: report.lastError,
          clearError: report.lastError == null,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          syncing: false,
          lastError: 'Gagal menyinkronkan hasil. Coba lagi.',
        ),
      );
    }
  }
}
