import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/course_detail.dart';
import '../../../domain/entities/course_progress.dart';
import '../../../domain/usecases/course/get_course_detail.dart';
import '../../../domain/usecases/progress/mark_material_completed.dart';

part 'material_viewer_event.dart';
part 'material_viewer_state.dart';

class MaterialViewerBloc
    extends Bloc<MaterialViewerEvent, MaterialViewerState> {
  MaterialViewerBloc({
    required GetCourseDetailUseCase getCourseDetail,
    required MarkMaterialCompletedUseCase markCompleted,
  })  : _getCourseDetail = getCourseDetail,
        _markCompleted = markCompleted,
        super(const MaterialViewerState()) {
    on<MaterialViewerStarted>(_onStarted);
    on<MaterialViewerNext>(_onNext);
    on<MaterialViewerPrevious>(_onPrevious);
    on<MaterialViewerCompleteRequested>(_onComplete);
  }

  final GetCourseDetailUseCase _getCourseDetail;
  final MarkMaterialCompletedUseCase _markCompleted;

  String _userId = '';

  Future<void> _onStarted(
    MaterialViewerStarted event,
    Emitter<MaterialViewerState> emit,
  ) async {
    _userId = event.userId;
    emit(state.copyWith(status: MaterialViewerStatus.loading));
    try {
      final detail = await _getCourseDetail(
        userId: event.userId,
        courseId: event.courseId,
      );
      final index =
          detail.materials.indexWhere((m) => m.id == event.materialId);

      if (index < 0) {
        emit(state.copyWith(
          status: MaterialViewerStatus.failure,
          loadError: 'Materi tidak tersedia.',
        ));
        return;
      }

      emit(state.copyWith(
        status: MaterialViewerStatus.success,
        detail: detail,
        index: index,
        progress: detail.item.progress,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(
        status: MaterialViewerStatus.failure,
        loadError: f.message,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: MaterialViewerStatus.failure,
        loadError: 'Gagal memuat materi. Coba lagi.',
      ));
    }
  }

  void _onNext(MaterialViewerNext event, Emitter<MaterialViewerState> emit) {
    final detail = state.detail;
    if (detail == null || state.isSaving) return;
    if (state.index < detail.materials.length - 1) {
      emit(state.copyWith(index: state.index + 1));
    }
  }

  void _onPrevious(
    MaterialViewerPrevious event,
    Emitter<MaterialViewerState> emit,
  ) {
    if (state.detail == null || state.isSaving) return;
    if (state.index > 0) {
      emit(state.copyWith(index: state.index - 1));
    }
  }

  Future<void> _onComplete(
    MaterialViewerCompleteRequested event,
    Emitter<MaterialViewerState> emit,
  ) async {
    final detail = state.detail;
    if (detail == null || state.isSaving) return;

    final material = detail.materials[state.index];
    emit(state.copyWith(isSaving: true));

    try {
      final updated = await _markCompleted(
        userId: _userId,
        course: detail.item.course,
        materials: detail.materials,
        materialId: material.id,
        current: state.progress,
      );

      final isLast = state.index >= detail.materials.length - 1;
      final allDone = updated.materialProgress >= detail.materials.length;

      emit(state.copyWith(
        isSaving: false,
        progress: updated,
        index: isLast ? state.index : state.index + 1,
        info: allDone ? 'Semua materi selesai 🎉' : null,
      ));
    } on Failure catch (f) {
      emit(state.copyWith(isSaving: false, error: f.message));
    } catch (_) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Gagal menyimpan progress. Coba lagi.',
      ));
    }
  }
}