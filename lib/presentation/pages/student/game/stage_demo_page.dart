import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/game/circuit.dart';
import '../../../../domain/game/game_models.dart';
import '../../../../domain/game/missions.dart';
import '../../../../domain/game/simulation_engine.dart';
import 'stage/stage_entry.dart';

/// Halaman uji panggung 3D: pasang perangkat dengan mengetuk dudukan,
/// sambung kabel, lalu putar simulasi. Dasar dari layar game Fase 3.
class StageDemoPage extends StatefulWidget {
  const StageDemoPage({super.key});

  @override
  State<StageDemoPage> createState() => _StageDemoPageState();
}

class _StageDemoPageState extends State<StageDemoPage> {
  MissionDefinition _mission = bundledMissions.first;
  late Circuit _circuit = Circuit.empty(_mission);

  String? _selected;
  SimulationReport? _report;
  TickSnapshot? _frame;
  Timer? _timer;
  int _tick = 0;
  int _speed = 1;
  bool _useRules = true;
  bool _stageFailed = false;
  String _message =
      'Pilih perangkat di rak, lalu ketuk dudukan yang berkedip hijau di panggung.';

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetRun() {
    _stop();
    _report = null;
    _frame = null;
    _tick = 0;
  }

  void _pickMission(MissionDefinition mission) {
    setState(() {
      _resetRun();
      _mission = mission;
      _circuit = Circuit.empty(mission);
      _selected = null;
      _message = 'Pilih perangkat di rak, lalu ketuk dudukan yang berkedip hijau di panggung.';
    });
  }

  void _onSlotTap(String slotId) {
    final slot = _mission.slotById(slotId);
    final slotName = slot?.label ?? slotId;
    final occupant = _circuit.installed.entries
        .where((e) => e.value == slotId)
        .map((e) => e.key)
        .firstOrNull;

    if (occupant != null) {
      final change = _circuit.uninstall(occupant);
      setState(() {
        _resetRun();
        _circuit = change.circuit;
        _message = 'Perangkat dilepas dari $slotName.';
      });
      return;
    }

    final id = _selected;
    if (id == null) {
      setState(
        () => _message = 'Pilih perangkat di rak dulu, baru ketuk dudukan.',
      );
      return;
    }

    final change = _circuit.install(id, slotId);
    setState(() {
      if (change.ok) {
        _resetRun();
        _circuit = change.circuit;
        _selected = null;
        _message = 'Terpasang di $slotName.';
      } else {
        _message = change.issue!.message;
      }
    });
  }

  void _autoWire() {
    var circuit = _circuit;
    for (final device in _mission.devices) {
      if (!circuit.isInstalled(device.id) || circuit.isWired(device.id))
        continue;
      for (final pin in _mission.pins) {
        final change = circuit.connect(device.id, pin.id);
        if (change.ok) {
          circuit = change.circuit;
          break;
        }
      }
    }
    setState(() {
      _resetRun();
      _circuit = circuit;
      _message = 'Kabel disambung otomatis ke pin yang cocok.';
    });
  }

  void _run() {
    _stop();
    final report = const SimulationEngine().run(
      mission: _mission,
      circuit: _circuit,
      rules: _useRules ? _mission.reference.rules : const [],
    );

    setState(() {
      _report = report;
      _tick = 0;
      _frame = report.snapshots.first;
      _message = 'Simulasi berjalan...';
    });

    _timer = Timer.periodic(Duration(milliseconds: (100 / _speed).round()), (
      timer,
    ) {
      if (!mounted) return;
      _tick++;
      if (_tick >= report.snapshots.length) {
        timer.cancel();
        setState(() {
          _message = report.completed
              ? 'Selesai. Semua objektif terpenuhi, nilai ${report.score}.'
              : 'Selesai. Belum semua objektif terpenuhi, nilai ${report.score}.';
        });
        return;
      }
      setState(() => _frame = report.snapshots[_tick]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trayDevices = _mission.devices
        .where((d) => !_circuit.isInstalled(d.id))
        .toList();
    final selectedKind = _selected == null
        ? null
        : _mission.deviceById(_selected!)?.kind.slotKind;
    final frame = _frame;
    final report = _report;

    return Scaffold(
      appBar: AppBar(title: const Text('Demo Panggung 3D')),
      body: Column(
        children: [
          Expanded(
            child: SmartHomeStage(
              mission: _mission,
              installed: _circuit.installed,
              wires: _circuit.wires,
              frame: frame,
              highlightKind: selectedKind,
              onSlotTap: _onSlotTap,
              onFailed: () => setState(() => _stageFailed = true),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final m in bundledMissions) ...[
                          ChoiceChip(
                            label: Text('${m.order}. ${m.title}'),
                            selected: m.id == _mission.id,
                            onSelected: (_) => _pickMission(m),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(_mission.goal, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(_message, style: theme.textTheme.labelLarge),
                  if (_stageFailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Panggung 3D gagal. Simulasi tetap berjalan, hasilnya ada di bawah.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text('Rak komponen', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  if (trayDevices.isEmpty)
                    Text(
                      'Semua perangkat sudah terpasang.',
                      style: theme.textTheme.bodySmall,
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final d in trayDevices)
                          ChoiceChip(
                            label: Text(d.displayName),
                            selected: _selected == d.id,
                            onSelected: (v) =>
                                setState(() => _selected = v ? d.id : null),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      OutlinedButton(
                        onPressed: _autoWire,
                        child: const Text('Sambung kabel otomatis'),
                      ),
                      FilledButton(
                        onPressed: _run,
                        child: const Text('Jalankan simulasi'),
                      ),
                      OutlinedButton(
                        onPressed: () => _pickMission(_mission),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pakai aturan acuan'),
                    subtitle: const Text(
                      'Matikan untuk melihat rumah tanpa logika.',
                    ),
                    value: _useRules,
                    onChanged: (v) => setState(() => _useRules = v),
                  ),
                  Row(
                    children: [
                      const Text('Kecepatan'),
                      const SizedBox(width: 12),
                      for (final s in const [1, 2, 4]) ...[
                        ChoiceChip(
                          label: Text('${s}x'),
                          selected: _speed == s,
                          onSelected: (_) => setState(() => _speed = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  if (frame != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Detik ${frame.seconds.toStringAsFixed(1)} · '
                      'suhu ${frame.observed[EnvVar.temperature]!.toStringAsFixed(1)}°C · '
                      'cahaya ${frame.observed[EnvVar.light]!.round()} lux · '
                      'gerakan ${frame.observed[EnvVar.motion]! > 0.5 ? 'ya' : 'tidak'}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final d in _mission.devices)
                          if (d.kind.isActuator)
                            Chip(
                              label: Text(
                                '${d.displayName}: ${d.kind.stateLabel(frame.actuators[d.id] == true)}',
                              ),
                            ),
                      ],
                    ),
                  ],
                  if (report != null &&
                      _tick >= report.snapshots.length - 1) ...[
                    const SizedBox(height: 8),
                    for (final r in report.results)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            r.passed ? Icons.check_circle : Icons.cancel,
                            size: 18,
                            color: r.passed
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              r.passed
                                  ? r.objective.title
                                  : '${r.objective.title}\n${r.objective.hint}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    for (final w in report.warnings)
                      Text('Peringatan: $w', style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
