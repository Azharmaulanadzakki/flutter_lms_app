import '../../core/errors/failure_guard.dart';
import '../../domain/entities/admin_entities.dart';
import '../../domain/entities/course.dart';
import '../../domain/entities/course_material.dart';
import '../../domain/entities/progress_weights.dart';
import '../../domain/entities/quiz_test.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<List<UserEntity>> getStudents() =>
      guardFirebase<List<UserEntity>>(_remote.getStudents);

  @override
  Future<UserEntity> getUser(String uid) =>
      guardFirebase<UserEntity>(() => _remote.getUser(uid));

  @override
  Future<List<StudentProgressRecord>> getAllProgress() =>
      guardFirebase<List<StudentProgressRecord>>(_remote.getAllProgress);

  @override
  Future<List<Course>> getAllCourses() =>
      guardFirebase<List<Course>>(_remote.getAllCourses);

  @override
  Future<Course> getCourse(String courseId) =>
      guardFirebase<Course>(() => _remote.getCourse(courseId));

  @override
  Future<String> saveCourse(Course course) =>
      guardFirebase<String>(() => _remote.saveCourse(course));

  @override
  Future<void> setCoursePublished(String courseId, bool published) =>
      guardFirebase<void>(
        () => _remote.setCoursePublished(courseId, published),
      );

  @override
  Future<void> deleteCourse(String courseId) =>
      guardFirebase<void>(() => _remote.deleteCourse(courseId));

  @override
  Future<List<CourseMaterial>> getAllMaterials() =>
      guardFirebase<List<CourseMaterial>>(_remote.getAllMaterials);

  @override
  Future<List<CourseMaterial>> getMaterials(String courseId) =>
      guardFirebase<List<CourseMaterial>>(() => _remote.getMaterials(courseId));

  @override
  Future<CourseMaterial> getMaterial(String materialId) =>
      guardFirebase<CourseMaterial>(() => _remote.getMaterial(materialId));

  @override
  Future<void> saveMaterial(CourseMaterial material) =>
      guardFirebase<void>(() => _remote.saveMaterial(material));

  @override
  Future<void> setMaterialPublished(String materialId, bool published) =>
      guardFirebase<void>(
        () => _remote.setMaterialPublished(materialId, published),
      );

  @override
  Future<void> deleteMaterial(String materialId) =>
      guardFirebase<void>(() => _remote.deleteMaterial(materialId));

  @override
  Future<List<QuizTest>> getTests(String courseId) =>
      guardFirebase<List<QuizTest>>(() => _remote.getTests(courseId));

  @override
  Future<QuizTest?> getTest(String testId) =>
      guardFirebase<QuizTest?>(() => _remote.getTest(testId));

  @override
  Future<int> countQuestions(String testId) =>
      guardFirebase<int>(() => _remote.countQuestions(testId));

  @override
  Future<void> saveTest(QuizTest test) =>
      guardFirebase<void>(() => _remote.saveTest(test));

  @override
  Future<void> setTestActive(String testId, bool active) =>
      guardFirebase<void>(() => _remote.setTestActive(testId, active));

  @override
  Future<void> deleteTest(String testId) =>
      guardFirebase<void>(() => _remote.deleteTest(testId));

  @override
  Future<void> saveProgressWeights(ProgressWeights weights) =>
      guardFirebase<void>(() => _remote.saveProgressWeights(weights));
}
