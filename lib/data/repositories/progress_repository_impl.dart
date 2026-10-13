import '../../core/errors/failure_guard.dart';
import '../../domain/entities/course_progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_remote_datasource.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._remote);

  final ProgressRemoteDataSource _remote;

  @override
  Future<Map<String, CourseProgress>> getUserProgress(String userId) =>
      guardFirebase<Map<String, CourseProgress>>(
        () => _remote.getUserProgress(userId),
      );

  @override
  Future<void> saveMaterialProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  }) =>
      guardFirebase(
        () => _remote.saveMaterialProgress(
          userId: userId,
          progress: progress,
          setStartedAt: setStartedAt,
          setCompletedAt: setCompletedAt,
        ),
      );

  @override
  Future<void> savePreTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
  }) =>
      guardFirebase(
        () => _remote.savePreTestProgress(
          userId: userId,
          progress: progress,
          setStartedAt: setStartedAt,
        ),
      );

  @override
  Future<void> savePostTestProgress({
    required String userId,
    required CourseProgress progress,
    required bool setStartedAt,
    required bool setCompletedAt,
  }) =>
      guardFirebase(
        () => _remote.savePostTestProgress(
          userId: userId,
          progress: progress,
          setStartedAt: setStartedAt,
          setCompletedAt: setCompletedAt,
        ),
      );
}