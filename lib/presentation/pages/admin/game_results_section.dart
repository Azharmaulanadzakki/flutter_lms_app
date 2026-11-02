import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/game/game_result_view.dart';
import '../../../domain/game/missions.dart';

/// Riwayat hasil simulasi seorang siswa, terbaru di atas.
class GameResultsSection extends StatelessWidget {
  const GameResultsSection({super.key, required this.results});

  final List<GameResultView> results;

  static const _limit = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = results.take(_limit).toList();
    final done = results.where((r) => r.completed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hasil Simulasi (IoT)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          results.isEmpty
              ? 'Belum ada hasil simulasi yang terkirim.'
              : '${results.length} percobaan, $done berhasil',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final r in shown)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  r.completed ? Icons.check_circle : Icons.cancel,
                  color: r.completed
                      ? Colors.green.shade600
                      : Colors.red.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        missionById(r.missionId)?.title ?? r.missionId,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Nilai ${r.score} · ${r.errors} kesalahan · ${r.durationSec} dtk',
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        formatDateTime(r.playedAt),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${r.score}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        if (results.length > _limit)
          Text(
            'dan ${results.length - _limit} percobaan lainnya.',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}
