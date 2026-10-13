import 'package:equatable/equatable.dart';

class CourseProgress extends Equatable {
  const CourseProgress({
    required this.courseId,
    this.completedMaterialIds = const [],
    this.materialProgress = 0,
    this.preTestCompleted = false,
    this.gameCompleted = false,
    this.postTestCompleted = false,
    this.progressPercentage = 0,
    this.preTestScore,
    this.postTestScore,
    this.startedAt,
    this.completedAt,
  });

  final String courseId;

  /// ID materi yang sudah ditandai selesai.
  final List<String> completedMaterialIds;

  /// Jumlah materi yang sudah selesai.
  final int materialProgress;
  final bool preTestCompleted;
  final bool gameCompleted;
  final bool postTestCompleted;
  final double progressPercentage;
  final double? preTestScore;
  final double? postTestScore;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get isCompleted => completedAt != null || progressPercentage >= 100;
  bool get isStarted => progressPercentage > 0 || startedAt != null;

  CourseProgress copyWith({
    List<String>? completedMaterialIds,
    int? materialProgress,
    bool? preTestCompleted,
    bool? gameCompleted,
    bool? postTestCompleted,
    double? progressPercentage,
    double? preTestScore,
    double? postTestScore,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return CourseProgress(
      courseId: courseId,
      completedMaterialIds: completedMaterialIds ?? this.completedMaterialIds,
      materialProgress: materialProgress ?? this.materialProgress,
      preTestCompleted: preTestCompleted ?? this.preTestCompleted,
      gameCompleted: gameCompleted ?? this.gameCompleted,
      postTestCompleted: postTestCompleted ?? this.postTestCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      preTestScore: preTestScore ?? this.preTestScore,
      postTestScore: postTestScore ?? this.postTestScore,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [
        courseId,
        completedMaterialIds,
        materialProgress,
        preTestCompleted,
        gameCompleted,
        postTestCompleted,
        progressPercentage,
        preTestScore,
        postTestScore,
        startedAt,
        completedAt,
      ];
}