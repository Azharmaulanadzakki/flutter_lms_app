import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/course_item.dart';
import '../../../domain/usecases/course/get_course_items.dart';

part 'courses_event.dart';
part 'courses_state.dart';

class CoursesBloc extends Bloc<CoursesEvent, CoursesState> {
  CoursesBloc(this._getCourseItems) : super(const CoursesState()) {
    on<CoursesRequested>(_onRequested);
  }

  final GetCourseItemsUseCase _getCourseItems;

  Future<void> _onRequested(
    CoursesRequested event,
    Emitter<CoursesState> emit,
  ) async {
    emit(state.copyWith(status: CoursesStatus.loading));
    try {
      final items = await _getCourseItems(event.userId);
      emit(state.copyWith(status: CoursesStatus.success, items: items));
    } on Failure catch (f) {
      emit(state.copyWith(status: CoursesStatus.failure, error: f.message));
    } catch (_) {
      emit(state.copyWith(
        status: CoursesStatus.failure,
        error: 'Gagal memuat daftar course. Coba lagi.',
      ));
    }
  }
}