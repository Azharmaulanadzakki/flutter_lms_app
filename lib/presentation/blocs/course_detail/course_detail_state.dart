part of 'course_detail_bloc.dart';

enum CourseDetailStatus { initial, loading, success, failure }

class CourseDetailState extends Equatable {
  const CourseDetailState({
    this.status = CourseDetailStatus.initial,
    this.detail,
    this.error,
  });

  final CourseDetailStatus status;
  final CourseDetail? detail;
  final String? error;

  CourseDetailState copyWith({
    CourseDetailStatus? status,
    CourseDetail? detail,
    String? error,
  }) {
    return CourseDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, detail, error];
}