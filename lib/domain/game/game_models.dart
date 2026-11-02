import 'logic_blocks.dart';

/// Jenis pin pada papan kontrol (ESP32 virtual).
enum PinKind { digital, analog, pwm }

extension PinKindX on PinKind {
  String get label => switch (this) {
    PinKind.digital => 'Digital',
    PinKind.analog => 'Analog',
    PinKind.pwm => 'PWM',
  };
}

/// Besaran lingkungan yang dibaca sensor.
enum EnvVar { temperature, light, motion }

extension EnvVarX on EnvVar {
  String get label => switch (this) {
    EnvVar.temperature => 'Suhu',
    EnvVar.light => 'Cahaya',
    EnvVar.motion => 'Gerakan',
  };

  String get unit => switch (this) {
    EnvVar.temperature => '°C',
    EnvVar.light => 'lux',
    EnvVar.motion => '',
  };
}

/// Jenis dudukan tempat perangkat dipasang.
enum SlotKind { sensor, ceiling, wall, door }

extension SlotKindX on SlotKind {
  String get label => switch (this) {
    SlotKind.sensor => 'Dudukan sensor',
    SlotKind.ceiling => 'Plafon',
    SlotKind.wall => 'Dinding',
    SlotKind.door => 'Pintu',
  };
}

enum DeviceKind {
  tempSensor,
  motionSensor,
  lightSensor,
  lamp,
  fan,
  buzzer,
  doorLock,
}

extension DeviceKindX on DeviceKind {
  String get label => switch (this) {
    DeviceKind.tempSensor => 'Sensor Suhu (DHT22)',
    DeviceKind.motionSensor => 'Sensor Gerak (PIR)',
    DeviceKind.lightSensor => 'Sensor Cahaya (LDR)',
    DeviceKind.lamp => 'Lampu',
    DeviceKind.fan => 'Kipas',
    DeviceKind.buzzer => 'Buzzer Alarm',
    DeviceKind.doorLock => 'Kunci Pintu (Servo)',
  };

  bool get isSensor =>
      this == DeviceKind.tempSensor ||
      this == DeviceKind.motionSensor ||
      this == DeviceKind.lightSensor;

  bool get isActuator => !isSensor;

  /// Besaran yang dibaca, khusus sensor.
  EnvVar? get senses => switch (this) {
    DeviceKind.tempSensor => EnvVar.temperature,
    DeviceKind.motionSensor => EnvVar.motion,
    DeviceKind.lightSensor => EnvVar.light,
    _ => null,
  };

  SlotKind get slotKind => switch (this) {
    DeviceKind.tempSensor ||
    DeviceKind.motionSensor ||
    DeviceKind.lightSensor => SlotKind.sensor,
    DeviceKind.lamp => SlotKind.ceiling,
    DeviceKind.fan || DeviceKind.buzzer => SlotKind.wall,
    DeviceKind.doorLock => SlotKind.door,
  };

  /// Jenis pin papan yang bisa dipakai perangkat ini.
  Set<PinKind> get acceptedPins => switch (this) {
    DeviceKind.tempSensor || DeviceKind.motionSensor => const {PinKind.digital},
    DeviceKind.lightSensor => const {PinKind.analog},
    DeviceKind.lamp ||
    DeviceKind.fan ||
    DeviceKind.buzzer => const {PinKind.digital, PinKind.pwm},
    DeviceKind.doorLock => const {PinKind.pwm},
  };

  String stateLabel(bool on) => switch (this) {
    DeviceKind.lamp => on ? 'Menyala' : 'Mati',
    DeviceKind.fan => on ? 'Berputar' : 'Mati',
    DeviceKind.buzzer => on ? 'Berbunyi' : 'Diam',
    DeviceKind.doorLock => on ? 'Terkunci' : 'Terbuka',
    _ => on ? 'Aktif' : 'Nonaktif',
  };
}

/// Satu komponen yang tersedia di rak pada sebuah misi.
class DeviceItem {
  const DeviceItem(this.id, this.kind, [this.name = '']);

  final String id;
  final DeviceKind kind;
  final String name;

  String get displayName => name.isEmpty ? kind.label : name;
}

/// Tempat memasang perangkat di ruangan.
class MountSlot {
  const MountSlot(this.id, this.kind, this.label);

  final String id;
  final SlotKind kind;
  final String label;
}

/// Pin pada papan kontrol.
class PinSpec {
  const PinSpec(this.id, this.kind);

  final String id;
  final PinKind kind;
}

const List<PinSpec> defaultBoardPins = [
  PinSpec('D1', PinKind.digital),
  PinSpec('D2', PinKind.digital),
  PinSpec('D3', PinKind.digital),
  PinSpec('A1', PinKind.analog),
  PinSpec('P1', PinKind.pwm),
  PinSpec('P2', PinKind.pwm),
];

/// Perubahan kondisi lingkungan pada detik tertentu.
class ScenarioEvent {
  const ScenarioEvent(this.atSec, this.variable, this.value);

  final double atSec;
  final EnvVar variable;
  final double value;
}

/// Skenario lingkungan selama simulasi.
class Scenario {
  const Scenario({
    required this.durationSec,
    required this.initial,
    this.events = const [],
    this.coolRatePerSec = 0.7,
    this.warmRatePerSec = 0.3,
    this.maxCooling = 12,
  });

  final int durationSec;
  final Map<EnvVar, double> initial;
  final List<ScenarioEvent> events;

  /// Kipas menyala: suhu terbaca turun sebesar ini per detik.
  final double coolRatePerSec;

  /// Kipas mati: pengaruh pendinginan hilang sebesar ini per detik.
  final double warmRatePerSec;
  final double maxCooling;
}

/// Syarat penilaian sebuah misi. Jumlah poin seluruh objektif harus 100.
sealed class Objective {
  const Objective({
    required this.id,
    required this.title,
    required this.points,
    required this.hint,
  });

  final String id;
  final String title;
  final int points;

  /// Petunjuk yang ditampilkan jika objektif gagal.
  final String hint;
}

/// Semua perangkat sudah terpasang dan terhubung ke pin.
final class AllWiredObjective extends Objective {
  const AllWiredObjective({
    required super.id,
    required super.title,
    required super.points,
    required super.hint,
  });
}

/// Perangkat keluaran harus berada pada keadaan [on] sepanjang rentang waktu.
final class ActuatorWindowObjective extends Objective {
  const ActuatorWindowObjective({
    required super.id,
    required super.title,
    required super.points,
    required super.hint,
    required this.deviceId,
    required this.on,
    required this.fromSec,
    required this.toSec,
  });

  final String deviceId;
  final bool on;
  final double fromSec;
  final double toSec;
}

/// Nilai yang terbaca sensor tidak boleh melebihi [maxValue] pada rentang waktu.
final class EnvBoundObjective extends Objective {
  const EnvBoundObjective({
    required super.id,
    required super.title,
    required super.points,
    required super.hint,
    required this.variable,
    required this.maxValue,
    required this.fromSec,
    required this.toSec,
  });

  final EnvVar variable;
  final double maxValue;
  final double fromSec;
  final double toSec;
}

/// Jawaban acuan. Dipakai untuk menguji misi dan nanti untuk petunjuk guru.
class ReferenceSolution {
  const ReferenceSolution({
    required this.installed,
    required this.wires,
    required this.rules,
  });

  /// ID perangkat → ID dudukan.
  final Map<String, String> installed;

  /// ID perangkat → ID pin.
  final Map<String, String> wires;
  final List<Rule> rules;
}

class MissionDefinition {
  const MissionDefinition({
    required this.id,
    required this.order,
    required this.title,
    required this.goal,
    required this.initialState,
    required this.devices,
    required this.slots,
    required this.scenario,
    required this.objectives,
    required this.reference,
    this.pins = defaultBoardPins,
    this.initialOn = const {},
  });

  final String id;
  final int order;
  final String title;

  /// Tujuan misi, tampil di awal.
  final String goal;

  /// Kondisi awal rumah, tampil di awal.
  final String initialState;
  final List<DeviceItem> devices;
  final List<MountSlot> slots;
  final List<PinSpec> pins;
  final Scenario scenario;
  final List<Objective> objectives;
  final ReferenceSolution reference;

  /// Keadaan awal perangkat keluaran. Yang tidak disebut dianggap mati.
  final Map<String, bool> initialOn;

  DeviceItem? deviceById(String id) {
    for (final d in devices) {
      if (d.id == id) return d;
    }
    return null;
  }

  MountSlot? slotById(String id) {
    for (final s in slots) {
      if (s.id == id) return s;
    }
    return null;
  }

  PinSpec? pinById(String id) {
    for (final p in pins) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Memeriksa kesalahan penulisan misi. Daftar kosong berarti misi valid.
  List<String> validate() {
    final problems = <String>[];

    void checkUnique(String what, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) problems.add('$what ganda: $id');
      }
    }

    checkUnique('Perangkat', devices.map((d) => d.id));
    checkUnique('Dudukan', slots.map((s) => s.id));
    checkUnique('Pin', pins.map((p) => p.id));
    checkUnique('Objektif', objectives.map((o) => o.id));

    final total = objectives.fold<int>(0, (sum, o) => sum + o.points);
    if (total != 100) {
      problems.add('Total poin objektif harus 100 (sekarang $total).');
    }

    for (final o in objectives) {
      if (o is ActuatorWindowObjective) {
        final device = deviceById(o.deviceId);
        if (device == null || !device.kind.isActuator) {
          problems.add(
            'Objektif ${o.id}: perangkat keluaran ${o.deviceId} tidak ada.',
          );
        }
        if (o.fromSec > o.toSec || o.toSec > scenario.durationSec) {
          problems.add('Objektif ${o.id}: rentang waktu tidak valid.');
        }
      } else if (o is EnvBoundObjective) {
        if (o.fromSec > o.toSec || o.toSec > scenario.durationSec) {
          problems.add('Objektif ${o.id}: rentang waktu tidak valid.');
        }
      }
    }

    return problems;
  }
}
