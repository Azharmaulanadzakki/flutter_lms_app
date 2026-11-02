import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/game/game_store.dart';
import '../../domain/game/mission_record.dart';

/// Menyimpan progres sebagai berkas JSON di folder dokumen aplikasi.
class PlatformGameStore implements GameLocalStore {
  Future<File> _file(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/game_progress_$safe.json');
  }

  @override
  Future<Map<String, MissionRecord>> load(String userId) async {
    final file = await _file(userId);
    if (!await file.exists()) return {};

    final text = await file.readAsString();

    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return {};
      final raw = decoded['records'];
      if (raw is! Map) return {};

      final out = <String, MissionRecord>{};
      for (final value in raw.values) {
        final record = MissionRecord.tryFromJson(value);
        if (record != null) out[record.missionId] = record;
      }
      return out;
    } on FormatException {
      // Berkas rusak dianggap kosong dan akan ditimpa saat menyimpan.
      return {};
    }
  }

  @override
  Future<void> save(String userId, Map<String, MissionRecord> records) async {
    final file = await _file(userId);
    final temp = File('${file.path}.tmp');

    final text = jsonEncode({
      'version': 1,
      'records': {for (final e in records.entries) e.key: e.value.toJson()},
    });

    // Tulis ke berkas sementara dulu, supaya berkas lama tidak setengah tertimpa.
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
  }
}
