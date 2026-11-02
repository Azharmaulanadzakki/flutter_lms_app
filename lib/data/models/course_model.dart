import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/course.dart';

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.title,
    required super.description,
    required super.thumbnailUrl,
    required super.level,
    required super.duration,
    required super.order,
    super.objectives,
    super.hasGame,
    super.missionIds,
    super.isPublished,
  });

  factory CourseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return CourseModel(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      thumbnailUrl: (d['thumbnailUrl'] as String?) ?? '',
      level: (d['level'] as String?) ?? 'Dasar',
      duration: (d['duration'] as num?)?.toInt() ?? 0,
      order: (d['order'] as num?)?.toInt() ?? 0,
      objectives:
          (d['objectives'] as List?)?.whereType<String>().toList() ?? const [],
      hasGame: (d['hasGame'] as bool?) ?? false,
      missionIds:
          (d['missionIds'] as List?)?.whereType<String>().toList() ?? const [],
      isPublished: (d['isPublished'] as bool?) ?? false,
    );
  }
}
