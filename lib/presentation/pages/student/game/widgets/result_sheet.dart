import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/game/game_models.dart';
// import '../../../../../domain/game/missions.dart';
import '../../../../../domain/game/simulation_engine.dart';
import '../../../../blocs/game/game_cubits.dart';

enum ResultAction { edit, next, leave }

class ResultSheet extends StatelessWidget {
  const ResultSheet({super.key, required this.mission, this.next});

  final MissionDefinition mission;

  /// Misi berikutnya dalam lingkup yang sama, atau null jika ini yang terakhir.
  final MissionDefinition? next;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) => p.outcome != c.outcome,
      builder: (context, state) {
        final outcome = state.outcome;
        if (outcome == null) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final report = outcome.report;
        final completed = report.completed;
        // final next = nextMission(mission);

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                completed ? Icons.emoji_events : Icons.build_circle_outlined,
                size: 56,
                color: completed ? Colors.amber.shade700 : Colors.blueGrey,
              ),
              const SizedBox(height: 8),
              Text(
                completed ? 'Misi selesai!' : 'Belum berhasil',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      i < outcome.stars ? Icons.star : Icons.star_border,
                      size: 36,
                      color: Colors.amber.shade700,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Nilai ${report.score}',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Poin objektif ${report.basePoints}'
                '${report.penalty > 0 ? ' − ${report.penalty} (${report.mistakes} kesalahan)' : ''}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              if (outcome.courseGameDone) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade700),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_events, color: Colors.green.shade700),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Simulasi course selesai! Post-test terbuka setelah hasil terkirim.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final r in report.results)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        r.passed ? Icons.check_circle : Icons.cancel,
                        size: 20,
                        color: r.passed
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.objective.title),
                            if (!r.passed)
                              Text(
                                r.objective.hint,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.points}/${r.objective.points}',
                        style: theme.textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              if (report.warnings.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final w in report.warnings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 18,
                          color: Colors.orange.shade800,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(w, style: theme.textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 12),
              Text(
                outcome.statusText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: outcome.saveError != null
                      ? theme.colorScheme.error
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              if (completed) ...[
                if (next != null)
                  FilledButton(
                    onPressed: () => Navigator.pop(context, ResultAction.next),
                    child: Text('Misi berikutnya: ${next?.title}'),
                  ),
                if (next != null) const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, ResultAction.leave),
                  child: const Text('Kembali ke daftar misi'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, ResultAction.edit),
                  child: const Text(
                    'Perbaiki rakitan untuk nilai lebih tinggi',
                  ),
                ),
              ] else
                FilledButton(
                  onPressed: () => Navigator.pop(context, ResultAction.edit),
                  child: const Text('Perbaiki rakitan'),
                ),
            ],
          ),
        );
      },
    );
  }
}
