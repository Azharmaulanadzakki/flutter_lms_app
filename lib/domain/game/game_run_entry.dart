import 'dart:math' as math;

import 'mission_record.dart';

/// Satu hasil permainan yang menunggu dikirim ke server.
class GameRunEntry {
  const GameRunEntry({
    required this.id,
    required this.userId,
    required this.missionId,
    this.courseId = '',
    required this.score,
    required this.completed,
    required this.mistakes,
    required this.durationSec,
    required this.playedAt,
    this.solution = const {},
    this.completesCourseGame = false,
    this.courseGameScore,
    this.attempts = 0,
    this.lastError,
  });

  factory GameRunEntry.fromRun({
    required String userId,
    required RunSummary run,
    String courseId = '',
    Map<String, dynamic> solution = const {},
    bool completesCourseGame = false,
    double? courseGameScore,
  }) {
    return GameRunEntry(
      id: idFor(userId, run.missionId, run.at),
      userId: userId,
      missionId: run.missionId,
      courseId: courseId,
      score: math.max(0, math.min(100, run.score)),
      completed: run.completed,
      mistakes: math.max(0, run.mistakes),
      durationSec: math.max(0, run.durationSec),
      playedAt: run.at,
      solution: solution,
      completesCourseGame: completesCourseGame,
      courseGameScore: courseGameScore,
    );
  }

  /// Setelah sekian kali ditolak server, entri diblokir (tetap tersimpan).
  static const int maxAttempts = 5;

  /// ID dokumen di Firestore. Sama untuk run yang sama, jadi aman dikirim ulang.
  static String idFor(String userId, String missionId, DateTime at) =>
      '${userId}_${missionId}_${at.millisecondsSinceEpoch}';

  final String id;
  final String userId;
  final String missionId;

  /// Kosong jika dimainkan di luar course.
  final String courseId;
  final int score;
  final bool completed;
  final int mistakes;
  final int durationSec;
  final DateTime playedAt;

  /// Rangkaian dan aturan pemain, untuk verifikasi ulang oleh mesin simulasi.
  final Map<String, dynamic> solution;

  /// Jika true, pengiriman ini juga menandai simulasi course selesai.
  final bool completesCourseGame;
  final double? courseGameScore;
  final int attempts;
  final String? lastError;

  String get status => completed ? 'completed' : 'failed';

  bool get isBlocked => attempts >= maxAttempts;

  GameRunEntry afterFailure(String error) =>
      _copy(attempts: attempts + 1, lastError: error);

  GameRunEntry resetAttempts() => _copy(attempts: 0, clearError: true);

  GameRunEntry _copy({
    int? attempts,
    String? lastError,
    bool clearError = false,
  }) {
    return GameRunEntry(
      id: id,
      userId: userId,
      missionId: missionId,
      courseId: courseId,
      score: score,
      completed: completed,
      mistakes: mistakes,
      durationSec: durationSec,
      playedAt: playedAt,
      solution: solution,
      completesCourseGame: completesCourseGame,
      courseGameScore: courseGameScore,
      attempts: attempts ?? this.attempts,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'missionId': missionId,
    'courseId': courseId,
    'score': score,
    'completed': completed,
    'mistakes': mistakes,
    'durationSec': durationSec,
    'playedAt': playedAt.toUtc().toIso8601String(),
    'solution': solution,
    'completesCourseGame': completesCourseGame,
    'courseGameScore': courseGameScore,
    'attempts': attempts,
    'lastError': lastError,
  };

  /// Null jika data tidak lengkap. Nilai di luar batas dirapikan.
  static GameRunEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;

    final id = json['id'];
    final userId = json['userId'];
    final missionId = json['missionId'];
    final playedRaw = json['playedAt'];

    if (id is! String || id.isEmpty) return null;
    if (userId is! String || userId.isEmpty) return null;
    if (missionId is! String || missionId.isEmpty) return null;
    if (playedRaw is! String) return null;

    final playedAt = DateTime.tryParse(playedRaw);
    if (playedAt == null) return null;

    int intOf(Object? v, int fallback) => v is num ? v.toInt() : fallback;

    final solution = json['solution'];
    final courseScore = json['courseGameScore'];
    final error = json['lastError'];

    return GameRunEntry(
      id: id,
      userId: userId,
      missionId: missionId,
      courseId: json['courseId'] is String ? json['courseId'] as String : '',
      score: math.max(0, math.min(100, intOf(json['score'], 0))),
      completed: json['completed'] == true,
      mistakes: math.max(0, intOf(json['mistakes'], 0)),
      durationSec: math.max(0, intOf(json['durationSec'], 0)),
      playedAt: playedAt,
      solution: solution is Map
          ? Map<String, dynamic>.from(solution)
          : const {},
      completesCourseGame: json['completesCourseGame'] == true,
      courseGameScore: courseScore is num ? courseScore.toDouble() : null,
      attempts: math.max(0, intOf(json['attempts'], 0)),
      lastError: error is String ? error : null,
    );
  }
}
