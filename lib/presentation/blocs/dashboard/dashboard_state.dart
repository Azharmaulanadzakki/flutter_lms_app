part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, success, failure }

class DashboardState extends Equatable {
  const DashboardState({
    this.status = DashboardStatus.initial,
    this.data,
    this.error,
  });

  final DashboardStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final DashboardData? data;
  final String? error;

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardData? data,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}