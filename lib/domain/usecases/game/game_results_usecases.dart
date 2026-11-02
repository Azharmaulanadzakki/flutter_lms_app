import '../../game/game_result_view.dart';
import '../../repositories/game_results_repository.dart';

class GetStudentGameResultsUseCase {
  const GetStudentGameResultsUseCase(this._repo);

  final GameResultsRepository _repo;

  Future<List<GameResultView>> call(String userId) => _repo.resultsOf(userId);
}
