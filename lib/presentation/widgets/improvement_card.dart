import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

String _fmt(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// Perbandingan nilai pre-test dan post-test beserta peningkatannya.
class ImprovementCard extends StatelessWidget {
  const ImprovementCard({super.key, required this.pre, required this.post});

  /// Null jika nilai pre-test tidak tersedia.
  final double? pre;
  final double post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preScore = pre;
    final delta = preScore == null ? null : post - preScore;

    final Color deltaColor;
    final String deltaText;
    if (delta == null) {
      deltaColor = Colors.blueGrey;
      deltaText = 'Nilai pre-test tidak tersedia';
    } else if (delta > 0) {
      deltaColor = Colors.green.shade700;
      deltaText = 'Naik +${_fmt(delta)} poin';
    } else if (delta < 0) {
      deltaColor = Colors.red.shade700;
      deltaText = 'Turun ${_fmt(delta)} poin';
    } else {
      deltaColor = Colors.blueGrey;
      deltaText = 'Nilai tidak berubah';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Perkembangan Belajar',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          if (preScore != null) ...[
            _ScoreBar(label: 'Pre-test', value: preScore, color: Colors.blueGrey),
            const SizedBox(height: 10),
          ],
          _ScoreBar(label: 'Post-test', value: post, color: AppColors.primary),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: deltaColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  delta == null || delta == 0
                      ? Icons.remove
                      : delta > 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                  size: 18,
                  color: deltaColor,
                ),
                const SizedBox(width: 6),
                Text(
                  deltaText,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: deltaColor,
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

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: theme.textTheme.bodySmall),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              minHeight: 14,
              color: color,
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            _fmt(value),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Banner yang muncul saat course baru saja selesai.
class CourseCompletedBanner extends StatelessWidget {
  const CourseCompletedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Colors.green.shade700;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selamat! Course ini sudah selesai 🎉',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}