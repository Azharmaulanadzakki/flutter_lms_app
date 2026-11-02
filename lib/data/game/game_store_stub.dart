import '../../domain/game/game_store.dart';
import '../../domain/game/mission_record.dart';

/// Versi web: game hanya tersedia di Android, jadi penyimpanan cukup di memori.
class PlatformGameStore implements GameLocalStore {
  static final Map<String, Map<String, MissionRecord>> _memory = {};

  @override
  Future<Map<String, MissionRecord>> load(String userId) async =>
      Map.of(_memory[userId] ?? const <String, MissionRecord>{});

  @override
  Future<void> save(String userId, Map<String, MissionRecord> records) async {
    _memory[userId] = Map.of(records);
  }
}
