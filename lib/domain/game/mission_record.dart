import 'dart:math' as math;

import 'game_models.dart';

/// Hasil satu kali menjalankan misi.
class RunSummary {
  const RunSummary({
    required this.missionId,
    required this.score,
    required this.completed,
    required this.mistakes,
    required this.durationSec,
    required this.at,
  });

  final String missionId;
  final int score;
  final bool completed;
  final int mistakes;
  final int durationSec;
  final DateTime at;
}

/// Jumlah bintang: 0 jika misi belum selesai, 1 sampai 3 menurut nilai.
int starsFor({required int score, required bool completed}) {
  if (!completed) return 0;
  if (score >= 90) return 3;
  if (score >= 70) return 2;
  return 1;
}

/// Rekap hasil pemain pada satu misi, disimpan di perangkat.
class MissionRecord {
  const MissionRecord({
    required this.missionId,
    this.attempts = 0,
    this.completed = false,
    this.bestScore,
    this.bestDurationSec,
    this.bestMistakes,
    this.lastPlayedAt,
  });

  final String missionId;
  final int attempts;
  final bool completed;

  /// Nilai terbaik dari percobaan yang menyelesaikan misi. Null jika belum ada.
  final int? bestScore;
  final int? bestDurationSec;
  final int? bestMistakes;
  final DateTime? lastPlayedAt;

  MissionRecord afterRun(RunSummary run) {
    var best = bestScore;
    var bestMist = bestMistakes;
    var bestDur = bestDurationSec;

    if (run.completed) {
      final better =
          best == null ||
          run.score > best ||
          (run.score == best && bestDur != null && run.durationSec < bestDur);
      if (better) {
        best = run.score;
        bestMist = run.mistakes;
        bestDur = run.durationSec;
      }
    }

    return MissionRecord(
      missionId: missionId,
      attempts: attempts + 1,
      completed: completed || run.completed,
      bestScore: best,
      bestDurationSec: bestDur,
      bestMistakes: bestMist,
      lastPlayedAt: run.at,
    );
  }

  Map<String, dynamic> toJson() => {
    'missionId': missionId,
    'attempts': attempts,
    'completed': completed,
    'bestScore': bestScore,
    'bestDurationSec': bestDurationSec,
    'bestMistakes': bestMistakes,
    'lastPlayedAt': lastPlayedAt?.toIso8601String(),
  };

  static MissionRecord? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['missionId'];
    if (id is! String || id.isEmpty) return null;

    int? intOf(Object? v) => v is num ? v.toInt() : null;
    final last = json['lastPlayedAt'];

    return MissionRecord(
      missionId: id,
      attempts: math.max(0, intOf(json['attempts']) ?? 0),
      completed: json['completed'] == true,
      bestScore: intOf(json['bestScore']),
      bestDurationSec: intOf(json['bestDurationSec']),
      bestMistakes: intOf(json['bestMistakes']),
      lastPlayedAt: last is String ? DateTime.tryParse(last) : null,
    );
  }
}

/// Seluruh progres game seorang pemain.
class GameProgress {
  const GameProgress(this.records);

  static const empty = GameProgress({});

  final Map<String, MissionRecord> records;

  MissionRecord recordOf(String missionId) =>
      records[missionId] ?? MissionRecord(missionId: missionId);

  bool isCompleted(String missionId) => records[missionId]?.completed ?? false;

  /// Misi pertama selalu terbuka. Misi lain terbuka setelah misi
  /// sebelumnya (urutan terdekat di bawahnya) selesai.
  bool isUnlocked(MissionDefinition mission, List<MissionDefinition> all) {
    MissionDefinition? previous;
    for (final m in all) {
      if (m.order < mission.order &&
          (previous == null || m.order > previous.order)) {
        previous = m;
      }
    }
    return previous == null || isCompleted(previous.id);
  }

  int completedCount(List<MissionDefinition> all) =>
      all.where((m) => isCompleted(m.id)).length;

  /// Rata-rata nilai terbaik pada misi yang sudah selesai. Null jika belum ada.
  double? averageBest(List<MissionDefinition> all) {
    final scores = <int>[];
    for (final m in all) {
      final s = records[m.id]?.bestScore;
      if (s != null) scores.add(s);
    }
    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }
}
