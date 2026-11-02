import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/missions.dart';
import 'package:smk_tkj_lms/domain/game/mission_record.dart';

RunSummary run({
  required int score,
  bool completed = true,
  int mistakes = 0,
  int duration = 60,
}) => RunSummary(
  missionId: 'm1-auto-lamp',
  score: score,
  completed: completed,
  mistakes: mistakes,
  durationSec: duration,
  at: DateTime(2026, 1, 1),
);

void main() {
  const blank = MissionRecord(missionId: 'm1-auto-lamp');

  group('MissionRecord.afterRun', () {
    test('percobaan gagal menambah jumlah percobaan tanpa nilai terbaik', () {
      final r = blank.afterRun(run(score: 60, completed: false));
      expect(r.attempts, 1);
      expect(r.completed, isFalse);
      expect(r.bestScore, isNull);
    });

    test('percobaan berhasil menetapkan nilai terbaik', () {
      final r = blank.afterRun(run(score: 80, mistakes: 2, duration: 90));
      expect(r.completed, isTrue);
      expect(r.bestScore, 80);
      expect(r.bestMistakes, 2);
      expect(r.bestDurationSec, 90);
    });

    test('nilai lebih rendah tidak menimpa, nilai lebih tinggi menimpa', () {
      var r = blank.afterRun(run(score: 80));
      r = r.afterRun(run(score: 70));
      expect(r.bestScore, 80);
      r = r.afterRun(run(score: 95));
      expect(r.bestScore, 95);
      expect(r.attempts, 3);
    });

    test('percobaan gagal sesudah berhasil tidak mencabut status selesai', () {
      var r = blank.afterRun(run(score: 80));
      r = r.afterRun(run(score: 10, completed: false));
      expect(r.completed, isTrue);
      expect(r.bestScore, 80);
    });

    test(
      'nilai sama dengan waktu lebih singkat memperbarui durasi terbaik',
      () {
        var r = blank.afterRun(run(score: 90, duration: 120));
        r = r.afterRun(run(score: 90, duration: 80));
        expect(r.bestDurationSec, 80);
      },
    );

    test('JSON bolak-balik dan JSON rusak', () {
      final r = blank.afterRun(run(score: 88));
      final restored = MissionRecord.tryFromJson(
        jsonDecode(jsonEncode(r.toJson())),
      );
      expect(restored, isNotNull);
      expect(restored!.bestScore, 88);
      expect(restored.attempts, 1);

      expect(MissionRecord.tryFromJson('x'), isNull);
      expect(MissionRecord.tryFromJson({'attempts': 2}), isNull);
    });
  });

  test('bintang menurut nilai', () {
    expect(starsFor(score: 100, completed: false), 0);
    expect(starsFor(score: 95, completed: true), 3);
    expect(starsFor(score: 90, completed: true), 3);
    expect(starsFor(score: 89, completed: true), 2);
    expect(starsFor(score: 70, completed: true), 2);
    expect(starsFor(score: 69, completed: true), 1);
    expect(starsFor(score: 0, completed: true), 1);
  });

  group('GameProgress', () {
    final m1 = missionAutoLamp;
    final m2 = missionSmartFan;
    final m3 = missionHomeSecurity;

    test('misi pertama selalu terbuka, sisanya berurutan', () {
      const none = GameProgress({});
      expect(none.isUnlocked(m1, bundledMissions), isTrue);
      expect(none.isUnlocked(m2, bundledMissions), isFalse);
      expect(none.isUnlocked(m3, bundledMissions), isFalse);

      final afterM1 = GameProgress({m1.id: blank.afterRun(run(score: 80))});
      expect(afterM1.isUnlocked(m2, bundledMissions), isTrue);
      expect(afterM1.isUnlocked(m3, bundledMissions), isFalse);
    });

    test(
      'misi yang hanya dicoba tetapi gagal tidak membuka misi berikutnya',
      () {
        final p = GameProgress({
          m1.id: blank.afterRun(run(score: 40, completed: false)),
        });
        expect(p.isUnlocked(m2, bundledMissions), isFalse);
      },
    );

    test('jumlah selesai dan rata-rata nilai terbaik', () {
      final p = GameProgress({
        m1.id: blank.afterRun(run(score: 80)),
        m2.id: MissionRecord(missionId: m2.id).afterRun(
          RunSummary(
            missionId: m2.id,
            score: 100,
            completed: true,
            mistakes: 0,
            durationSec: 30,
            at: DateTime(2026, 1, 1),
          ),
        ),
      });
      expect(p.completedCount(bundledMissions), 2);
      expect(p.averageBest(bundledMissions), 90);
      expect(const GameProgress({}).averageBest(bundledMissions), isNull);
    });

    test('nextMission', () {
      expect(nextMission(m1)!.id, m2.id);
      expect(nextMission(m2)!.id, m3.id);
      expect(nextMission(m3), isNull);
    });
  });
}
