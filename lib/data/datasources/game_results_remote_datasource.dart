import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../domain/game/game_run_entry.dart';
import '../../domain/game/game_sync.dart';
import '../../domain/game/game_result_view.dart';

class GameResultsRemoteDataSource {
  GameResultsRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Membuat dokumen hasil hanya jika belum ada (idempoten). Jika run ini
  /// menyelesaikan simulasi course, progres course ikut diperbarui dalam
  /// transaksi yang sama. Transaksi butuh server, jadi saat offline langsung
  /// gagal dan tidak meninggalkan antrean tulis ganda di Firestore.
  Future<void> submit(GameRunEntry e) async {
    final resultRef = _db.collection(FirestorePaths.gameResults).doc(e.id);
    final progressRef = (e.completesCourseGame && e.courseId.isNotEmpty)
        ? _db
              .collection(FirestorePaths.courseProgress)
              .doc(FirestorePaths.progressId(e.userId, e.courseId))
        : null;

    try {
      await _db
          .runTransaction<void>(
            (tx) async {
              final existing = await tx.get(resultRef);
              if (existing.exists) return;

              tx.set(resultRef, {
                'userId': e.userId,
                'courseId': e.courseId,
                'missionId': e.missionId,
                'score': e.score,
                'durationSec': e.durationSec,
                'errors': e.mistakes,
                'status': e.status,
                'playedAt': Timestamp.fromDate(e.playedAt),
                'createdAt': FieldValue.serverTimestamp(),
                'solution': e.solution,
              });

              if (progressRef != null) {
                tx.set(progressRef, {
                  'userId': e.userId,
                  'courseId': e.courseId,
                  'gameCompleted': true,
                  'gameScore': e.courseGameScore ?? e.score,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            },
            timeout: const Duration(seconds: 12),
            maxAttempts: 2,
          )
          .timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const GameSyncException(
        GameSyncErrorKind.network,
        'Koneksi terlalu lama. Hasil akan dikirim saat internet stabil.',
      );
    } on FirebaseException catch (error) {
      throw _map(error);
    }
  }

  Future<List<GameResultView>> resultsOf(String userId) async {
    final snap = await _db
        .collection(FirestorePaths.gameResults)
        .where('userId', isEqualTo: userId)
        .get();

    final list = <GameResultView>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final played =
          (d['playedAt'] as Timestamp?)?.toDate() ??
          (d['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0);

      list.add(
        GameResultView(
          id: doc.id,
          missionId: (d['missionId'] as String?) ?? '',
          courseId: (d['courseId'] as String?) ?? '',
          score: (d['score'] as num?)?.toInt() ?? 0,
          errors: (d['errors'] as num?)?.toInt() ?? 0,
          durationSec: (d['durationSec'] as num?)?.toInt() ?? 0,
          completed: d['status'] == 'completed',
          playedAt: played,
        ),
      );
    }

    list.sort((a, b) => b.playedAt.compareTo(a.playedAt));
    return list;
  }

  GameSyncException _map(FirebaseException e) {
    switch (e.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'cancelled':
      case 'aborted':
      case 'unauthenticated':
      case 'network-request-failed':
        return const GameSyncException(
          GameSyncErrorKind.network,
          'Tidak ada koneksi ke server. Hasil akan dikirim saat online.',
        );
      case 'permission-denied':
      case 'invalid-argument':
      case 'failed-precondition':
        return GameSyncException(
          GameSyncErrorKind.rejected,
          'Server menolak hasil ini (${e.code}).',
        );
      default:
        return GameSyncException(
          GameSyncErrorKind.unknown,
          'Gagal mengirim hasil (${e.code}).',
        );
    }
  }
}
