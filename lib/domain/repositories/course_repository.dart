import '../entities/course.dart';
import '../entities/course_material.dart';

abstract class CourseRepository {
  /// Course published, terurut berdasarkan `order`.
  Future<List<Course>> getPublishedCourses();

  /// courseId -> jumlah materi yang published.
  Future<Map<String, int>> getPublishedMaterialCounts();

  /// Satu course published. Melempar Failure jika tidak tersedia.
  Future<Course> getCourseById(String courseId);

  /// Materi published milik course, terurut berdasarkan `order`.
  Future<List<CourseMaterial>> getPublishedMaterials(String courseId);
}