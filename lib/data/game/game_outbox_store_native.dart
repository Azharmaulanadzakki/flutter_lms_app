import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/game/game_outbox_store.dart';
import '../../domain/game/game_run_entry.dart';

/// Antrean sebagai berkas JSON di folder dokumen aplikasi. Semua operasi
/// diserialkan supaya baca-ubah-tulis tidak saling menimpa.
class PlatformGameOutboxStore implements GameOutboxStore {
  Future<void> _tail = Future<void>.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<File> _file(String userId) async {
    final dir = await getApplicationDocumentsDirectory();
    final safe = userId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return File('${dir.path}/game_outbox_$safe.json');
  }

  Future<List<GameRunEntry>> _read(String userId) async {
    final file = await _file(userId);
    if (!await file.exists()) return [];

    final text = await file.readAsString();

    try {
      final decoded = jsonDecode(text);
      final raw = decoded is Map ? decoded['entries'] : null;
      if (raw is! List)
        throw const FormatException('Bentuk berkas tidak dikenal');

      final out = <GameRunEntry>[];
      for (final item in raw) {
        final entry = GameRunEntry.tryFromJson(item);
        if (entry != null) out.add(entry);
      }
      return out;
    } on FormatException {
      // Berkas rusak disimpan sebagai cadangan, bukan dihapus diam-diam.
      final backup = File(
        '${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}',
      );
      await file.rename(backup.path);
      return [];
    }
  }

  Future<void> _write(String userId, List<GameRunEntry> entries) async {
    final file = await _file(userId);
    final temp = File('${file.path}.tmp');

    final text = jsonEncode({
      'version': 1,
      'entries': [for (final e in entries) e.toJson()],
    });

    // Tulis ke berkas sementara dulu, supaya berkas lama tidak setengah tertimpa.
    await temp.writeAsString(text, flush: true);
    await temp.rename(file.path);
  }

  @override
  Future<List<GameRunEntry>> readAll(String userId) =>
      _locked(() => _read(userId));

  @override
  Future<void> add(String userId, GameRunEntry entry) => _locked(() async {
    final list = await _read(userId);
    if (list.any((e) => e.id == entry.id)) return;
    list.add(entry);
    await _write(userId, list);
  });

  @override
  Future<void> update(String userId, GameRunEntry entry) => _locked(() async {
    final list = await _read(userId);
    final index = list.indexWhere((e) => e.id == entry.id);
    if (index < 0) return;
    list[index] = entry;
    await _write(userId, list);
  });

  @override
  Future<void> remove(String userId, Iterable<String> ids) => _locked(() async {
    final drop = ids.toSet();
    final list = await _read(userId);
    final kept = list.where((e) => !drop.contains(e.id)).toList();
    if (kept.length != list.length) await _write(userId, kept);
  });
}
