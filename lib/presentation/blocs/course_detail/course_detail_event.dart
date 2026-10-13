part of 'course_detail_bloc.dart';

sealed class CourseDetailEvent extends Equatable {
  const CourseDetailEvent();

  @override
  List<Object?> get props => [];
}

final class CourseDetailRequested extends CourseDetailEvent {
  const CourseDetailRequested({required this.userId, required this.courseId});

  final String userId;
  final String courseId;

  @override
  List<Object?> get props => [userId, courseId];
}