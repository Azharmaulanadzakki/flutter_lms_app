import 'package:flutter/material.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../../domain/game/simulation_engine.dart';

/// Versi web: panggung 3D hanya tersedia di aplikasi Android.
class SmartHomeStage extends StatelessWidget {
  const SmartHomeStage({
    super.key,
    required this.mission,
    required this.installed,
    required this.wires,
    this.frame,
    this.highlightKind,
    this.onSlotTap,
    this.onFailed,
  });

  final MissionDefinition mission;
  final Map<String, String> installed;
  final Map<String, String> wires;
  final TickSnapshot? frame;
  final SlotKind? highlightKind;
  final ValueChanged<String>? onSlotTap;
  final VoidCallback? onFailed;

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF0F172A),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Panggung 3D hanya tersedia di aplikasi Android.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
