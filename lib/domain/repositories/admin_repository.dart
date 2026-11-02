import '../entities/admin_entities.dart';
import '../entities/course.dart';
import '../entities/course_material.dart';
import '../entities/progress_weights.dart';
import '../entities/quiz_test.dart';
import '../entities/user_entity.dart';

abstract class AdminRepository {
  // Siswa dan progress
  Future<List<UserEntity>> getStudents();
  Future<UserEntity> getUser(String uid);
  Future<List<StudentProgressRecord>> getAllProgress();

  // Course (termasuk yang belum dipublikasikan)
  Future<List<Course>> getAllCourses();
  Future<Course> getCourse(String courseId);

  /// Mengembalikan ID course. Jika `course.id` kosong, course baru dibuat.
  Future<String> saveCourse(Course course);
  Future<void> setCoursePublished(String courseId, bool published);
  Future<void> deleteCourse(String courseId);

  // Materi
  Future<List<CourseMaterial>> getAllMaterials();
  Future<List<CourseMaterial>> getMaterials(String courseId);
  Future<CourseMaterial> getMaterial(String materialId);

  /// Jika `material.id` kosong, materi baru dibuat.
  Future<void> saveMaterial(CourseMaterial material);
  Future<void> setMaterialPublished(String materialId, bool published);
  Future<void> deleteMaterial(String materialId);

  // Test
  Future<List<QuizTest>> getTests(String courseId);
  Future<QuizTest?> getTest(String testId);
  Future<int> countQuestions(String testId);
  Future<void> saveTest(QuizTest test);
  Future<void> setTestActive(String testId, bool active);
  Future<void> deleteTest(String testId);

  // Pengaturan
  Future<void> saveProgressWeights(ProgressWeights weights);
}
