import '../game/game_result_view.dart';
import '../game/game_run_entry.dart';

abstract class GameResultsRepository {
  /// Mengirim satu hasil ke server. Aman dipanggil ulang untuk entri yang sama.
  /// Melempar GameSyncException.
  Future<void> submit(GameRunEntry entry);

  /// Semua hasil seorang siswa di server, terbaru di atas.
  Future<List<GameResultView>> resultsOf(String userId);
}