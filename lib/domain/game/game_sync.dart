enum GameSyncErrorKind {
  /// Tidak ada koneksi atau server tidak terjangkau. Coba lagi nanti.
  network,

  /// Server menolak data ini.
  rejected,
  unknown,
}

class GameSyncException implements Exception {
  const GameSyncException(this.kind, this.message);

  final GameSyncErrorKind kind;
  final String message;

  @override
  String toString() => message;
}

/// Hasil satu kali sinkronisasi.
class SyncReport {
  const SyncReport({
    this.sent = 0,
    this.rejected = 0,
    this.remaining = 0,
    this.blocked = 0,
    this.offline = false,
    this.skipped = false,
    this.lastError,
  });

  final int sent;
  final int rejected;

  /// Entri yang masih menunggu dan belum diblokir.
  final int remaining;

  /// Entri yang diblokir setelah terlalu sering ditolak.
  final int blocked;
  final bool offline;

  /// True jika sinkronisasi lain sedang berjalan.
  final bool skipped;
  final String? lastError;

  /// Tidak ada lagi yang menunggu dikirim.
  bool get isClear => !skipped && !offline && remaining == 0;
}

class OutboxSummary {
  const OutboxSummary({this.pending = 0, this.blocked = 0});

  final int pending;
  final int blocked;
}
