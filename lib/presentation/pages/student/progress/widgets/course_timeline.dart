import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/formatters.dart';
import 'timeline_row.dart';

class TimelineStep {
  const TimelineStep({
    required this.title,
    required this.subtitle,
    required this.done,
    this.time,
  });

  final String title;
  final String subtitle;
  final bool done;
  final DateTime? time;
}

/// Perjalanan belajar satu course. Langkah pertama yang belum selesai
/// ditandai sebagai langkah saat ini.
class CourseTimeline extends StatelessWidget {
  const CourseTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    final current = steps.indexWhere((s) => !s.done);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          TimelineRow(
            icon: steps[i].done
                ? Icons.check_circle
                : (i == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked),
            color: steps[i].done
                ? Colors.green.shade600
                : (i == current ? AppColors.primary : Colors.grey),
            title: steps[i].title,
            subtitle: steps[i].subtitle,
            time: steps[i].time == null ? null : formatDateTime(steps[i].time!),
            isLast: i == steps.length - 1,
            dimmed: !steps[i].done && i != current,
          ),
      ],
    );
  }
}
