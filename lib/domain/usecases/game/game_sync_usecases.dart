import '../../game/game_outbox_store.dart';
import '../../game/game_run_entry.dart';
import '../../game/game_sync.dart';
import '../../game/mission_record.dart';
import '../../repositories/game_results_repository.dart';
import 'game_usecases.dart';

class RunSubmission {
  const RunSubmission({
    this.record,
    this.queued = false,
    this.recordError,
    this.queueError,
  });

  /// Rekap lokal setelah run ini. Null jika gagal disimpan.
  final MissionRecord? record;

  /// True jika hasil masuk antrean pengiriman.
  final bool queued;
  final Object? recordError;
  final Object? queueError;
}

/// Menyimpan hasil run ke rekap lokal dan ke antrean pengiriman.
/// Keduanya dicoba terpisah: kegagalan satu tidak membatalkan yang lain.
class SubmitMissionRunUseCase {
  const SubmitMissionRunUseCase(this._recordRun, this._outbox);

  final RecordMissionRunUseCase _recordRun;
  final GameOutboxStore _outbox;

  Future<RunSubmission> call({
    required String userId,
    required RunSummary run,
    String courseId = '',
    Map<String, dynamic> solution = const {},
    bool completesCourseGame = false,
    double? courseGameScore,
  }) async {
    MissionRecord? record;
    Object? recordError;
    try {
      record = await _recordRun(userId, run);
    } catch (e) {
      recordError = e;
    }

    var queued = false;
    Object? queueError;
    try {
      await _outbox.add(
        userId,
        GameRunEntry.fromRun(
          userId: userId,
          run: run,
          courseId: courseId,
          solution: solution,
          completesCourseGame: completesCourseGame,
          courseGameScore: courseGameScore,
        ),
      );
      queued = true;
    } catch (e) {
      queueError = e;
    }

    return RunSubmission(
      record: record,
      queued: queued,
      recordError: recordError,
      queueError: queueError,
    );
  }
}

/// Mengirim antrean ke server, berurutan dari yang terlama.
class SyncGameResultsUseCase {
  SyncGameResultsUseCase(this._outbox, this._results);

  final GameOutboxStore _outbox;
  final GameResultsRepository _results;

  bool _busy = false;

  /// [retryBlocked]: entri yang diblokir dicoba lagi dari awal.
  Future<SyncReport> call(String userId, {bool retryBlocked = false}) async {
    if (_busy) return const SyncReport(skipped: true);
    _busy = true;
    try {
      return await _run(userId, retryBlocked);
    } finally {
      _busy = false;
    }
  }

  Future<SyncReport> _run(String userId, bool retryBlocked) async {
    var entries = await _outbox.readAll(userId);

    if (retryBlocked) {
      for (final e in entries) {
        if (e.isBlocked) await _outbox.update(userId, e.resetAttempts());
      }
      entries = await _outbox.readAll(userId);
    }

    var sent = 0;
    var rejected = 0;
    var offline = false;
    String? lastError;

    for (final entry in entries) {
      if (entry.isBlocked) continue;

      try {
        await _results.submit(entry);
        await _outbox.remove(userId, [entry.id]);
        sent++;
      } on GameSyncException catch (e) {
        lastError = e.message;

        if (e.kind == GameSyncErrorKind.network) {
          // Tidak ada koneksi: sisa antrean dibiarkan utuh dan dicoba nanti.
          offline = true;
          break;
        }
        rejected++;
        await _outbox.update(userId, entry.afterFailure(e.message));
      } catch (_) {
        lastError = 'Terjadi kesalahan tak terduga saat mengirim.';
        rejected++;
        await _outbox.update(userId, entry.afterFailure(lastError));
      }
    }

    final left = await _outbox.readAll(userId);
    return SyncReport(
      sent: sent,
      rejected: rejected,
      remaining: left.where((e) => !e.isBlocked).length,
      blocked: left.where((e) => e.isBlocked).length,
      offline: offline,
      lastError: lastError,
    );
  }
}

class GetOutboxSummaryUseCase {
  const GetOutboxSummaryUseCase(this._outbox);

  final GameOutboxStore _outbox;

  Future<OutboxSummary> call(String userId) async {
    final entries = await _outbox.readAll(userId);
    return OutboxSummary(
      pending: entries.where((e) => !e.isBlocked).length,
      blocked: entries.where((e) => e.isBlocked).length,
    );
  }
}
