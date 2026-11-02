import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/game/course_game.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/course_detail/course_detail_bloc.dart';
import '../../../widgets/state_views.dart';
import 'game_home_page.dart';

/// Daftar misi simulasi milik satu course.
class CourseGamePage extends StatelessWidget {
  const CourseGamePage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) =>
          sl<CourseDetailBloc>()
            ..add(CourseDetailRequested(userId: uid, courseId: courseId)),
      child: BlocBuilder<CourseDetailBloc, CourseDetailState>(
        builder: (context, state) {
          final detail = state.detail;

          if (detail == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Simulasi')),
              body: state.status == CourseDetailStatus.failure
                  ? ErrorView(
                      message: state.error ?? 'Gagal memuat course.',
                      onRetry: () => context.read<CourseDetailBloc>().add(
                        CourseDetailRequested(userId: uid, courseId: courseId),
                      ),
                    )
                  : const LoadingView(),
            );
          }

          final course = detail.item.course;
          if (!course.hasGame) {
            return Scaffold(
              appBar: AppBar(title: const Text('Simulasi')),
              body: const EmptyView(
                icon: Icons.sports_esports_outlined,
                message: 'Course ini tidak memakai simulasi.',
              ),
            );
          }

          return GameHomePage(
            courseId: course.id,
            courseTitle: course.title,
            missions: missionsForCourse(course.missionIds),
            serverGameDone: detail.item.progress?.gameCompleted ?? false,
          );
        },
      ),
    );
  }
}
