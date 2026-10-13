import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/course_progress.dart';

class CourseProgressModel extends CourseProgress {
  const CourseProgressModel({
    required super.courseId,
    super.completedMaterialIds,
    super.materialProgress,
    super.preTestCompleted,
    super.gameCompleted,
    super.postTestCompleted,
    super.progressPercentage,
    super.preTestScore,
    super.postTestScore,
    super.startedAt,
    super.completedAt,
  });

  factory CourseProgressModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return CourseProgressModel(
      courseId: (d['courseId'] as String?) ?? '',
      completedMaterialIds: (d['completedMaterialIds'] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      materialProgress: (d['materialProgress'] as num?)?.toInt() ?? 0,
      preTestCompleted: (d['preTestCompleted'] as bool?) ?? false,
      gameCompleted: (d['gameCompleted'] as bool?) ?? false,
      postTestCompleted: (d['postTestCompleted'] as bool?) ?? false,
      progressPercentage: (d['progressPercentage'] as num?)?.toDouble() ?? 0,
      preTestScore: (d['preTestScore'] as num?)?.toDouble(),
      postTestScore: (d['postTestScore'] as num?)?.toDouble(),
      startedAt: (d['startedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }
}