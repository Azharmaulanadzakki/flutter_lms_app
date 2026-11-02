import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/course_game.dart';
import 'package:smk_tkj_lms/domain/game/mission_record.dart';
import 'package:smk_tkj_lms/domain/game/missions.dart';

RunSummary run(String missionId, int score, {bool completed = true}) =>
    RunSummary(
      missionId: missionId,
      score: score,
      completed: completed,
      mistakes: 0,
      durationSec: 10,
      at: DateTime(2026, 1, 1),
    );

MissionRecord record(String missionId, int score) =>
    MissionRecord(missionId: missionId).afterRun(run(missionId, score));

void main() {
  final m1 = missionAutoLamp;
  final m2 = missionSmartFan;
  final m3 = missionHomeSecurity;

  group('missionsForCourse', () {
    test('daftar kosong atau ID tidak dikenal berarti semua misi', () {
      expect(missionsForCourse(const []).length, bundledMissions.length);
      expect(missionsForCourse(const ['ghost']).length, bundledMissions.length);
    });

    test('terurut menurut order, tanpa duplikat, ID asing dibuang', () {
      final scope = missionsForCourse([m3.id, 'ghost', m1.id, m1.id]);
      expect(scope.map((m) => m.id), [m1.id, m3.id]);
    });
  });

  test('nextMissionIn dibatasi pada lingkup course', () {
    final scope = [m1, m3];
    expect(nextMissionIn(scope, m1)!.id, m3.id);
    expect(nextMissionIn(scope, m3), isNull);
  });

  group('status simulasi course', () {
    final scope = [m1, m3];

    test('belum semua misi selesai', () {
      final s = courseGameAfterRun(
        missions: scope,
        progress: GameProgress.empty,
        run: run(m1.id, 90),
      );
      expect(s.completed, isFalse);
      expect(s.doneCount, 1);
      expect(s.total, 2);
      expect(s.averageScore, 90);
    });

    test(
      'misi terakhir menuntaskan simulasi dengan rata-rata nilai terbaik',
      () {
        final progress = GameProgress({m1.id: record(m1.id, 80)});
        final s = courseGameAfterRun(
          missions: scope,
          progress: progress,
          run: run(m3.id, 100),
        );
        expect(s.completed, isTrue);
        expect(s.averageScore, 90);
      },
    );

    test('percobaan gagal tidak menyelesaikan misi', () {
      final progress = GameProgress({m1.id: record(m1.id, 80)});
      final s = courseGameAfterRun(
        missions: scope,
        progress: progress,
        run: run(m3.id, 50, completed: false),
      );
      expect(s.completed, isFalse);
      expect(s.doneCount, 1);
    });

    test('mengulang misi memakai nilai terbaik, bukan yang terakhir', () {
      final progress = GameProgress({
        m1.id: record(m1.id, 100),
        m3.id: record(m3.id, 60),
      });

      final s = courseGameAfterRun(
        missions: scope,
        progress: progress,
        run: run(m3.id, 80),
      );

      expect(s.completed, isTrue);
      expect(s.averageScore, 90);

      final lower = courseGameAfterRun(
        missions: scope,
        progress: progress,
        run: run(m1.id, 70),
      );

      expect(lower.averageScore, 80);
    });

    test('misi di luar course tidak dihitung', () {
      final progress = GameProgress({m2.id: record(m2.id, 100)});
      final s = courseGameStatus([m1], progress);
      expect(s.completed, isFalse);
      expect(s.doneCount, 0);
    });

    test('tanpa misi tidak pernah dianggap selesai', () {
      final s = courseGameStatus(const [], GameProgress.empty);
      expect(s.completed, isFalse);
      expect(s.averageScore, isNull);
    });
  });
}
