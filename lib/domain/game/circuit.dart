import 'game_models.dart';

/// Alasan sebuah pemasangan atau penyambungan ditolak.
enum CircuitIssue {
  unknownDevice,
  unknownSlot,
  slotKindMismatch,
  slotTaken,
  notInstalled,
  unknownPin,
  pinIncompatible,
  pinTaken,
}

extension CircuitIssueX on CircuitIssue {
  String get message => switch (this) {
    CircuitIssue.unknownDevice => 'Perangkat tidak dikenal.',
    CircuitIssue.unknownSlot => 'Dudukan tidak dikenal.',
    CircuitIssue.slotKindMismatch =>
      'Perangkat ini tidak cocok dipasang di dudukan tersebut.',
    CircuitIssue.slotTaken => 'Dudukan itu sudah dipakai perangkat lain.',
    CircuitIssue.notInstalled =>
      'Pasang perangkat ke dudukannya dulu sebelum menyambung kabel.',
    CircuitIssue.unknownPin => 'Pin tidak dikenal.',
    CircuitIssue.pinIncompatible =>
      'Jenis pin tidak cocok untuk perangkat ini.',
    CircuitIssue.pinTaken => 'Pin itu sudah dipakai perangkat lain.',
  };

  /// Kesalahan yang berasal dari pilihan pemain dan dihitung sebagai kesalahan.
  /// ID tidak dikenal adalah kesalahan program, bukan kesalahan pemain.
  bool get isMistake =>
      this != CircuitIssue.unknownDevice &&
      this != CircuitIssue.unknownSlot &&
      this != CircuitIssue.unknownPin;
}

class CircuitChange {
  const CircuitChange(this.circuit, [this.issue]);

  /// Rangkaian setelah perubahan. Tidak berubah jika [issue] terisi.
  final Circuit circuit;
  final CircuitIssue? issue;

  bool get ok => issue == null;
}

/// Rangkaian rakitan pemain: perangkat yang dipasang dan kabel ke pin.
/// Tidak bisa diubah. Setiap perubahan menghasilkan rangkaian baru.
class Circuit {
  Circuit._(
    this.mission,
    Map<String, String> installed,
    Map<String, String> wires,
  ) : installed = Map.unmodifiable(installed),
      wires = Map.unmodifiable(wires);

  factory Circuit.empty(MissionDefinition mission) =>
      Circuit._(mission, const {}, const {});

  /// Memulihkan rangkaian dari JSON. Entri yang tidak valid dilewati.
  factory Circuit.fromJson(MissionDefinition mission, Object? json) {
    var circuit = Circuit.empty(mission);
    if (json is! Map) return circuit;

    final installed = json['installed'];
    if (installed is Map) {
      installed.forEach((device, slot) {
        if (device is String && slot is String) {
          circuit = circuit.install(device, slot).circuit;
        }
      });
    }

    final wires = json['wires'];
    if (wires is Map) {
      wires.forEach((device, pin) {
        if (device is String && pin is String) {
          circuit = circuit.connect(device, pin).circuit;
        }
      });
    }
    return circuit;
  }

  final MissionDefinition mission;

  /// ID perangkat → ID dudukan.
  final Map<String, String> installed;

  /// ID perangkat → ID pin.
  final Map<String, String> wires;

  bool isInstalled(String deviceId) => installed.containsKey(deviceId);
  bool isWired(String deviceId) => wires.containsKey(deviceId);
  String? slotOf(String deviceId) => installed[deviceId];
  String? pinOf(String deviceId) => wires[deviceId];

  /// Semua perangkat misi sudah terpasang dan terhubung.
  bool get isComplete =>
      mission.devices.every((d) => isInstalled(d.id) && isWired(d.id));

  /// Memasang perangkat. Jika sudah terpasang, perangkat dipindah dan
  /// kabelnya tetap.
  CircuitChange install(String deviceId, String slotId) {
    final device = mission.deviceById(deviceId);
    if (device == null) return CircuitChange(this, CircuitIssue.unknownDevice);

    final slot = mission.slotById(slotId);
    if (slot == null) return CircuitChange(this, CircuitIssue.unknownSlot);

    if (slot.kind != device.kind.slotKind) {
      return CircuitChange(this, CircuitIssue.slotKindMismatch);
    }
    final taken = installed.entries.any(
      (e) => e.value == slotId && e.key != deviceId,
    );
    if (taken) return CircuitChange(this, CircuitIssue.slotTaken);

    return CircuitChange(
      Circuit._(mission, {...installed, deviceId: slotId}, wires),
    );
  }

  /// Melepas perangkat dari dudukan, beserta kabelnya.
  CircuitChange uninstall(String deviceId) {
    if (mission.deviceById(deviceId) == null) {
      return CircuitChange(this, CircuitIssue.unknownDevice);
    }
    return CircuitChange(
      Circuit._(
        mission,
        {...installed}..remove(deviceId),
        {...wires}..remove(deviceId),
      ),
    );
  }

  /// Menyambung kabel dari perangkat ke pin papan.
  CircuitChange connect(String deviceId, String pinId) {
    final device = mission.deviceById(deviceId);
    if (device == null) return CircuitChange(this, CircuitIssue.unknownDevice);
    if (!isInstalled(deviceId))
      return CircuitChange(this, CircuitIssue.notInstalled);

    final pin = mission.pinById(pinId);
    if (pin == null) return CircuitChange(this, CircuitIssue.unknownPin);

    if (!device.kind.acceptedPins.contains(pin.kind)) {
      return CircuitChange(this, CircuitIssue.pinIncompatible);
    }
    final taken = wires.entries.any(
      (e) => e.value == pinId && e.key != deviceId,
    );
    if (taken) return CircuitChange(this, CircuitIssue.pinTaken);

    return CircuitChange(
      Circuit._(mission, installed, {...wires, deviceId: pinId}),
    );
  }

  CircuitChange disconnect(String deviceId) {
    if (mission.deviceById(deviceId) == null) {
      return CircuitChange(this, CircuitIssue.unknownDevice);
    }
    return CircuitChange(
      Circuit._(mission, installed, {...wires}..remove(deviceId)),
    );
  }

  Map<String, dynamic> toJson() => {'installed': installed, 'wires': wires};
}

/// Rangkaian dari jawaban acuan misi. Melempar StateError jika acuannya salah.
Circuit referenceCircuit(MissionDefinition mission) {
  var circuit = Circuit.empty(mission);

  for (final entry in mission.reference.installed.entries) {
    final change = circuit.install(entry.key, entry.value);
    if (!change.ok) {
      throw StateError(
        'Acuan ${mission.id}: pasang ${entry.key} ke ${entry.value}: ${change.issue!.message}',
      );
    }
    circuit = change.circuit;
  }
  for (final entry in mission.reference.wires.entries) {
    final change = circuit.connect(entry.key, entry.value);
    if (!change.ok) {
      throw StateError(
        'Acuan ${mission.id}: sambung ${entry.key} ke ${entry.value}: ${change.issue!.message}',
      );
    }
    circuit = change.circuit;
  }
  return circuit;
}
