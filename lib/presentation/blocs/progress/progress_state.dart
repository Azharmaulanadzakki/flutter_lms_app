part of 'progress_bloc.dart';

enum ProgressStatus { initial, loading, success, failure }

class ProgressState extends Equatable {
  const ProgressState({
    this.status = ProgressStatus.initial,
    this.overview,
    this.error,
  });

  final ProgressStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final ProgressOverview? overview;
  final String? error;

  ProgressState copyWith({
    ProgressStatus? status,
    ProgressOverview? overview,
    String? error,
  }) {
    return ProgressState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, overview, error];
}