import '../../core/errors/failure_guard.dart';
import '../../domain/game/game_result_view.dart';
import '../../domain/game/game_run_entry.dart';
import '../../domain/repositories/game_results_repository.dart';
import '../datasources/game_results_remote_datasource.dart';

class GameResultsRepositoryImpl implements GameResultsRepository {
  GameResultsRepositoryImpl(this._remote);

  final GameResultsRemoteDataSource _remote;

  @override
  Future<void> submit(GameRunEntry entry) => _remote.submit(entry);

  @override
  Future<List<GameResultView>> resultsOf(String userId) =>
      guardFirebase<List<GameResultView>>(() => _remote.resultsOf(userId));
}