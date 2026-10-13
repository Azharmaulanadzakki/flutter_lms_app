import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../domain/entities/progress_overview.dart';
import 'timeline_row.dart';

/// Riwayat pembelajaran berbentuk timeline.
class HistoryList extends StatelessWidget {
  const HistoryList({super.key, required this.entries});

  final List<HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _row(entries[i], isLast: i == entries.length - 1),
      ],
    );
  }

  Widget _row(HistoryEntry entry, {required bool isLast}) {
    final IconData icon;
    final Color color;
    final String title;

    switch (entry.type) {
      case HistoryType.courseStarted:
        icon = Icons.play_circle_outline;
        color = AppColors.primary;
        title = 'Memulai course';
      case HistoryType.preTest:
        icon = Icons.quiz_outlined;
        color = AppColors.primary;
        title = 'Pre-test selesai · Nilai ${scoreText(entry.score)}';
      case HistoryType.postTest:
        icon = Icons.fact_check_outlined;
        color = AppColors.primary;
        title = 'Post-test selesai · Nilai ${scoreText(entry.score)}';
      case HistoryType.courseCompleted:
        icon = Icons.emoji_events;
        color = Colors.green.shade700;
        title = 'Course selesai';
    }

    return TimelineRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: entry.courseTitle,
      time: formatDateTime(entry.at),
      isLast: isLast,
    );
  }
}
