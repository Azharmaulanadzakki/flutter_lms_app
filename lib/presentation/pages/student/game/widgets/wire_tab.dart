import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../blocs/game/game_cubits.dart';
import 'device_icons.dart';

class WireTab extends StatelessWidget {
  const WireTab({super.key, required this.mission});

  final MissionDefinition mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) => !identical(p.session.circuit, c.session.circuit),
      builder: (context, state) {
        final cubit = context.read<GameSessionCubit>();
        final circuit = state.session.circuit;
        final installed = [
          for (final d in mission.devices)
            if (circuit.isInstalled(d.id)) d,
        ];

        if (installed.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Pasang perangkat dulu di tab Pasang, baru kabelnya bisa disambung.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final used = [
          for (final e in circuit.wires.entries)
            '${e.value} → ${mission.deviceById(e.key)?.displayName ?? e.key}',
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pilih pin papan kontrol untuk tiap perangkat. Jenis pin harus cocok.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final device in installed)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(deviceIcon(device.kind), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            device.displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Butuh pin: ${device.kind.acceptedPins.map((p) => p.label).join(' atau ')}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final pin in mission.pins)
                          ChoiceChip(
                            label: Text('${pin.id} · ${pin.kind.label}'),
                            selected: circuit.pinOf(device.id) == pin.id,
                            onSelected: (selected) => cubit.connect(
                              device.id,
                              selected ? pin.id : null,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            if (used.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Pin terpakai: ${used.join(', ')}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        );
      },
    );
  }
}
