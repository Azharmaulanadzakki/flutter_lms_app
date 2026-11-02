import 'circuit.dart';
import 'game_models.dart';
import 'logic_blocks.dart';
import 'simulation_engine.dart';

class SessionChange {
  const SessionChange(this.session, [this.issue]);

  final GameSession session;
  final CircuitIssue? issue;

  bool get ok => issue == null;
}

/// Keadaan satu sesi bermain: rangkaian, aturan, dan hasil terakhir.
/// Tidak bisa diubah. Semua perubahan menghasilkan sesi baru.
class GameSession {
  GameSession._(
    this.mission,
    this.circuit,
    this.rules,
    this.mistakes,
    this.runs,
    this.report,
  );

  factory GameSession.start(MissionDefinition mission) =>
      GameSession._(mission, Circuit.empty(mission), const [], 0, 0, null);

  static const int maxRules = 6;

  final MissionDefinition mission;
  final Circuit circuit;
  final List<Rule> rules;

  /// Kesalahan pemain saat memasang atau menyambung. Mengurangi nilai.
  final int mistakes;
  final int runs;

  /// Hasil simulasi terakhir. Null jika belum dijalankan atau rakitan berubah.
  final SimulationReport? report;

  bool get canAddRule => rules.length < maxRules;

  /// Keadaan rumah sebelum simulasi: perangkat pada keadaan awal dan
  /// sensor pada nilai awal skenario.
  TickSnapshot get restFrame {
    final initial = mission.scenario.initial;
    return TickSnapshot(
      0,
      {
        for (final d in mission.devices)
          if (d.kind.isActuator) d.id: mission.initialOn[d.id] ?? false,
      },
      {for (final v in EnvVar.values) v: initial[v] ?? 0.0},
    );
  }

  GameSession _with({
    Circuit? circuit,
    List<Rule>? rules,
    int? mistakes,
    int? runs,
    SimulationReport? report,
    bool clearReport = false,
  }) {
    return GameSession._(
      mission,
      circuit ?? this.circuit,
      rules ?? this.rules,
      mistakes ?? this.mistakes,
      runs ?? this.runs,
      clearReport ? null : (report ?? this.report),
    );
  }

  SessionChange _apply(CircuitChange change) {
    if (change.ok) {
      return SessionChange(_with(circuit: change.circuit, clearReport: true));
    }
    final issue = change.issue!;
    return SessionChange(
      _with(mistakes: mistakes + (issue.isMistake ? 1 : 0)),
      issue,
    );
  }

  SessionChange install(String deviceId, String slotId) =>
      _apply(circuit.install(deviceId, slotId));

  SessionChange uninstall(String deviceId) =>
      _apply(circuit.uninstall(deviceId));

  SessionChange connect(String deviceId, String pinId) =>
      _apply(circuit.connect(deviceId, pinId));

  SessionChange disconnect(String deviceId) =>
      _apply(circuit.disconnect(deviceId));

  GameSession addRule(Rule rule) =>
      canAddRule ? _with(rules: [...rules, rule], clearReport: true) : this;

  GameSession replaceRule(int index, Rule rule) {
    if (index < 0 || index >= rules.length) return this;
    final next = [...rules];
    next[index] = rule;
    return _with(rules: next, clearReport: true);
  }

  GameSession removeRule(int index) {
    if (index < 0 || index >= rules.length) return this;
    final next = [...rules]..removeAt(index);
    return _with(rules: next, clearReport: true);
  }

  GameSession run() {
    final result = const SimulationEngine().run(
      mission: mission,
      circuit: circuit,
      rules: rules,
      mistakes: mistakes,
    );
    return _with(report: result, runs: runs + 1);
  }
}
