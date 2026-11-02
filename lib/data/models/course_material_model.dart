import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/course_material.dart';

class CourseMaterialModel extends CourseMaterial {
  const CourseMaterialModel({
    required super.id,
    required super.courseId,
    required super.title,
    required super.content,
    required super.type,
    required super.mediaUrl,
    required super.order,
    super.isPublished,
  });

  factory CourseMaterialModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    return CourseMaterialModel(
      id: doc.id,
      courseId: (d['courseId'] as String?) ?? '',
      title: (d['title'] as String?) ?? '',
      content: (d['content'] as String?) ?? '',
      type: _parseType(d['type'] as String?),
      mediaUrl: (d['mediaUrl'] as String?) ?? '',
      order: (d['order'] as num?)?.toInt() ?? 0,
      isPublished: (d['isPublished'] as bool?) ?? false,
    );
  }

  static MaterialKind _parseType(String? value) {
    switch (value) {
      case 'video':
        return MaterialKind.video;
      case 'pdf':
        return MaterialKind.pdf;
      default:
        return MaterialKind.text;
    }
  }
}