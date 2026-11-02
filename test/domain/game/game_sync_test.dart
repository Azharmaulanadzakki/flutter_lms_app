import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/game_outbox_store.dart';
import 'package:smk_tkj_lms/domain/game/game_run_entry.dart';
import 'package:smk_tkj_lms/domain/game/game_store.dart';
import 'package:smk_tkj_lms/domain/game/game_sync.dart';
import 'package:smk_tkj_lms/domain/game/mission_record.dart';
import 'package:smk_tkj_lms/domain/repositories/game_results_repository.dart';
import 'package:smk_tkj_lms/domain/usecases/game/game_sync_usecases.dart';
import 'package:smk_tkj_lms/domain/usecases/game/game_usecases.dart';
import 'package:smk_tkj_lms/domain/game/game_result_view.dart';

class FakeRecordStore implements GameLocalStore {
  Map<String, MissionRecord> data = {};
  bool failLoad = false;

  @override
  Future<Map<String, MissionRecord>> load(String userId) async {
    if (failLoad) throw Exception('gagal baca');
    return Map.of(data);
  }

  @override
  Future<void> save(String userId, Map<String, MissionRecord> records) async {
    data = Map.of(records);
  }
}

class FakeOutbox implements GameOutboxStore {
  final List<GameRunEntry> entries = [];
  bool failAdd = false;

  @override
  Future<List<GameRunEntry>> readAll(String userId) async => [...entries];

  @override
  Future<void> add(String userId, GameRunEntry entry) async {
    if (failAdd) throw Exception('gagal tulis');
    if (entries.every((e) => e.id != entry.id)) entries.add(entry);
  }

  @override
  Future<void> update(String userId, GameRunEntry entry) async {
    final i = entries.indexWhere((e) => e.id == entry.id);
    if (i >= 0) entries[i] = entry;
  }

  @override
  Future<void> remove(String userId, Iterable<String> ids) async {
    final drop = ids.toSet();
    entries.removeWhere((e) => drop.contains(e.id));
  }
}

class FakeResults implements GameResultsRepository {
  final List<String> sent = [];
  final List<String> attempted = [];
  Future<void> Function(GameRunEntry entry)? handler;

  @override
  Future<void> submit(GameRunEntry entry) async {
    attempted.add(entry.id);
    final h = handler;
    if (h != null) await h(entry);
    sent.add(entry.id);
  }

  @override
  Future<List<GameResultView>> resultsOf(String userId) async => const [];
}

GameRunEntry entry(int n, {int attempts = 0}) => GameRunEntry(
  id: 'u1_m1_$n',
  userId: 'u1',
  missionId: 'm1-auto-lamp',
  score: 90,
  completed: true,
  mistakes: 0,
  durationSec: 30,
  playedAt: DateTime.utc(2026, 1, 1, 0, 0, n),
  attempts: attempts,
);

RunSummary summary({int score = 90, bool completed = true}) => RunSummary(
  missionId: 'm1-auto-lamp',
  score: score,
  completed: completed,
  mistakes: 1,
  durationSec: 45,
  at: DateTime.utc(2026, 2, 3, 4, 5, 6),
);

void main() {
  group('GameRunEntry', () {
    test('ID dibentuk dari pemain, misi, dan waktu main', () {
      final at = DateTime.utc(2026, 2, 3, 4, 5, 6);
      expect(
        GameRunEntry.idFor('u1', 'm1-auto-lamp', at),
        'u1_m1-auto-lamp_${at.millisecondsSinceEpoch}',
      );
    });

    test('JSON bolak-balik mempertahankan isi', () {
      final original = GameRunEntry.fromRun(
        userId: 'u1',
        run: summary(),
        courseId: 'c1',
        solution: {
          'circuit': {
            'installed': {'lamp1': 'hall_ceiling'},
          },
          'rules': [
            {'conditions': [], 'then': []},
          ],
        },
        completesCourseGame: true,
        courseGameScore: 88.5,
      ).afterFailure('galat');

      final restored = GameRunEntry.tryFromJson(
        jsonDecode(jsonEncode(original.toJson())),
      );

      expect(restored, isNotNull);
      expect(restored!.id, original.id);
      expect(restored.courseId, 'c1');
      expect(restored.score, 90);
      expect(restored.mistakes, 1);
      expect(restored.completesCourseGame, isTrue);
      expect(restored.courseGameScore, 88.5);
      expect(restored.attempts, 1);
      expect(restored.lastError, 'galat');
      expect(restored.solution['circuit'], original.solution['circuit']);
      expect(
        restored.playedAt.millisecondsSinceEpoch,
        original.playedAt.millisecondsSinceEpoch,
      );
    });

    test('data tidak lengkap menghasilkan null', () {
      expect(GameRunEntry.tryFromJson('x'), isNull);
      expect(GameRunEntry.tryFromJson({'id': 'a'}), isNull);
      expect(
        GameRunEntry.tryFromJson({
          'id': 'a',
          'userId': 'u',
          'missionId': 'm',
          'playedAt': 'bukan tanggal',
        }),
        isNull,
      );
    });

    test('nilai di luar batas dirapikan', () {
      final e = GameRunEntry.tryFromJson({
        'id': 'a',
        'userId': 'u',
        'missionId': 'm',
        'playedAt': '2026-01-01T00:00:00Z',
        'score': 500,
        'mistakes': -3,
        'attempts': -1,
      });
      expect(e!.score, 100);
      expect(e.mistakes, 0);
      expect(e.attempts, 0);
    });

    test('status, pemblokiran, dan reset percobaan', () {
      expect(entry(1).status, 'completed');
      expect(entry(1).isBlocked, isFalse);
      expect(entry(1, attempts: 5).isBlocked, isTrue);
      expect(entry(1, attempts: 5).resetAttempts().isBlocked, isFalse);
      expect(entry(1, attempts: 5).resetAttempts().lastError, isNull);
    });
  });

  group('SubmitMissionRunUseCase', () {
    test('hasil masuk rekap lokal dan antrean', () async {
      final store = FakeRecordStore();
      final outbox = FakeOutbox();
      final useCase = SubmitMissionRunUseCase(
        RecordMissionRunUseCase(store),
        outbox,
      );

      final result = await useCase(
        userId: 'u1',
        run: summary(),
        solution: const {'rules': []},
      );

      expect(result.record?.bestScore, 90);
      expect(result.queued, isTrue);
      expect(store.data['m1-auto-lamp']!.completed, isTrue);
      expect(outbox.entries.length, 1);
      expect(outbox.entries.first.id, startsWith('u1_m1-auto-lamp_'));
    });

    test('rekap lokal gagal tetapi antrean tetap terisi', () async {
      final store = FakeRecordStore()..failLoad = true;
      final outbox = FakeOutbox();
      final useCase = SubmitMissionRunUseCase(
        RecordMissionRunUseCase(store),
        outbox,
      );

      final result = await useCase(userId: 'u1', run: summary());
      expect(result.record, isNull);
      expect(result.recordError, isNotNull);
      expect(result.queued, isTrue);
    });

    test('antrean gagal tetapi rekap lokal tetap tersimpan', () async {
      final store = FakeRecordStore();
      final outbox = FakeOutbox()..failAdd = true;
      final useCase = SubmitMissionRunUseCase(
        RecordMissionRunUseCase(store),
        outbox,
      );

      final result = await useCase(userId: 'u1', run: summary());
      expect(result.record, isNotNull);
      expect(result.queued, isFalse);
      expect(result.queueError, isNotNull);
    });
  });

  group('SyncGameResultsUseCase', () {
    late FakeOutbox outbox;
    late FakeResults results;
    late SyncGameResultsUseCase sync;

    setUp(() {
      outbox = FakeOutbox();
      results = FakeResults();
      sync = SyncGameResultsUseCase(outbox, results);
    });

    test('antrean kosong tidak menyentuh server', () async {
      final report = await sync('u1');
      expect(report.sent, 0);
      expect(report.isClear, isTrue);
      expect(results.attempted, isEmpty);
    });

    test('semua terkirim berurutan dan antrean kosong', () async {
      outbox.entries.addAll([entry(1), entry(2), entry(3)]);

      final report = await sync('u1');

      expect(report.sent, 3);
      expect(report.isClear, isTrue);
      expect(results.sent, ['u1_m1_1', 'u1_m1_2', 'u1_m1_3']);
      expect(outbox.entries, isEmpty);
    });

    test(
      'offline: berhenti di galat jaringan dan sisanya tidak disentuh',
      () async {
        outbox.entries.addAll([entry(1), entry(2), entry(3)]);
        results.handler = (e) async {
          if (e.id == 'u1_m1_2') {
            throw const GameSyncException(GameSyncErrorKind.network, 'offline');
          }
        };

        final report = await sync('u1');

        expect(report.sent, 1);
        expect(report.offline, isTrue);
        expect(report.isClear, isFalse);
        expect(report.remaining, 2);
        expect(results.attempted, ['u1_m1_1', 'u1_m1_2']);
        expect(outbox.entries.map((e) => e.id), ['u1_m1_2', 'u1_m1_3']);
        // Galat jaringan tidak menghitung sebagai percobaan ditolak.
        expect(outbox.entries.first.attempts, 0);
      },
    );

    test('ditolak server: dihitung, entri lain tetap dikirim', () async {
      outbox.entries.addAll([entry(1), entry(2), entry(3)]);
      results.handler = (e) async {
        if (e.id == 'u1_m1_2') {
          throw const GameSyncException(GameSyncErrorKind.rejected, 'ditolak');
        }
      };

      final report = await sync('u1');

      expect(report.sent, 2);
      expect(report.rejected, 1);
      expect(report.remaining, 1);
      expect(report.lastError, 'ditolak');
      expect(outbox.entries.single.id, 'u1_m1_2');
      expect(outbox.entries.single.attempts, 1);
      expect(outbox.entries.single.lastError, 'ditolak');
    });

    test(
      'setelah terlalu sering ditolak, entri diblokir dan dilewati',
      () async {
        outbox.entries.add(entry(1, attempts: GameRunEntry.maxAttempts - 1));
        results.handler = (_) async => throw const GameSyncException(
          GameSyncErrorKind.rejected,
          'ditolak',
        );

        final first = await sync('u1');
        expect(first.blocked, 1);
        expect(first.remaining, 0);
        expect(outbox.entries.single.isBlocked, isTrue);

        results.attempted.clear();
        final second = await sync('u1');
        expect(results.attempted, isEmpty);
        expect(second.blocked, 1);
        expect(outbox.entries.length, 1);
      },
    );

    test('mencoba ulang entri yang diblokir bila diminta', () async {
      outbox.entries.add(entry(1, attempts: GameRunEntry.maxAttempts));

      final report = await sync('u1', retryBlocked: true);

      expect(report.sent, 1);
      expect(report.blocked, 0);
      expect(outbox.entries, isEmpty);
    });

    test('galat tak terduga dihitung sebagai percobaan gagal', () async {
      outbox.entries.addAll([entry(1), entry(2)]);
      results.handler = (e) async {
        if (e.id == 'u1_m1_1') throw StateError('aneh');
      };

      final report = await sync('u1');

      expect(report.sent, 1);
      expect(report.rejected, 1);
      expect(outbox.entries.single.attempts, 1);
    });

    test('dua sinkronisasi bersamaan: yang kedua dilewati', () async {
      outbox.entries.add(entry(1));
      final gate = Completer<void>();
      results.handler = (_) => gate.future;

      final first = sync('u1');
      final second = await sync('u1');
      expect(second.skipped, isTrue);

      gate.complete();
      final firstReport = await first;
      expect(firstReport.sent, 1);
      expect(firstReport.skipped, isFalse);

      // Setelah selesai, sinkronisasi berikutnya berjalan normal lagi.
      expect((await sync('u1')).skipped, isFalse);
    });

    test('ringkasan antrean membedakan menunggu dan diblokir', () async {
      outbox.entries.addAll([entry(1), entry(2, attempts: 5)]);
      final summary = await GetOutboxSummaryUseCase(outbox)('u1');
      expect(summary.pending, 1);
      expect(summary.blocked, 1);
    });
  });
}
