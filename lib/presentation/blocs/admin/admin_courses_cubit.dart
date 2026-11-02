import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/usecases/admin/admin_course_usecases.dart';
import 'admin_status.dart';

class AdminCoursesState extends Equatable {
  const AdminCoursesState({
    this.status = AdminLoadStatus.initial,
    this.rows,
    this.error,
  });

  final AdminLoadStatus status;
  final List<AdminCourseRow>? rows;
  final String? error;

  AdminCoursesState copyWith({
    AdminLoadStatus? status,
    List<AdminCourseRow>? rows,
    String? error,
  }) {
    return AdminCoursesState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, rows, error];
}

class AdminCoursesCubit extends Cubit<AdminCoursesState> {
  AdminCoursesCubit(this._getCourses) : super(const AdminCoursesState());

  final GetAdminCoursesUseCase _getCourses;

  Future<void> load() async {
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final rows = await _getCourses();
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.success, rows: rows));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.failure, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: AdminLoadStatus.failure,
          error: 'Gagal memuat daftar course. Coba lagi.',
        ),
      );
    }
  }
}
