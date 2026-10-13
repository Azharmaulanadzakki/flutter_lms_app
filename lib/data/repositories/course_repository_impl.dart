import '../../core/errors/failure_guard.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_material.dart';
import '../../domain/repositories/course_repository.dart';
import '../datasources/course_remote_datasource.dart';

class CourseRepositoryImpl implements CourseRepository {
  CourseRepositoryImpl(this._remote);

  final CourseRemoteDataSource _remote;

  @override
  Future<List<Course>> getPublishedCourses() =>
      guardFirebase<List<Course>>(_remote.getPublishedCourses);

  @override
  Future<Map<String, int>> getPublishedMaterialCounts() =>
      guardFirebase(_remote.getPublishedMaterialCounts);

  @override
  Future<Course> getCourseById(String courseId) =>
      guardFirebase<Course>(() => _remote.getCourseById(courseId));

  @override
  Future<List<CourseMaterial>> getPublishedMaterials(String courseId) =>
      guardFirebase<List<CourseMaterial>>(
        () => _remote.getPublishedMaterials(courseId),
      );
}