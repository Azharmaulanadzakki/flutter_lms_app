part of 'material_viewer_bloc.dart';

enum MaterialViewerStatus { loading, success, failure }

class MaterialViewerState extends Equatable {
  const MaterialViewerState({
    this.status = MaterialViewerStatus.loading,
    this.detail,
    this.index = 0,
    this.progress,
    this.isSaving = false,
    this.loadError,
    this.error,
    this.info,
  });

  final MaterialViewerStatus status;
  final CourseDetail? detail;

  /// Posisi materi yang sedang dibuka.
  final int index;
  final CourseProgress? progress;
  final bool isSaving;

  /// Error yang menggantikan seluruh halaman (gagal memuat).
  final String? loadError;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? error;
  final String? info;

  MaterialViewerState copyWith({
    MaterialViewerStatus? status,
    CourseDetail? detail,
    int? index,
    CourseProgress? progress,
    bool? isSaving,
    String? loadError,
    String? error,
    String? info,
  }) {
    return MaterialViewerState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      index: index ?? this.index,
      progress: progress ?? this.progress,
      isSaving: isSaving ?? this.isSaving,
      loadError: loadError ?? this.loadError,
      error: error,
      info: info,
    );
  }

  @override
  List<Object?> get props =>
      [status, detail, index, progress, isSaving, loadError, error, info];
}