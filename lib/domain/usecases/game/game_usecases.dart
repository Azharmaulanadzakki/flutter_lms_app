import '../../game/game_store.dart';
import '../../game/mission_record.dart';

class LoadGameProgressUseCase {
  const LoadGameProgressUseCase(this._store);

  final GameLocalStore _store;

  Future<GameProgress> call(String userId) async =>
      GameProgress(await _store.load(userId));
}

/// Menambahkan satu hasil ke rekap misi, lalu menyimpannya.
/// Gagal membaca berkas berarti gagal menyimpan, supaya data lama
/// tidak tertimpa oleh rekap kosong.
class RecordMissionRunUseCase {
  const RecordMissionRunUseCase(this._store);

  final GameLocalStore _store;

  Future<MissionRecord> call(String userId, RunSummary run) async {
    final records = Map<String, MissionRecord>.of(await _store.load(userId));
    final current =
        records[run.missionId] ?? MissionRecord(missionId: run.missionId);
    final updated = current.afterRun(run);
    records[run.missionId] = updated;
    await _store.save(userId, records);
    return updated;
  }
}
