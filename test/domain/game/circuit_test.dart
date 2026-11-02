import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smk_tkj_lms/domain/game/circuit.dart';
import 'package:smk_tkj_lms/domain/game/missions.dart';

void main() {
  final m1 = missionAutoLamp;
  final m2 = missionSmartFan;
  final m3 = missionHomeSecurity;

  group('memasang perangkat', () {
    test('perangkat dipasang ke dudukan yang cocok', () {
      final change = Circuit.empty(m1).install('lamp1', 'hall_ceiling');
      expect(change.ok, isTrue);
      expect(change.circuit.slotOf('lamp1'), 'hall_ceiling');
    });

    test('dudukan salah jenis ditolak dan rangkaian tidak berubah', () {
      final start = Circuit.empty(m1);
      final change = start.install('lamp1', 'hall_sensor');
      expect(change.issue, CircuitIssue.slotKindMismatch);
      expect(change.circuit.installed, isEmpty);
    });

    test('dudukan yang sudah dipakai ditolak', () {
      final c = Circuit.empty(m3).install('motion1', 'door_sensor').circuit;
      expect(c.install('light1', 'door_sensor').issue, CircuitIssue.slotTaken);
    });

    test('ID tidak dikenal ditolak dan bukan kesalahan pemain', () {
      final c = Circuit.empty(m1);
      final a = c.install('ghost', 'hall_sensor').issue;
      final b = c.install('motion1', 'nowhere').issue;
      expect(a, CircuitIssue.unknownDevice);
      expect(b, CircuitIssue.unknownSlot);
      expect(a!.isMistake, isFalse);
      expect(CircuitIssue.pinTaken.isMistake, isTrue);
    });

    test('memindahkan perangkat mempertahankan kabelnya', () {
      var c = Circuit.empty(m3).install('motion1', 'door_sensor').circuit;
      c = c.connect('motion1', 'D1').circuit;
      c = c.install('motion1', 'window_sensor').circuit;
      expect(c.slotOf('motion1'), 'window_sensor');
      expect(c.pinOf('motion1'), 'D1');
    });

    test('melepas perangkat ikut melepas kabelnya', () {
      var c = Circuit.empty(m1).install('lamp1', 'hall_ceiling').circuit;
      c = c.connect('lamp1', 'D1').circuit;
      c = c.uninstall('lamp1').circuit;
      expect(c.isInstalled('lamp1'), isFalse);
      expect(c.isWired('lamp1'), isFalse);
    });
  });

  group('menyambung kabel', () {
    test('kabel sebelum perangkat dipasang ditolak', () {
      final change = Circuit.empty(m1).connect('lamp1', 'D1');
      expect(change.issue, CircuitIssue.notInstalled);
    });

    test('jenis pin yang tidak cocok ditolak', () {
      var c3 = Circuit.empty(m3);
      c3 = c3.install('light1', 'window_sensor').circuit;
      c3 = c3.install('lock1', 'front_door').circuit;
      expect(c3.connect('light1', 'D1').issue, CircuitIssue.pinIncompatible);
      expect(c3.connect('lock1', 'D1').issue, CircuitIssue.pinIncompatible);
      expect(c3.connect('light1', 'A1').ok, isTrue);
      expect(c3.connect('lock1', 'P1').ok, isTrue);

      final c2 = Circuit.empty(m2).install('temp1', 'room_sensor').circuit;
      expect(c2.connect('temp1', 'A1').issue, CircuitIssue.pinIncompatible);
    });

    test('pin yang sudah dipakai perangkat lain ditolak', () {
      var c = Circuit.empty(m1);
      c = c.install('motion1', 'hall_sensor').circuit;
      c = c.install('lamp1', 'hall_ceiling').circuit;
      c = c.connect('motion1', 'D1').circuit;
      expect(c.connect('lamp1', 'D1').issue, CircuitIssue.pinTaken);
    });

    test('pin tidak dikenal ditolak', () {
      final c = Circuit.empty(m1).install('lamp1', 'hall_ceiling').circuit;
      expect(c.connect('lamp1', 'X9').issue, CircuitIssue.unknownPin);
    });

    test('melepas kabel', () {
      var c = Circuit.empty(m1).install('lamp1', 'hall_ceiling').circuit;
      c = c.connect('lamp1', 'D2').circuit;
      c = c.disconnect('lamp1').circuit;
      expect(c.isWired('lamp1'), isFalse);
      expect(c.isInstalled('lamp1'), isTrue);
    });
  });

  group('kelengkapan dan penyimpanan', () {
    test('rangkaian kosong belum lengkap, rangkaian acuan lengkap', () {
      expect(Circuit.empty(m1).isComplete, isFalse);
      for (final m in bundledMissions) {
        expect(referenceCircuit(m).isComplete, isTrue, reason: m.id);
      }
    });

    test('JSON bolak-balik menghasilkan rangkaian yang sama', () {
      final original = referenceCircuit(m3);
      final text = jsonEncode(original.toJson());
      final restored = Circuit.fromJson(m3, jsonDecode(text));
      expect(restored.installed, original.installed);
      expect(restored.wires, original.wires);
    });

    test('JSON rusak tidak membuat crash dan entri tidak valid dilewati', () {
      expect(Circuit.fromJson(m1, 'bukan json').installed, isEmpty);

      final restored = Circuit.fromJson(m1, {
        'installed': {'lamp1': 'hall_sensor', 'motion1': 'hall_sensor'},
        'wires': {'motion1': 'A1', 'ghost': 'D1'},
      });
      expect(restored.installed, {'motion1': 'hall_sensor'});
      expect(restored.wires, isEmpty);
    });
  });
}
