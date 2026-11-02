import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/circuit.dart';
import 'package:smk_tkj_lms/domain/game/game_models.dart';
import 'package:smk_tkj_lms/domain/game/logic_blocks.dart';
import 'package:smk_tkj_lms/domain/game/missions.dart';
import 'package:smk_tkj_lms/domain/game/simulation_engine.dart';

const engine = SimulationEngine();

bool passed(SimulationReport report, String objectiveId) =>
    report.results.firstWhere((r) => r.objective.id == objectiveId).passed;

void main() {
  group('misi yang tertanam', () {
    test('semua misi valid dan ID-nya unik', () {
      final ids = <String>{};
      for (final m in bundledMissions) {
        expect(m.validate(), isEmpty, reason: m.id);
        expect(ids.add(m.id), isTrue, reason: 'ID ganda ${m.id}');
      }
      expect([for (final m in bundledMissions) m.order], [1, 2, 3]);
    });

    for (final mission in bundledMissions) {
      test(
        'solusi acuan ${mission.id} lolos semua objektif dengan nilai 100',
        () {
          final report = engine.run(
            mission: mission,
            circuit: referenceCircuit(mission),
            rules: mission.reference.rules,
          );
          final failed = report.results
              .where((r) => !r.passed)
              .map((r) => r.objective.id)
              .join(', ');

          expect(report.completed, isTrue, reason: 'objektif gagal: $failed');
          expect(report.score, 100);
          expect(
            report.snapshots.length,
            mission.scenario.durationSec * 10 + 1,
          );
        },
      );
    }
  });

  group('sifat mesin', () {
    test('deterministik: dua kali jalan menghasilkan rekaman identik', () {
      final m = missionSmartFan;
      final a = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: m.reference.rules,
      );
      final b = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: m.reference.rules,
      );

      expect(a.snapshots.length, b.snapshots.length);
      for (var i = 0; i < a.snapshots.length; i++) {
        expect(a.snapshots[i].actuators, b.snapshots[i].actuators);
        expect(a.snapshots[i].observed, b.snapshots[i].observed);
      }
    });

    test(
      'kipas menurunkan suhu terbaca dan sensor tanpa kipas tetap panas',
      () {
        final m = missionSmartFan;

        final withFan = engine.run(
          mission: m,
          circuit: referenceCircuit(m),
          rules: m.reference.rules,
        );
        expect(withFan.snapshots[40].observed[EnvVar.temperature], 34);
        expect(
          withFan.snapshots[80].observed[EnvVar.temperature]!,
          lessThan(33),
        );

        final noRules = engine.run(
          mission: m,
          circuit: referenceCircuit(m),
          rules: const [],
        );
        expect(noRules.snapshots[80].observed[EnvVar.temperature], 34);
      },
    );
  });

  group('jawaban yang salah mendapat umpan balik', () {
    test('tanpa aturan: rakitan benar tetapi lampu tidak pernah menyala', () {
      final m = missionAutoLamp;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [],
      );
      expect(passed(report, 'wired'), isTrue);
      expect(passed(report, 'off-before'), isTrue);
      expect(passed(report, 'on-motion'), isFalse);
      expect(report.completed, isFalse);
    });

    test('perangkat tidak dipasang: aturan diabaikan dan ada peringatan', () {
      final m = missionAutoLamp;
      final report = engine.run(
        mission: m,
        circuit: Circuit.empty(m),
        rules: m.reference.rules,
      );
      expect(passed(report, 'wired'), isFalse);
      expect(passed(report, 'on-motion'), isFalse);
      expect(report.warnings, isNotEmpty);
      expect(
        report.snapshots.every((s) => s.actuators['lamp1'] == false),
        isTrue,
      );
    });

    test('tanpa bagian LAINNYA kipas tidak pernah mati lagi', () {
      final m = missionSmartFan;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [
          Rule(
            conditions: [Condition('temp1', CompareOp.gt, 30)],
            thenActions: [RuleAction('fan1', true)],
          ),
        ],
      );
      expect(passed(report, 'on-hot'), isTrue);
      expect(passed(report, 'off-after'), isFalse);
      expect(report.completed, isFalse);
    });

    test(
      'kipas tidak terhubung: suhu tidak terkendali dan ada peringatan kipas',
      () {
        final m = missionSmartFan;
        var c = Circuit.empty(m);
        c = c.install('temp1', 'room_sensor').circuit;
        c = c.install('fan1', 'room_wall').circuit;
        c = c.connect('temp1', 'D1').circuit;

        final report = engine.run(
          mission: m,
          circuit: c,
          rules: m.reference.rules,
        );
        expect(passed(report, 'on-hot'), isFalse);
        expect(passed(report, 'temp-bound'), isFalse);
        expect(report.warnings.any((w) => w.contains('Kipas')), isTrue);
      },
    );

    test('hanya satu kondisi: alarm berbunyi di siang hari dan gagal', () {
      final m = missionHomeSecurity;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [
          Rule(
            conditions: [Condition('motion1', CompareOp.gt, 0.5)],
            thenActions: [
              RuleAction('buzzer1', true),
              RuleAction('lock1', true),
            ],
            elseActions: [RuleAction('buzzer1', false)],
          ),
        ],
      );
      expect(passed(report, 'quiet-day'), isFalse);
      expect(passed(report, 'alarm-night'), isTrue);
    });

    test('DAN dan ATAU memberi hasil berbeda', () {
      final m = missionHomeSecurity;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [
          Rule(
            conditions: [
              Condition('motion1', CompareOp.gt, 0.5),
              Condition('light1', CompareOp.lt, 200),
            ],
            joiner: Joiner.or,
            thenActions: [
              RuleAction('buzzer1', true),
              RuleAction('lock1', true),
            ],
            elseActions: [RuleAction('buzzer1', false)],
          ),
        ],
      );
      expect(passed(report, 'alarm-night'), isTrue);
      expect(passed(report, 'quiet-day'), isFalse);
      expect(passed(report, 'quiet-after'), isFalse);
    });

    test('aturan tanpa kondisi diabaikan dengan peringatan', () {
      final m = missionAutoLamp;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [
          Rule(conditions: [], thenActions: [RuleAction('lamp1', true)]),
        ],
      );
      expect(report.warnings.any((w) => w.contains('tanpa kondisi')), isTrue);
      expect(
        report.snapshots.every((s) => s.actuators['lamp1'] == false),
        isTrue,
      );
    });

    test('perintah ke sensor dan kondisi dari perangkat keluaran diberi peringatan', () {
      final m = missionAutoLamp;
      final report = engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: const [
          Rule(
            conditions: [Condition('lamp1', CompareOp.gt, 0.5)],
            thenActions: [RuleAction('motion1', true)],
          ),
        ],
      );
      expect(report.warnings.length, 2);
    });
  });

  group('skor', () {
    test('setiap kesalahan mengurangi 2 poin dengan batas 20', () {
      final m = missionAutoLamp;

      SimulationReport runWith(int mistakes) => engine.run(
        mission: m,
        circuit: referenceCircuit(m),
        rules: m.reference.rules,
        mistakes: mistakes,
      );

      expect(runWith(0).score, 100);
      expect(runWith(3).score, 94);
      expect(runWith(50).score, 80);
      expect(runWith(50).completed, isTrue);
      expect(runWith(-5).score, 100);
    });
  });

  group('blok logika', () {
    test('aturan bisa disimpan dan dipulihkan lewat JSON', () {
      final rule = missionHomeSecurity.reference.rules.first;
      final restored = Rule.tryFromJson(jsonDecode(jsonEncode(rule.toJson())));
      expect(restored, isNotNull);
      expect(restored!.toJson(), rule.toJson());
    });

    test('JSON rusak menghasilkan null atau bagian yang dilewati', () {
      expect(Rule.tryFromJson('x'), isNull);
      expect(Rule.tryFromJson(null), isNull);

      final partial = Rule.tryFromJson({
        'conditions': [
          {'device': 'a', 'op': 'gt', 'value': 1},
          {'device': 'b', 'op': 'tidak-ada', 'value': 1},
          'sampah',
        ],
        'then': [
          {'device': 'x', 'on': true},
          {'device': 'y'},
        ],
      });
      expect(partial!.conditions.length, 1);
      expect(partial.thenActions.length, 1);
      expect(partial.joiner, Joiner.and);
    });

    test('operator perbandingan', () {
      expect(CompareOp.gt.test(31, 30), isTrue);
      expect(CompareOp.gt.test(30, 30), isFalse);
      expect(CompareOp.gte.test(30, 30), isTrue);
      expect(CompareOp.lt.test(1, 2), isTrue);
      expect(CompareOp.lte.test(2, 2), isTrue);
      expect(CompareOp.eq.test(0.3 + 0.0, 0.3), isTrue);
    });
  });
}
