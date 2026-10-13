import 'package:flutter/material.dart';

import '../../../../domain/entities/course_item.dart';

class ContinueCourseCard extends StatelessWidget {
  const ContinueCourseCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final CourseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = item.status == CourseStatus.notStarted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            item.course.title,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.course.level} · ${item.course.duration} menit',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${item.materialsDone} / ${item.materialCount} materi',
                style: theme.textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${item.percentage}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onTap,
            child: Text(isNew ? 'Mulai Belajar' : 'Lanjutkan Belajar'),
          ),
        ],
      ),
    );
  }
}