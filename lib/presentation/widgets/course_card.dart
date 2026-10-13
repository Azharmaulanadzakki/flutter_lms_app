import 'package:flutter/material.dart';

import '../../domain/entities/course_item.dart';
import 'course_status_badge.dart';
import 'course_thumbnail.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.item, required this.onTap});

  final CourseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = item.course;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  CourseThumbnail(url: course.thumbnailUrl, height: 110),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: CourseStatusBadge(status: item.status),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      children: [
                        _Info(icon: Icons.signal_cellular_alt, text: course.level),
                        _Info(
                          icon: Icons.schedule,
                          text: '${course.duration} menit',
                        ),
                        _Info(
                          icon: Icons.menu_book_outlined,
                          text: '${item.materialCount} materi',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${item.percentage}%',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: style?.color),
        const SizedBox(width: 4),
        Text(text, style: style),
      ],
    );
  }
}