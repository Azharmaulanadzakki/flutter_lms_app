part of 'dashboard_bloc.dart';

sealed class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Muat (atau muat ulang) data dashboard.
final class DashboardRequested extends DashboardEvent {
  const DashboardRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}