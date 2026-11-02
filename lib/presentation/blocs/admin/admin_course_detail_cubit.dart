// TODO Implement this library.
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../../domain/usecases/admin/admin_course_usecases.dart';
import '../../../domain/usecases/admin/admin_material_usecases.dart';
import '../../../domain/usecases/admin/admin_test_usecases.dart';
import 'admin_status.dart';

class AdminCourseDetailState extends Equatable {
  const AdminCourseDetailState({
    this.status = AdminLoadStatus.initial,
    this.detail,
    this.isBusy = false,
    this.loadError,
    this.error,
    this.info,
    this.deleted = false,
  });

  final AdminLoadStatus status;
  final AdminCourseDetail? detail;

  /// True saat sebuah aksi (publish, hapus, dan sebagainya) sedang berjalan.
  final bool isBusy;

  /// Error yang menggantikan seluruh halaman (gagal memuat).
  final String? loadError;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;
  final String? info;

  /// True setelah course berhasil dihapus.
  final bool deleted;

  AdminCourseDetailState copyWith({
    AdminLoadStatus? status,
    AdminCourseDetail? detail,
    bool? isBusy,
    String? loadError,
    String? error,
    String? info,
    bool? deleted,
  }) {
    return AdminCourseDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      isBusy: isBusy ?? this.isBusy,
      loadError: loadError,
      error: error,
      info: info,
      deleted: deleted ?? this.deleted,
    );
  }

  @override
  List<Object?> get props =>
      [status, detail, isBusy, loadError, error, info, deleted];
}

class AdminCourseDetailCubit extends Cubit<AdminCourseDetailState> {
  AdminCourseDetailCubit({
    required GetAdminCourseDetailUseCase getDetail,
    required SetCoursePublishedUseCase setCoursePublished,
    required DeleteCourseUseCase deleteCourse,
    required SetMaterialPublishedUseCase setMaterialPublished,
    required DeleteMaterialUseCase deleteMaterial,
    required SetTestActiveUseCase setTestActive,
    required DeleteTestUseCase deleteTest,
  })  : _getDetail = getDetail,
        _setCoursePublished = setCoursePublished,
        _deleteCourse = deleteCourse,
        _setMaterialPublished = setMaterialPublished,
        _deleteMaterial = deleteMaterial,
        _setTestActive = setTestActive,
        _deleteTest = deleteTest,
        super(const AdminCourseDetailState());

  final GetAdminCourseDetailUseCase _getDetail;
  final SetCoursePublishedUseCase _setCoursePublished;
  final DeleteCourseUseCase _deleteCourse;
  final SetMaterialPublishedUseCase _setMaterialPublished;
  final DeleteMaterialUseCase _deleteMaterial;
  final SetTestActiveUseCase _setTestActive;
  final DeleteTestUseCase _deleteTest;

  String _courseId = '';

  Future<void> load(String courseId) async {
    _courseId = courseId;
    emit(state.copyWith(status: AdminLoadStatus.loading));
    try {
      final detail = await _getDetail(courseId);
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.success, detail: detail));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(status: AdminLoadStatus.failure, loadError: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        status: AdminLoadStatus.failure,
        loadError: 'Gagal memuat course. Coba lagi.',
      ));
    }
  }

  Future<void> reload() => load(_courseId);

  Future<void> setCoursePublished(bool published) => _act(
        () => _setCoursePublished(_courseId, published),
        info: published ? 'Course dipublikasikan.' : 'Course disembunyikan.',
      );

  Future<void> deleteCourse() =>
      _act(() => _deleteCourse(_courseId), deletes: true);

  Future<void> setMaterialPublished(String materialId, bool published) => _act(
        () => _setMaterialPublished(materialId, published),
        info: published ? 'Materi dipublikasikan.' : 'Materi disembunyikan.',
      );

  Future<void> deleteMaterial(String materialId) => _act(
        () => _deleteMaterial(materialId),
        info: 'Materi dihapus.',
      );

  Future<void> setTestActive(String testId, bool active) => _act(
        () => _setTestActive(testId, active),
        info: active ? 'Test diaktifkan.' : 'Test dinonaktifkan.',
      );

  Future<void> deleteTest(String testId) => _act(
        () => _deleteTest(testId),
        info: 'Test dihapus.',
      );

  /// Menjalankan aksi, lalu memuat ulang data (tanpa layar loading penuh).
  Future<void> _act(
    Future<void> Function() action, {
    String? info,
    bool deletes = false,
  }) async {
    if (state.isBusy) return;
    emit(state.copyWith(isBusy: true));

    try {
      await action();
      if (isClosed) return;

      if (deletes) {
        emit(state.copyWith(isBusy: false, deleted: true));
        return;
      }

      final detail = await _getDetail(_courseId);
      if (isClosed) return;
      emit(state.copyWith(
        isBusy: false,
        status: AdminLoadStatus.success,
        detail: detail,
        info: info,
      ));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(isBusy: false, error: f.message));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(
        isBusy: false,
        error: 'Terjadi kesalahan. Coba lagi.',
      ));
    }
  }
}