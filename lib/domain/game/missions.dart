import 'game_models.dart';
import 'logic_blocks.dart';

final MissionDefinition missionAutoLamp = MissionDefinition(
  id: 'm1-auto-lamp',
  order: 1,
  title: 'Lampu Otomatis',
  goal: 'Buat lampu ruang tamu menyala otomatis saat ada orang dan mati saat ruangan kosong.',
  initialState: 'Lampu mati. Sensor gerak dan lampu belum dipasang.',
  devices: const [
    DeviceItem('motion1', DeviceKind.motionSensor),
    DeviceItem('lamp1', DeviceKind.lamp),
  ],
  slots: const [
    MountSlot('hall_sensor', SlotKind.sensor, 'Dinding lorong'),
    MountSlot('hall_ceiling', SlotKind.ceiling, 'Plafon ruang tamu'),
  ],
  scenario: const Scenario(
    durationSec: 20,
    initial: {EnvVar.temperature: 27, EnvVar.light: 300, EnvVar.motion: 0},
    events: [
      ScenarioEvent(5, EnvVar.motion, 1),
      ScenarioEvent(12, EnvVar.motion, 0),
    ],
  ),
  objectives: const [
    AllWiredObjective(
      id: 'wired',
      title: 'Semua perangkat terpasang dan terhubung',
      points: 30,
      hint: 'Pasang sensor gerak dan lampu, lalu sambungkan keduanya ke pin papan.',
    ),
    ActuatorWindowObjective(
      id: 'off-before',
      title: 'Lampu mati saat ruangan kosong',
      points: 20,
      hint: 'Lampu tidak boleh menyala sebelum ada gerakan.',
      deviceId: 'lamp1',
      on: false,
      fromSec: 0,
      toSec: 4.5,
    ),
    ActuatorWindowObjective(
      id: 'on-motion',
      title: 'Lampu menyala saat ada gerakan',
      points: 30,
      hint: 'Tambahkan aturan: JIKA gerakan terdeteksi MAKA lampu ON.',
      deviceId: 'lamp1',
      on: true,
      fromSec: 6,
      toSec: 11,
    ),
    ActuatorWindowObjective(
      id: 'off-after',
      title: 'Lampu mati lagi setelah orang pergi',
      points: 20,
      hint: 'Isi bagian LAINNYA supaya lampu OFF saat tidak ada gerakan.',
      deviceId: 'lamp1',
      on: false,
      fromSec: 13,
      toSec: 20,
    ),
  ],
  reference: const ReferenceSolution(
    installed: {'motion1': 'hall_sensor', 'lamp1': 'hall_ceiling'},
    wires: {'motion1': 'D1', 'lamp1': 'D2'},
    rules: [
      Rule(
        conditions: [Condition('motion1', CompareOp.gt, 0.5)],
        thenActions: [RuleAction('lamp1', true)],
        elseActions: [RuleAction('lamp1', false)],
      ),
    ],
  ),
);

final MissionDefinition missionSmartFan = MissionDefinition(
  id: 'm2-smart-fan',
  order: 2,
  title: 'Kipas Pintar',
  goal: 'Nyalakan kipas otomatis saat suhu ruangan di atas 30°C dan matikan saat sudah sejuk.',
  initialState:
      'Ruangan 26°C, kipas mati. Pada detik ke-4 suhu naik menjadi 34°C.',
  devices: const [
    DeviceItem('temp1', DeviceKind.tempSensor),
    DeviceItem('fan1', DeviceKind.fan),
  ],
  slots: const [
    MountSlot('room_sensor', SlotKind.sensor, 'Rak sensor'),
    MountSlot('room_wall', SlotKind.wall, 'Dinding ruangan'),
  ],
  scenario: const Scenario(
    durationSec: 20,
    initial: {EnvVar.temperature: 26, EnvVar.light: 300, EnvVar.motion: 0},
    events: [
      ScenarioEvent(4, EnvVar.temperature, 34),
      ScenarioEvent(14, EnvVar.temperature, 26),
    ],
  ),
  objectives: const [
    AllWiredObjective(
      id: 'wired',
      title: 'Semua perangkat terpasang dan terhubung',
      points: 15,
      hint: 'Pasang sensor suhu dan kipas, lalu sambungkan ke pin yang cocok.',
    ),
    ActuatorWindowObjective(
      id: 'off-cold',
      title: 'Kipas mati saat ruangan sejuk',
      points: 20,
      hint: 'Kipas tidak boleh menyala sebelum suhu naik.',
      deviceId: 'fan1',
      on: false,
      fromSec: 0,
      toSec: 3.5,
    ),
    ActuatorWindowObjective(
      id: 'on-hot',
      title: 'Kipas menyala saat panas',
      points: 30,
      hint: 'Tambahkan aturan: JIKA suhu > 30 MAKA kipas ON.',
      deviceId: 'fan1',
      on: true,
      fromSec: 5,
      toSec: 9,
    ),
    EnvBoundObjective(
      id: 'temp-bound',
      title: 'Suhu terkendali di bawah 33°C',
      points: 20,
      hint: 'Kipas harus menyala cukup lama agar suhu turun.',
      variable: EnvVar.temperature,
      maxValue: 33,
      fromSec: 8,
      toSec: 20,
    ),
    ActuatorWindowObjective(
      id: 'off-after',
      title: 'Kipas mati lagi setelah ruangan sejuk',
      points: 15,
      hint: 'Isi bagian LAINNYA supaya kipas OFF saat suhu sudah normal.',
      deviceId: 'fan1',
      on: false,
      fromSec: 16,
      toSec: 20,
    ),
  ],
  reference: const ReferenceSolution(
    installed: {'temp1': 'room_sensor', 'fan1': 'room_wall'},
    wires: {'temp1': 'D1', 'fan1': 'D2'},
    rules: [
      Rule(
        conditions: [Condition('temp1', CompareOp.gt, 30)],
        thenActions: [RuleAction('fan1', true)],
        elseActions: [RuleAction('fan1', false)],
      ),
    ],
  ),
);

final MissionDefinition missionHomeSecurity = MissionDefinition(
  id: 'm3-home-security',
  order: 3,
  title: 'Keamanan Rumah',
  goal: 'Bunyikan alarm dan kunci pintu hanya jika ada gerakan saat gelap. Siang hari alarm harus diam.',
  initialState: 'Siang hari (600 lux). Alarm diam, pintu terbuka. Malam tiba pada detik ke-8.',
  devices: const [
    DeviceItem('motion1', DeviceKind.motionSensor),
    DeviceItem('light1', DeviceKind.lightSensor),
    DeviceItem('buzzer1', DeviceKind.buzzer),
    DeviceItem('lock1', DeviceKind.doorLock),
  ],
  slots: const [
    MountSlot('door_sensor', SlotKind.sensor, 'Dekat pintu'),
    MountSlot('window_sensor', SlotKind.sensor, 'Dekat jendela'),
    MountSlot('wall_siren', SlotKind.wall, 'Dinding ruang tamu'),
    MountSlot('front_door', SlotKind.door, 'Pintu depan'),
  ],
  scenario: const Scenario(
    durationSec: 18,
    initial: {EnvVar.temperature: 27, EnvVar.light: 600, EnvVar.motion: 0},
    events: [
      ScenarioEvent(3, EnvVar.motion, 1),
      ScenarioEvent(6, EnvVar.motion, 0),
      ScenarioEvent(8, EnvVar.light, 100),
      ScenarioEvent(10, EnvVar.motion, 1),
      ScenarioEvent(14, EnvVar.motion, 0),
    ],
  ),
  objectives: const [
    AllWiredObjective(
      id: 'wired',
      title: 'Semua perangkat terpasang dan terhubung',
      points: 20,
      hint: 'Sensor cahaya butuh pin analog, kunci pintu butuh pin PWM.',
    ),
    ActuatorWindowObjective(
      id: 'quiet-day',
      title: 'Alarm diam saat ada gerakan di siang hari',
      points: 20,
      hint: 'Gabungkan dua kondisi dengan DAN: gerakan terdeteksi DAN cahaya rendah.',
      deviceId: 'buzzer1',
      on: false,
      fromSec: 3.5,
      toSec: 5.5,
    ),
    ActuatorWindowObjective(
      id: 'alarm-night',
      title: 'Alarm berbunyi saat ada gerakan di malam hari',
      points: 25,
      hint: 'JIKA gerakan terdeteksi DAN cahaya < 200 MAKA buzzer ON.',
      deviceId: 'buzzer1',
      on: true,
      fromSec: 11,
      toSec: 13,
    ),
    ActuatorWindowObjective(
      id: 'lock-night',
      title: 'Pintu terkunci saat alarm berbunyi',
      points: 15,
      hint: 'Tambahkan perintah kunci pintu ON pada aksi MAKA.',
      deviceId: 'lock1',
      on: true,
      fromSec: 11,
      toSec: 13,
    ),
    ActuatorWindowObjective(
      id: 'quiet-after',
      title: 'Alarm berhenti setelah gerakan selesai',
      points: 20,
      hint: 'Isi bagian LAINNYA supaya buzzer OFF.',
      deviceId: 'buzzer1',
      on: false,
      fromSec: 15,
      toSec: 18,
    ),
  ],
  reference: const ReferenceSolution(
    installed: {
      'motion1': 'door_sensor',
      'light1': 'window_sensor',
      'buzzer1': 'wall_siren',
      'lock1': 'front_door',
    },
    wires: {'motion1': 'D1', 'light1': 'A1', 'buzzer1': 'D2', 'lock1': 'P1'},
    rules: [
      Rule(
        conditions: [
          Condition('motion1', CompareOp.gt, 0.5),
          Condition('light1', CompareOp.lt, 200),
        ],
        joiner: Joiner.and,
        thenActions: [RuleAction('buzzer1', true), RuleAction('lock1', true)],
        elseActions: [RuleAction('buzzer1', false)],
      ),
    ],
  ),
);

/// Misi yang tertanam di aplikasi, terurut berdasarkan `order`.
final List<MissionDefinition> bundledMissions = [
  missionAutoLamp,
  missionSmartFan,
  missionHomeSecurity,
];

MissionDefinition? missionById(String id) {
  for (final m in bundledMissions) {
    if (m.id == id) return m;
  }
  return null;
}

/// Misi berikutnya setelah [mission], atau null jika ini misi terakhir.
MissionDefinition? nextMission(MissionDefinition mission) {
  MissionDefinition? next;
  for (final m in bundledMissions) {
    if (m.order > mission.order && (next == null || m.order < next.order)) {
      next = m;
    }
  }
  return next;
}
