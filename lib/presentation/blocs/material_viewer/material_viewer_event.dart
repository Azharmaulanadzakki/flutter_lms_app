part of 'material_viewer_bloc.dart';

sealed class MaterialViewerEvent extends Equatable {
  const MaterialViewerEvent();

  @override
  List<Object?> get props => [];
}

final class MaterialViewerStarted extends MaterialViewerEvent {
  const MaterialViewerStarted({
    required this.userId,
    required this.courseId,
    required this.materialId,
  });

  final String userId;
  final String courseId;
  final String materialId;

  @override
  List<Object?> get props => [userId, courseId, materialId];
}

final class MaterialViewerNext extends MaterialViewerEvent {
  const MaterialViewerNext();
}

final class MaterialViewerPrevious extends MaterialViewerEvent {
  const MaterialViewerPrevious();
}

final class MaterialViewerCompleteRequested extends MaterialViewerEvent {
  const MaterialViewerCompleteRequested();
}