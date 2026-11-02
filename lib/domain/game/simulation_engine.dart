import 'dart:math' as math;

import 'circuit.dart';
import 'game_models.dart';
import 'logic_blocks.dart';

/// Keadaan dunia simulasi pada satu tick.
class TickSnapshot {
  const TickSnapshot(this.tick, this.actuators, this.observed);

  final int tick;

  /// ID perangkat keluaran → hidup (true) atau mati (false).
  final Map<String, bool> actuators;

  /// Nilai yang terbaca sensor pada tick ini.
  final Map<EnvVar, double> observed;

  double get seconds => tick / SimulationEngine.ticksPerSecond;
}

class ObjectiveResult {
  const ObjectiveResult(this.objective, this.passed);

  final Objective objective;
  final bool passed;

  int get points => passed ? objective.points : 0;
}

class SimulationReport {
  const SimulationReport({
    required this.snapshots,
    required this.results,
    required this.warnings,
    required this.mistakes,
  });

  static const penaltyPerMistake = 2;
  static const maxPenalty = 20;

  final List<TickSnapshot> snapshots;
  final List<ObjectiveResult> results;

  /// Peringatan untuk pemain, misalnya perangkat belum terhubung.
  final List<String> warnings;
  final int mistakes;

  int get basePoints => results.fold<int>(0, (sum, r) => sum + r.points);

  int get penalty =>
      math.min(maxPenalty, math.max(0, mistakes) * penaltyPerMistake);

  /// Nilai 0 sampai 100.
  int get score => math.max(0, math.min(100, basePoints - penalty));

  /// Misi selesai jika semua objektif terpenuhi.
  bool get completed => results.isNotEmpty && results.every((r) => r.passed);
}

/// Mesin simulasi IoT. Deterministik: input yang sama selalu menghasilkan
/// rekaman yang sama, tanpa acak dan tanpa jam sistem.
class SimulationEngine {
  const SimulationEngine();

  /// Satu tick = 0,1 detik waktu simulasi.
  static const int ticksPerSecond = 10;

  SimulationReport run({
    required MissionDefinition mission,
    required Circuit circuit,
    required List<Rule> rules,
    int mistakes = 0,
  }) {
    final scenario = mission.scenario;
    final totalTicks = scenario.durationSec * ticksPerSecond;
    const dt = 1 / ticksPerSecond;

    final devices = {for (final d in mission.devices) d.id: d};

    bool isLive(String id) =>
        devices.containsKey(id) &&
        circuit.isInstalled(id) &&
        circuit.isWired(id);

    final eventsByTick = <int, List<ScenarioEvent>>{};
    for (final event in scenario.events) {
      final tick = (event.atSec * ticksPerSecond).round();
      if (tick < 0 || tick > totalTicks) continue;
      eventsByTick.putIfAbsent(tick, () => <ScenarioEvent>[]).add(event);
    }

    final raw = <EnvVar, double>{
      for (final v in EnvVar.values) v: scenario.initial[v] ?? 0.0,
    };
    final actuators = <String, bool>{
      for (final d in mission.devices)
        if (d.kind.isActuator) d.id: mission.initialOn[d.id] ?? false,
    };
    final fanIds = [
      for (final d in mission.devices)
        if (d.kind == DeviceKind.fan && isLive(d.id)) d.id,
    ];

    bool check(Condition c, Map<EnvVar, double> observed) {
      final device = devices[c.deviceId];
      if (device == null || !isLive(c.deviceId)) return false;
      final variable = device.kind.senses;
      if (variable == null) return false;
      return c.op.test(observed[variable]!, c.threshold);
    }

    var cooling = 0.0;
    final snapshots = <TickSnapshot>[];

    for (var tick = 0; tick <= totalTicks; tick++) {
      for (final event in eventsByTick[tick] ?? const <ScenarioEvent>[]) {
        raw[event.variable] = event.value;
      }

      final observed = <EnvVar, double>{
        EnvVar.temperature: raw[EnvVar.temperature]! - cooling,
        EnvVar.light: raw[EnvVar.light]!,
        EnvVar.motion: raw[EnvVar.motion]!,
      };

      // Aturan dievaluasi berurutan. Untuk perangkat yang sama, aturan
      // terakhir menang. Perangkat tanpa perintah mempertahankan keadaannya.
      for (final rule in rules) {
        if (rule.conditions.isEmpty) continue;

        final results = [for (final c in rule.conditions) check(c, observed)];
        final fired = rule.joiner == Joiner.and
            ? results.every((r) => r)
            : results.any((r) => r);

        for (final action in fired ? rule.thenActions : rule.elseActions) {
          if (actuators.containsKey(action.deviceId) &&
              isLive(action.deviceId)) {
            actuators[action.deviceId] = action.on;
          }
        }
      }

      snapshots.add(TickSnapshot(tick, Map.of(actuators), Map.of(observed)));

      // Kipas menyala mendinginkan ruangan, kipas mati membuatnya hangat lagi.
      final fanOn = fanIds.any((id) => actuators[id] == true);
      cooling = fanOn
          ? math.min(
              scenario.maxCooling,
              cooling + scenario.coolRatePerSec * dt,
            )
          : math.max(0.0, cooling - scenario.warmRatePerSec * dt);
    }

    (int, int)? window(double fromSec, double toSec) {
      final from = (fromSec * ticksPerSecond).round();
      final to = math.min(totalTicks, (toSec * ticksPerSecond).round());
      if (from < 0 || from > to) return null;
      return (from, to);
    }

    bool holds(ActuatorWindowObjective o) {
      if (!isLive(o.deviceId)) return false;
      final range = window(o.fromSec, o.toSec);
      if (range == null) return false;
      for (var t = range.$1; t <= range.$2; t++) {
        if (snapshots[t].actuators[o.deviceId] != o.on) return false;
      }
      return true;
    }

    bool bounded(EnvBoundObjective o) {
      final range = window(o.fromSec, o.toSec);
      if (range == null) return false;
      for (var t = range.$1; t <= range.$2; t++) {
        if (snapshots[t].observed[o.variable]! > o.maxValue) return false;
      }
      return true;
    }

    ObjectiveResult evaluate(Objective o) => switch (o) {
      AllWiredObjective() => ObjectiveResult(o, circuit.isComplete),
      ActuatorWindowObjective w => ObjectiveResult(o, holds(w)),
      EnvBoundObjective b => ObjectiveResult(o, bounded(b)),
    };

    return SimulationReport(
      snapshots: snapshots,
      results: [for (final o in mission.objectives) evaluate(o)],
      warnings: _warnings(mission, circuit, rules),
      mistakes: mistakes,
    );
  }

  List<String> _warnings(
    MissionDefinition mission,
    Circuit circuit,
    List<Rule> rules,
  ) {
    final devices = {for (final d in mission.devices) d.id: d};
    bool live(String id) => circuit.isInstalled(id) && circuit.isWired(id);

    final out = <String>{};

    for (final rule in rules) {
      if (rule.conditions.isEmpty) {
        out.add('Ada aturan tanpa kondisi. Aturan itu diabaikan.');
        continue;
      }

      for (final c in rule.conditions) {
        final d = devices[c.deviceId];
        if (d == null) {
          out.add(
            'Kondisi memakai perangkat yang tidak dikenal (${c.deviceId}).',
          );
        } else if (!d.kind.isSensor) {
          out.add(
            '${d.displayName} bukan sensor, jadi tidak bisa dipakai sebagai kondisi.',
          );
        } else if (!live(d.id)) {
          out.add(
            '${d.displayName} belum terpasang atau belum terhubung, kondisinya dianggap salah.',
          );
        }
      }

      for (final a in [...rule.thenActions, ...rule.elseActions]) {
        final d = devices[a.deviceId];
        if (d == null) {
          out.add(
            'Perintah memakai perangkat yang tidak dikenal (${a.deviceId}).',
          );
        } else if (!d.kind.isActuator) {
          out.add(
            '${d.displayName} adalah sensor, tidak bisa diberi perintah.',
          );
        } else if (!live(d.id)) {
          out.add(
            '${d.displayName} belum terpasang atau belum terhubung, perintahnya diabaikan.',
          );
        }
      }
    }

    return out.toList();
  }
}
