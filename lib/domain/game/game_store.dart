import 'mission_record.dart';

/// Penyimpanan progres game di perangkat. Berjalan tanpa internet.
abstract class GameLocalStore {
  /// Melempar exception jika berkas gagal dibaca. Berkas yang rusak
  /// dianggap kosong.
  Future<Map<String, MissionRecord>> load(String userId);

  Future<void> save(String userId, Map<String, MissionRecord> records);
}
