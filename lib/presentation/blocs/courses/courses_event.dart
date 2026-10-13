part of 'courses_bloc.dart';

sealed class CoursesEvent extends Equatable {
  const CoursesEvent();

  @override
  List<Object?> get props => [];
}

final class CoursesRequested extends CoursesEvent {
  const CoursesRequested(this.userId);

  final String userId;

  @override
  List<Object?> get props => [userId];
}