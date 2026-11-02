import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/course_detail.dart';
import '../../../../domain/entities/course_item.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/course_detail/course_detail_bloc.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/course_status_badge.dart';
import '../../../widgets/course_thumbnail.dart';
import '../../../widgets/improvement_card.dart';
import '../../../widgets/state_views.dart';
import 'widgets/activity_tile.dart';
import 'widgets/material_tile.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) =>
          sl<CourseDetailBloc>()
            ..add(CourseDetailRequested(userId: uid, courseId: courseId)),
      child: _CourseDetailView(userId: uid, courseId: courseId),
    );
  }
}

class _CourseDetailView extends StatelessWidget {
  const _CourseDetailView({required this.userId, required this.courseId});

  final String userId;
  final String courseId;

  void _reload(BuildContext context) {
    context.read<CourseDetailBloc>().add(
      CourseDetailRequested(userId: userId, courseId: courseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Course')),
      body: BlocBuilder<CourseDetailBloc, CourseDetailState>(
        builder: (context, state) {
          final detail = state.detail;

          if (detail == null) {
            if (state.status == CourseDetailStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat course.',
                onRetry: () => _reload(context),
              );
            }
            return const LoadingView();
          }

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<CourseDetailBloc>();
              _reload(context);
              await bloc.stream.firstWhere(
                (s) => s.status != CourseDetailStatus.loading,
              );
            },
            child: _DetailContent(
              detail: detail,
              // Dipanggil setelah kembali dari materi atau test,
              // supaya centang, nilai, dan progress diperbarui.
              onReturn: () {
                if (context.mounted) _reload(context);
              },
            ),
          );
        },
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.detail, required this.onReturn});

  final CourseDetail detail;
  final VoidCallback onReturn;

  void _soon(BuildContext context, String message) =>
      showAppSnackBar(context, message);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = detail.item;
    final course = item.course;
    final progress = item.progress;

    final completedIds = progress?.completedMaterialIds ?? const <String>[];
    final gameDone = progress?.gameCompleted ?? false;
    final preDone = progress?.preTestCompleted ?? false;
    final postDone = progress?.postTestCompleted ?? false;

    final lock = item.postTestLock;
    final postUnlocked = lock == PostTestLock.none;

    final pre = progress?.preTestScore;
    final post = progress?.postTestScore;
    final improvement = (pre != null && post != null) ? post - pre : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        CourseThumbnail(url: course.thumbnailUrl, height: 180),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseStatusBadge(status: item.status),
              const SizedBox(height: 10),
              Text(
                course.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${course.level} · ${course.duration} menit · ${item.materialCount} materi',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),

              // Deskripsi
              const _SectionTitle('Deskripsi'),
              Text(course.description, style: theme.textTheme.bodyMedium),

              // Tujuan pembelajaran
              if (course.objectives.isNotEmpty) ...[
                const SizedBox(height: 24),
                const _SectionTitle('Tujuan Pembelajaran'),
                for (final o in course.objectives)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(o)),
                      ],
                    ),
                  ),
              ],

              // Progress
              const SizedBox(height: 24),
              const _SectionTitle('Progress'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: item.percentage / 100,
                              minHeight: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${item.percentage}%',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _MiniStat(label: 'Pre-test', value: _fmt(pre)),
                        _MiniStat(label: 'Post-test', value: _fmt(post)),
                        _MiniStat(
                          label: 'Peningkatan',
                          value: improvement == null
                              ? '-'
                              : '${improvement >= 0 ? '+' : ''}${improvement.round()}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (post != null) ...[
                const SizedBox(height: 12),
                ImprovementCard(pre: pre, post: post),
              ],

              // Pre-test
              const SizedBox(height: 24),
              const _SectionTitle('Pre-Test'),
              ActivityTile(
                icon: Icons.quiz_outlined,
                title: 'Pre-Test',
                subtitle: preDone
                    ? 'Nilai: ${_fmt(pre)}'
                    : 'Ukur pengetahuan awalmu',
                state: preDone ? ActivityState.done : ActivityState.available,
                onTap: () => context
                    .push('/course/${course.id}/test/pre')
                    .then((_) => onReturn()),
              ),

              // Materi
              const SizedBox(height: 24),
              _SectionTitle('Materi (${detail.materials.length})'),
              if (detail.materials.isEmpty)
                const Text('Belum ada materi untuk course ini.')
              else
                for (var i = 0; i < detail.materials.length; i++) ...[
                  MaterialTile(
                    index: i + 1,
                    material: detail.materials[i],
                    done: completedIds.contains(detail.materials[i].id),
                    onTap: () => context
                        .push(
                          '/course/${course.id}/material/${detail.materials[i].id}',
                        )
                        .then((_) => onReturn()),
                  ),
                  const SizedBox(height: 10),
                ],

              // Game
              if (course.hasGame) ...[
                const SizedBox(height: 14),
                const _SectionTitle('Simulasi 3D'),
                ActivityTile(
                  icon: Icons.home_work_outlined,
                  title: 'Simulasi Smart Home (IoT)',
                  subtitle: gameDone
                      ? 'Simulasi selesai${progress?.gameScore == null ? '' : ' · nilai ${_fmt(progress?.gameScore)}'}'
                      : 'Rakit, sambung kabel, dan program rumah pintar',
                  state: gameDone
                      ? ActivityState.done
                      : ActivityState.available,
                  onTap: () => context
                      .push('/course/${course.id}/game')
                      .then((_) => onReturn()),
                ),
              ],

              // Post-test
              const SizedBox(height: 24),
              const _SectionTitle('Post-Test'),
              ActivityTile(
                icon: Icons.fact_check_outlined,
                title: 'Post-Test',
                subtitle: postDone
                    ? 'Nilai: ${_fmt(post)}'
                    : postUnlocked
                    ? 'Ukur peningkatan belajarmu'
                    : lock.message,
                state: postDone
                    ? ActivityState.done
                    : postUnlocked
                    ? ActivityState.available
                    : ActivityState.locked,
                onTap: () {
                  if (!postUnlocked && !postDone) {
                    _soon(context, '${lock.message}.');
                    return;
                  }
                  context
                      .push('/course/${course.id}/test/post')
                      .then((_) => onReturn());
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(double? v) => v == null ? '-' : '${v.round()}';
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
