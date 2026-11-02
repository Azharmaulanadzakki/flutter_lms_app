import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/game/game_models.dart';
import '../../../../blocs/game/game_cubits.dart';

class MissionTab extends StatelessWidget {
  const MissionTab({super.key, required this.mission});

  final MissionDefinition mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) => !identical(p.session, c.session),
      builder: (context, state) {
        final s = state.session;
        final total = mission.devices.length;
        final installed = s.circuit.installed.length;
        final wired = s.circuit.wires.length;

        final steps = <(String, bool, String)>[
          ('Baca tujuan misi', true, ''),
          ('Pasang komponen', installed == total, '$installed/$total'),
          ('Hubungkan kabel', wired == total, '$wired/$total'),
          ('Susun blok logika', s.rules.isNotEmpty, '${s.rules.length} aturan'),
          ('Jalankan simulasi', s.runs > 0, s.runs == 0 ? '' : '${s.runs}x'),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Tujuan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(mission.goal),
            const SizedBox(height: 12),
            Text(
              'Kondisi awal',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(mission.initialState),
            const SizedBox(height: 16),
            Text(
              'Langkah',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            for (final step in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      step.$2
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: step.$2 ? Colors.green.shade600 : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(step.$1)),
                    if (step.$3.isNotEmpty)
                      Text(step.$3, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Yang dinilai',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            for (final o in mission.objectives)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.flag_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(o.title)),
                    Text('${o.points}', style: theme.textTheme.labelLarge),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
