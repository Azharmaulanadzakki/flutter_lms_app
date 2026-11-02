import '../../domain/game/game_outbox_store.dart';
import '../../domain/game/game_run_entry.dart';

/// Versi web: game hanya tersedia di Android, jadi antrean cukup di memori.
class PlatformGameOutboxStore implements GameOutboxStore {
  static final Map<String, List<GameRunEntry>> _memory = {};

  List<GameRunEntry> _list(String userId) =>
      _memory.putIfAbsent(userId, () => <GameRunEntry>[]);

  @override
  Future<List<GameRunEntry>> readAll(String userId) async => [..._list(userId)];

  @override
  Future<void> add(String userId, GameRunEntry entry) async {
    final list = _list(userId);
    if (list.every((e) => e.id != entry.id)) list.add(entry);
  }

  @override
  Future<void> update(String userId, GameRunEntry entry) async {
    final list = _list(userId);
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index >= 0) list[index] = entry;
  }

  @override
  Future<void> remove(String userId, Iterable<String> ids) async {
    final drop = ids.toSet();
    _list(userId).removeWhere((e) => drop.contains(e.id));
  }
}
