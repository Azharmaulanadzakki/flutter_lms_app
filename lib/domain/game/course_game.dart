import 'game_models.dart';
import 'mission_record.dart';
import 'missions.dart';

/// Konteks pemain saat memainkan misi sebagai bagian dari sebuah course.
class GameCourseContext {
  const GameCourseContext({required this.courseId, required this.missionIds});

  final String courseId;
  final List<String> missionIds;
}

/// Misi yang dipakai sebuah course, terurut dan tanpa duplikat.
/// Daftar kosong, atau tidak ada ID yang dikenal, berarti semua misi.
List<MissionDefinition> missionsForCourse(List<String> missionIds) {
  final picked = <MissionDefinition>[];
  for (final id in missionIds) {
    final mission = missionById(id);
    if (mission != null && !picked.any((p) => p.id == mission.id)) {
      picked.add(mission);
    }
  }
  if (picked.isEmpty) return [...bundledMissions];

  picked.sort((a, b) => a.order.compareTo(b.order));
  return picked;
}

/// Misi berikutnya dalam [scope] setelah [current], atau null jika ini yang terakhir.
MissionDefinition? nextMissionIn(
  List<MissionDefinition> scope,
  MissionDefinition current,
) {
  MissionDefinition? next;
  for (final m in scope) {
    if (m.order > current.order && (next == null || m.order < next.order)) {
      next = m;
    }
  }
  return next;
}

class CourseGameStatus {
  const CourseGameStatus({
    required this.completed,
    required this.doneCount,
    required this.total,
    this.averageScore,
  });

  /// Semua misi dalam lingkup sudah selesai.
  final bool completed;
  final int doneCount;
  final int total;

  /// Rata-rata nilai terbaik misi yang sudah selesai. Null jika belum ada.
  final double? averageScore;
}

CourseGameStatus courseGameStatus(
  List<MissionDefinition> missions,
  GameProgress progress,
) {
  var done = 0;
  final scores = <int>[];

  for (final m in missions) {
    final record = progress.records[m.id];
    if (record == null || !record.completed) continue;
    done++;
    final best = record.bestScore;
    if (best != null) scores.add(best);
  }

  return CourseGameStatus(
    completed: missions.isNotEmpty && done == missions.length,
    doneCount: done,
    total: missions.length,
    averageScore: scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length,
  );
}

/// Status simulasi course setelah [run] ikut dihitung. Dipakai sebelum
/// hasilnya disimpan, supaya penandaan selesai ikut terkirim bersama hasil.
CourseGameStatus courseGameAfterRun({
  required List<MissionDefinition> missions,
  required GameProgress progress,
  required RunSummary run,
}) {
  final records = <String, MissionRecord>{...progress.records};
  records[run.missionId] = progress.recordOf(run.missionId).afterRun(run);
  return courseGameStatus(missions, GameProgress(records));
}
