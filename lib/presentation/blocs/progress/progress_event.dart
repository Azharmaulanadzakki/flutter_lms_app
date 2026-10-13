part of 'progress_bloc.dart';

sealed class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

/// Muat (atau muat ulang) ringkasan progress.
final class ProgressRequested extends ProgressEvent {
  const ProgressRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}