import 'package:flutter/material.dart';

import '../../domain/entities/course_item.dart';

String courseStatusLabel(CourseStatus status) {
  switch (status) {
    case CourseStatus.notStarted:
      return 'Belum Dimulai';
    case CourseStatus.inProgress:
      return 'Sedang Berjalan';
    case CourseStatus.completed:
      return 'Selesai';
  }
}

class CourseStatusBadge extends StatelessWidget {
  const CourseStatusBadge({super.key, required this.status});

  final CourseStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case CourseStatus.notStarted:
        color = Colors.blueGrey;
      case CourseStatus.inProgress:
        color = Colors.orange.shade800;
      case CourseStatus.completed:
        color = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        courseStatusLabel(status),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
