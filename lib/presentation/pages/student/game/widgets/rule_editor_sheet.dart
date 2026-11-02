import 'package:flutter/material.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../../domain/game/logic_blocks.dart';

class RuleEditorSheet extends StatefulWidget {
  const RuleEditorSheet({super.key, required this.mission, this.initial});

  final MissionDefinition mission;

  /// Null = aturan baru.
  final Rule? initial;

  @override
  State<RuleEditorSheet> createState() => _RuleEditorSheetState();
}

class _CondDraft {
  _CondDraft({
    this.deviceId,
    this.op = CompareOp.gt,
    this.detected = true,
    String value = '',
  }) : value = TextEditingController(text: value);

  String? deviceId;
  CompareOp op;
  bool detected;
  final TextEditingController value;
}

class _ActDraft {
  _ActDraft({this.deviceId, this.on = true});

  String? deviceId;
  bool on;
}

class _RuleEditorSheetState extends State<RuleEditorSheet> {
  late final List<_CondDraft> _conds;
  late final List<_ActDraft> _then;
  late final List<_ActDraft> _else;
  Joiner _joiner = Joiner.and;
  String? _error;

  MissionDefinition get _m => widget.mission;

  List<DeviceItem> get _sensors => [
        for (final d in _m.devices)
          if (d.kind.isSensor) d,
      ];

  List<DeviceItem> get _actuators => [
        for (final d in _m.devices)
          if (d.kind.isActuator) d,
      ];

  bool _isMotion(String? id) =>
      id != null && _m.deviceById(id)?.kind == DeviceKind.motionSensor;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  @override
  void initState() {
    super.initState();
    final rule = widget.initial;

    if (rule == null) {
      _conds = [_CondDraft(deviceId: _sensors.isEmpty ? null : _sensors.first.id)];
      _then = [_ActDraft(deviceId: _actuators.isEmpty ? null : _actuators.first.id)];
      _else = [];
    } else {
      _joiner = rule.joiner;
      _conds = [for (final c in rule.conditions) _draftOf(c)];
      if (_conds.isEmpty) _conds.add(_CondDraft());
      _then = [for (final a in rule.thenActions) _ActDraft(deviceId: a.deviceId, on: a.on)];
      _else = [for (final a in rule.elseActions) _ActDraft(deviceId: a.deviceId, on: a.on)];
    }
  }

  @override
  void dispose() {
    for (final c in _conds) {
      c.value.dispose();
    }
    super.dispose();
  }

  _CondDraft _draftOf(Condition c) {
    if (_isMotion(c.deviceId)) {
      final high = c.op.test(1, c.threshold);
      final low = c.op.test(0, c.threshold);
      return _CondDraft(deviceId: c.deviceId, detected: high || !low);
    }
    return _CondDraft(deviceId: c.deviceId, op: c.op, value: _fmt(c.threshold));
  }

  Condition? _buildCond(_CondDraft c) {
    final id = c.deviceId;
    if (id == null) return null;
    if (_isMotion(id)) {
      return Condition(id, c.detected ? CompareOp.gt : CompareOp.lt, 0.5);
    }
    final v = double.tryParse(c.value.text.trim().replaceAll(',', '.'));
    if (v == null || v.isNaN || v.isInfinite) return null;
    return Condition(id, c.op, v);
  }

  void _save() {
    final conditions = <Condition>[];
    for (final c in _conds) {
      final built = _buildCond(c);
      if (built == null) {
        setState(() => _error = 'Lengkapi semua kondisi: pilih sensor dan isi nilai berupa angka.');
        return;
      }
      conditions.add(built);
    }

    String? problem;
    List<RuleAction> build(List<_ActDraft> drafts, String branch) {
      final out = <RuleAction>[];
      final seen = <String>{};
      for (final a in drafts) {
        final id = a.deviceId;
        if (id == null) {
          problem = 'Pilih perangkat untuk setiap perintah di $branch.';
          return out;
        }
        if (!seen.add(id)) {
          problem = 'Perangkat yang sama tidak boleh muncul dua kali di $branch.';
          return out;
        }
        out.add(RuleAction(id, a.on));
      }
      return out;
    }

    final thenActions = build(_then, 'MAKA');
    final elseActions = problem == null ? build(_else, 'LAINNYA') : <RuleAction>[];

    if (problem != null) {
      final message = problem;
      setState(() => _error = message);
      return;
    }
    if (thenActions.isEmpty) {
      setState(() => _error = 'Tambahkan minimal satu perintah pada MAKA.');
      return;
    }

    Navigator.pop(
      context,
      Rule(
        conditions: conditions,
        joiner: _joiner,
        thenActions: thenActions,
        elseActions: elseActions,
      ),
    );
  }

  Widget _conditionCard(_CondDraft cond) {
    final motion = _isMotion(cond.deviceId);
    final unit = _m.deviceById(cond.deviceId ?? '')?.kind.senses?.unit;

    return Card(
      key: ObjectKey(cond),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: cond.deviceId,
                    hint: const Text('Pilih sensor'),
                    items: [
                      for (final d in _sensors)
                        DropdownMenuItem(value: d.id, child: Text(d.displayName)),
                    ],
                    onChanged: (v) => setState(() => cond.deviceId = v),
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus kondisi',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _conds.length > 1
                      ? () => setState(() {
                            _conds.remove(cond);
                            cond.value.dispose();
                          })
                      : null,
                ),
              ],
            ),
            if (motion)
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Ada gerakan')),
                  ButtonSegment(value: false, label: Text('Tidak ada gerakan')),
                ],
                selected: {cond.detected},
                onSelectionChanged: (s) => setState(() => cond.detected = s.first),
              )
            else
              Row(
                children: [
                  DropdownButton<CompareOp>(
                    value: cond.op,
                    items: [
                      for (final op in CompareOp.values)
                        DropdownMenuItem(value: op, child: Text(op.symbol)),
                    ],
                    onChanged: (v) => setState(() => cond.op = v ?? cond.op),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: cond.value,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        labelText: 'Nilai',
                        suffixText: unit,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionList(List<_ActDraft> drafts) {
    return Column(
      children: [
        for (final act in drafts)
          Card(
            key: ObjectKey(act),
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: act.deviceId,
                      hint: const Text('Pilih perangkat'),
                      items: [
                        for (final d in _actuators)
                          DropdownMenuItem(value: d.id, child: Text(d.displayName)),
                      ],
                      onChanged: (v) => setState(() => act.deviceId = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Builder(builder: (context) {
                    final kind = _m.deviceById(act.deviceId ?? '')?.kind;
                    return SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: true, label: Text(kind?.stateLabel(true) ?? 'ON')),
                        ButtonSegment(value: false, label: Text(kind?.stateLabel(false) ?? 'OFF')),
                      ],
                      selected: {act.on},
                      onSelectionChanged: (s) => setState(() => act.on = s.first),
                    );
                  }),
                  IconButton(
                    tooltip: 'Hapus perintah',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => drafts.remove(act)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Aturan baru' : 'Edit aturan',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('JIKA', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          for (final c in _conds) _conditionCard(c),
          if (_conds.length < 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _sensors.isEmpty
                    ? null
                    : () => setState(() => _conds.add(_CondDraft(deviceId: _sensors.first.id))),
                icon: const Icon(Icons.add),
                label: const Text('Kondisi'),
              ),
            ),
          if (_conds.length > 1)
            SegmentedButton<Joiner>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: Joiner.and, label: Text('DAN (semua harus benar)')),
                ButtonSegment(value: Joiner.or, label: Text('ATAU (salah satu)')),
              ],
              selected: {_joiner},
              onSelectionChanged: (s) => setState(() => _joiner = s.first),
            ),
          const SizedBox(height: 12),
          Text('MAKA', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _actionList(_then),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _actuators.isEmpty
                  ? null
                  : () => setState(() => _then.add(_ActDraft(deviceId: _actuators.first.id))),
              icon: const Icon(Icons.add),
              label: const Text('Perintah'),
            ),
          ),
          const SizedBox(height: 4),
          Text('LAINNYA (jika kondisi tidak terpenuhi, opsional)',
              style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          _actionList(_else),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _actuators.isEmpty
                  ? null
                  : () => setState(() => _else.add(_ActDraft(deviceId: _actuators.first.id))),
              icon: const Icon(Icons.add),
              label: const Text('Perintah'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(onPressed: _save, child: const Text('Simpan aturan')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}