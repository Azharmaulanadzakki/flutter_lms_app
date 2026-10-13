import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/course_detail.dart';
import '../../../domain/usecases/course/get_course_detail.dart';

part 'course_detail_event.dart';
part 'course_detail_state.dart';

class CourseDetailBloc extends Bloc<CourseDetailEvent, CourseDetailState> {
  CourseDetailBloc(this._getCourseDetail) : super(const CourseDetailState()) {
    on<CourseDetailRequested>(_onRequested);
  }

  final GetCourseDetailUseCase _getCourseDetail;

  Future<void> _onRequested(
    CourseDetailRequested event,
    Emitter<CourseDetailState> emit,
  ) async {
    emit(state.copyWith(status: CourseDetailStatus.loading));
    try {
      final detail = await _getCourseDetail(
        userId: event.userId,
        courseId: event.courseId,
      );
      emit(state.copyWith(status: CourseDetailStatus.success, detail: detail));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: CourseDetailStatus.failure,
        error: f.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: CourseDetailStatus.failure,
        error: 'Gagal memuat course. Coba lagi.',
      ));
    }
  }
}