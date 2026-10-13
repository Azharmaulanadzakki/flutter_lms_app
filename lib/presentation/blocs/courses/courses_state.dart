part of 'courses_bloc.dart';

enum CoursesStatus { initial, loading, success, failure }

class CoursesState extends Equatable {
  const CoursesState({
    this.status = CoursesStatus.initial,
    this.items,
    this.error,
  });

  final CoursesStatus status;

  /// Data terakhir yang berhasil dimuat. Tetap ada saat refresh.
  final List<CourseItem>? items;
  final String? error;

  CoursesState copyWith({
    CoursesStatus? status,
    List<CourseItem>? items,
    String? error,
  }) {
    return CoursesState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}