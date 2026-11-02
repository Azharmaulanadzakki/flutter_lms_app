import 'game_models.dart';
import 'logic_blocks.dart';

String _num(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

String describeCondition(MissionDefinition mission, Condition c) {
  final device = mission.deviceById(c.deviceId);
  final name = device?.displayName ?? c.deviceId;

  if (device != null && device.kind == DeviceKind.motionSensor) {
    final high = c.op.test(1, c.threshold);
    final low = c.op.test(0, c.threshold);
    if (high && !low) return '$name mendeteksi gerakan';
    if (!high && low) return '$name tidak mendeteksi gerakan';
  }

  final unit = device?.kind.senses?.unit ?? '';
  final unitText = unit.isEmpty ? '' : (unit == '°C' ? unit : ' $unit');
  return '$name ${c.op.symbol} ${_num(c.threshold)}$unitText';
}

String describeAction(MissionDefinition mission, RuleAction a) {
  final device = mission.deviceById(a.deviceId);
  if (device == null) return '${a.deviceId} → ${a.on ? 'ON' : 'OFF'}';
  return '${device.displayName} → ${device.kind.stateLabel(a.on)}';
}

/// Teks aturan untuk ditampilkan di kartu.
String describeRule(MissionDefinition mission, Rule rule) {
  final joiner = rule.joiner == Joiner.and ? ' DAN ' : ' ATAU ';
  final conditions = rule.conditions
      .map((c) => describeCondition(mission, c))
      .join(joiner);
  final then = rule.thenActions.isEmpty
      ? '-'
      : rule.thenActions.map((a) => describeAction(mission, a)).join(', ');

  final buffer = StringBuffer('JIKA $conditions\nMAKA $then');
  if (rule.elseActions.isNotEmpty) {
    buffer.write(
      '\nLAINNYA ${rule.elseActions.map((a) => describeAction(mission, a)).join(', ')}',
    );
  }
  return buffer.toString();
}
