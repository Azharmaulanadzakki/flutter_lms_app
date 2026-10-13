import 'package:equatable/equatable.dart';

import 'course_item.dart';
import 'course_material.dart';

class CourseDetail extends Equatable {
  const CourseDetail({required this.item, required this.materials});

  final CourseItem item;

  /// Materi published, terurut berdasarkan `order`.
  final List<CourseMaterial> materials;

  @override
  List<Object?> get props => [item, materials];
}