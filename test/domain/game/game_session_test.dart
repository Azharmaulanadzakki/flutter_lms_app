import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/circuit.dart';
import 'package:smk_tkj_lms/domain/game/game_models.dart';
import 'package:smk_tkj_lms/domain/game/game_session.dart';
import 'package:smk_tkj_lms/domain/game/logic_blocks.dart';
import 'package:smk_tkj_lms/domain/game/missions.dart';

/// Sesi yang dirakit mengikuti jawaban acuan lewat API sesi.
GameSession solved(MissionDefinition m) {
  var s = GameSession.start(m);
  for (final e in m.reference.installed.entries) {
    final c = s.install(e.key, e.value);
    expect(c.ok, isTrue, reason: 'pasang ${e.key}');
    s = c.session;
  }
  for (final e in m.reference.wires.entries) {
    final c = s.connect(e.key, e.value);
    expect(c.ok, isTrue, reason: 'sambung ${e.key}');
    s = c.session;
  }
  for (final r in m.reference.rules) {
    s = s.addRule(r);
  }
  return s;
}

void main() {
  final m1 = missionAutoLamp;

  test('sesi baru kosong', () {
    final s = GameSession.start(m1);
    expect(s.circuit.installed, isEmpty);
    expect(s.rules, isEmpty);
    expect(s.mistakes, 0);
    expect(s.runs, 0);
    expect(s.report, isNull);
  });

  group('kesalahan', () {
    test('pilihan pemain yang salah menambah kesalahan', () {
      final change = GameSession.start(m1).install('lamp1', 'hall_sensor');
      expect(change.ok, isFalse);
      expect(change.issue, CircuitIssue.slotKindMismatch);
      expect(change.session.mistakes, 1);
      expect(change.session.circuit.installed, isEmpty);
    });

    test('ID tidak dikenal bukan kesalahan pemain', () {
      final change = GameSession.start(m1).install('ghost', 'hall_sensor');
      expect(change.issue, CircuitIssue.unknownDevice);
      expect(change.session.mistakes, 0);
    });

    test('kesalahan mengurangi nilai akhir', () {
      var s = GameSession.start(m1);
      s = s.install('lamp1', 'hall_sensor').session;
      s = s.install('lamp1', 'hall_sensor').session;
      expect(s.mistakes, 2);

      var good = solved(m1);
      good = GameSession.start(m1);
      for (final e in m1.reference.installed.entries) {
        good = good.install(e.key, e.value).session;
      }
      for (final e in m1.reference.wires.entries) {
        good = good.connect(e.key, e.value).session;
      }
      for (final r in m1.reference.rules) {
        good = good.addRule(r);
      }
      // Dua kesalahan dipindahkan ke sesi yang benar lewat langkah salah dulu.
      var withMistakes = good.install('lamp1', 'hall_sensor').session;
      withMistakes = withMistakes.install('lamp1', 'hall_sensor').session;
      final ran = withMistakes.run();
      expect(ran.report!.completed, isTrue);
      expect(ran.report!.score, 96);
    });
  });

  group('mengedit', () {
    test('perubahan membuang hasil simulasi lama', () {
      var s = solved(m1).run();
      expect(s.report, isNotNull);
      expect(s.runs, 1);

      s = s.removeRule(0);
      expect(s.report, isNull);
      expect(s.rules, isEmpty);
      expect(s.runs, 1);
    });

    test('batas jumlah aturan', () {
      var s = GameSession.start(m1);
      final rule = m1.reference.rules.first;
      for (var i = 0; i < GameSession.maxRules + 3; i++) {
        s = s.addRule(rule);
      }
      expect(s.rules.length, GameSession.maxRules);
      expect(s.canAddRule, isFalse);
    });

    test(
      'mengganti dan menghapus aturan dengan indeks tidak valid diabaikan',
      () {
        final s = solved(m1);
        expect(identical(s.replaceRule(9, s.rules.first), s), isTrue);
        expect(identical(s.removeRule(-1), s), isTrue);

        const replacement = Rule(
          conditions: [Condition('motion1', CompareOp.lt, 0.5)],
          thenActions: [RuleAction('lamp1', false)],
        );
        final replaced = s.replaceRule(0, replacement);
        expect(replaced.rules.length, 1);
        expect(replaced.rules.first.thenActions.first.on, isFalse);
      },
    );
  });

  group('menjalankan', () {
    test('jawaban acuan menyelesaikan setiap misi', () {
      for (final m in bundledMissions) {
        final ran = solved(m).run();
        expect(ran.report!.completed, isTrue, reason: m.id);
        expect(ran.report!.score, 100, reason: m.id);
        expect(ran.runs, 1);
      }
    });

    test('rumah awal sesuai skenario misi', () {
      final frame = GameSession.start(missionSmartFan).restFrame;
      expect(frame.observed[EnvVar.temperature], 26);
      expect(frame.actuators['fan1'], isFalse);
      expect(frame.actuators.containsKey('temp1'), isFalse);
    });
  });
}
