import 'package:flutter/material.dart';

import '../../../../../domain/game/game_models.dart';

IconData deviceIcon(DeviceKind kind) => switch (kind) {
  DeviceKind.tempSensor => Icons.thermostat,
  DeviceKind.motionSensor => Icons.directions_run,
  DeviceKind.lightSensor => Icons.light_mode,
  DeviceKind.lamp => Icons.lightbulb,
  DeviceKind.fan => Icons.air,
  DeviceKind.buzzer => Icons.notifications_active,
  DeviceKind.doorLock => Icons.lock,
};
