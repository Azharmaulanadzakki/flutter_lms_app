import 'game_run_entry.dart';

/// Antrean hasil game di perangkat. Berjalan tanpa internet.
abstract class GameOutboxStore {
  Future<List<GameRunEntry>> readAll(String userId);

  /// Entri dengan ID yang sudah ada diabaikan.
  Future<void> add(String userId, GameRunEntry entry);

  Future<void> update(String userId, GameRunEntry entry);

  Future<void> remove(String userId, Iterable<String> ids);
}
