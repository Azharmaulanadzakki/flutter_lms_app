import 'package:flutter/material.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../../domain/game/game_session.dart';
import '../../../../../domain/game/simulation_engine.dart';
import 'device_icons.dart';

/// Tampilan 2D pengganti jika panggung 3D gagal. Misi tetap bisa dimainkan.
class FallbackStage extends StatelessWidget {
  const FallbackStage({
    super.key,
    required this.mission,
    required this.session,
    required this.frame,
    required this.onRetry,
  });

  final MissionDefinition mission;
  final GameSession session;
  final TickSnapshot frame;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obs = frame.observed;
    final circuit = session.circuit;

    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Panggung 3D tidak tersedia. Mode 2D aktif, misi tetap bisa dimainkan.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Coba 3D')),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill('Suhu ${obs[EnvVar.temperature]!.toStringAsFixed(1)}°C'),
              _Pill('Cahaya ${obs[EnvVar.light]!.round()} lux'),
              _Pill(
                obs[EnvVar.motion]! > 0.5 ? 'Ada gerakan' : 'Tidak ada gerakan',
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final d in mission.devices)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(deviceIcon(d.kind), color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                        Text(
                          circuit.isInstalled(d.id)
                              ? 'Terpasang · ${circuit.isWired(d.id) ? 'kabel ke ${circuit.pinOf(d.id)}' : 'belum ada kabel'}'
                              : 'Di rak',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (d.kind.isActuator)
                    Text(
                      d.kind.stateLabel(frame.actuators[d.id] == true),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
