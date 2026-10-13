import '../../core/errors/failure_guard.dart';
import '../../domain/entities/test_attempt.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._remote);

  final HistoryRemoteDataSource _remote;

  @override
  Future<List<TestAttempt>> getGradedAttempts(String userId) =>
      guardFirebase<List<TestAttempt>>(
        () => _remote.getGradedAttempts(userId),
      );
}