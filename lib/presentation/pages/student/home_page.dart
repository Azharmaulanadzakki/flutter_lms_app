import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/course_item.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../widgets/state_views.dart';
import 'widgets/continue_course_card.dart';
import 'widgets/overall_progress_card.dart';
import 'widgets/recommended_course_tile.dart';
import 'widgets/stat_card.dart';

/// Dashboard siswa.
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onSeeAllCourses});

  /// Pindah ke tab Course.
  final VoidCallback onSeeAllCourses;

  void _load(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid;
    if (uid == null) return;
    context.read<DashboardBloc>().add(DashboardRequested(uid));
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<DashboardBloc>();
    final uid = context.read<AuthBloc>().state.user?.uid;
    if (uid == null) return;
    bloc.add(DashboardRequested(uid));
    await bloc.stream.firstWhere((s) => s.status != DashboardStatus.loading);
  }

  void _openCourse(BuildContext context, CourseItem item) {
    context.push('/course/${item.course.id}').then((_) {
      if (context.mounted) _load(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthBloc>().state.user;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return SafeArea(
      child: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final data = state.data;

          if (data == null) {
            if (state.status == DashboardStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat dashboard.',
                onRetry: () => _load(context),
              );
            }
            return const LoadingView();
          }

          if (data.items.isEmpty) {
            return EmptyView(
              icon: Icons.school_outlined,
              message: 'Belum ada course yang tersedia.',
              onAction: () => _load(context),
            );
          }

          final current = data.continueCourse;
          final recommended = data.recommended;
          final latest = data.latestScore;

          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Halo, ${firstName.isEmpty ? 'Siswa' : firstName} ',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ayo lanjutkan belajarmu hari ini.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                OverallProgressCard(
                  percent: data.overallProgress,
                  completed: data.completedCount,
                  total: data.items.length,
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Course selesai',
                          value: '${data.completedCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.play_circle_outline,
                          label: 'Sedang berjalan',
                          value: '${data.inProgressCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'Nilai terbaru',
                          value: latest == null ? '-' : '${latest.round()}',
                        ),
                      ),
                    ],
                  ),
                ),
                if (current != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    current.status == CourseStatus.notStarted
                        ? 'Mulai Course Pertamamu'
                        : 'Lanjutkan Belajar',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ContinueCourseCard(
                    item: current,
                    onTap: () => _openCourse(context, current),
                  ),
                ],
                if (recommended.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Rekomendasi Course',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        onPressed: onSeeAllCourses,
                        child: const Text('Lihat semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  for (final item in recommended) ...[
                    RecommendedCourseTile(
                      item: item,
                      onTap: () => _openCourse(context, item),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}