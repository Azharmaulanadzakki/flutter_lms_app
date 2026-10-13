import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../domain/entities/course_item.dart';
import '../../../../domain/entities/progress_overview.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/progress/progress_bloc.dart';
import '../../../widgets/course_status_badge.dart';
import '../../../widgets/improvement_card.dart';
import '../../../widgets/state_views.dart';
import '../widgets/stat_card.dart';
import 'widgets/course_timeline.dart';

class ProgressDetailPage extends StatelessWidget {
  const ProgressDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<ProgressBloc>()..add(ProgressRequested(uid)),
      child: _View(userId: uid, courseId: courseId),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.userId, required this.courseId});

  final String userId;
  final String courseId;

  void _reload(BuildContext context) =>
      context.read<ProgressBloc>().add(ProgressRequested(userId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Course')),
      body: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == ProgressStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat progress.',
                onRetry: () => _reload(context),
              );
            }
            return const LoadingView();
          }

          final matches =
              overview.items.where((i) => i.course.id == courseId).toList();
          if (matches.isEmpty) {
            return const EmptyView(
              icon: Icons.school_outlined,
              message: 'Course tidak tersedia.',
            );
          }

          final item = matches.first;
          final entries =
              overview.history.where((h) => h.courseId == courseId).toList();

          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<ProgressBloc>();
              _reload(context);
              await bloc.stream
                  .firstWhere((s) => s.status != ProgressStatus.loading);
            },
            child: _Content(
              item: item,
              entries: entries,
              onOpenCourse: () => context
                  .push('/course/$courseId')
                  .then((_) {
                    if (context.mounted) _reload(context);
                  }),
            ),
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.item,
    required this.entries,
    required this.onOpenCourse,
  });

  final CourseItem item;
  final List<HistoryEntry> entries;
  final VoidCallback onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = item.course;
    final p = item.progress;
    final pre = p?.preTestScore;
    final post = p?.postTestScore;
    final improvement = (pre != null && post != null) ? post - pre : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          course.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          '${course.level} · ${course.duration} menit',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _HeaderCard(item: item),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.quiz_outlined,
                  label: 'Pre-test',
                  value: scoreText(pre),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.fact_check_outlined,
                  label: 'Post-test',
                  value: scoreText(post),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.trending_up,
                  label: 'Peningkatan',
                  value: deltaText(improvement),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _MaterialsCard(item: item),
        if (course.hasGame) ...[
          const SizedBox(height: 12),
          _GameCard(done: p?.gameCompleted ?? false),
        ],
        if (post != null) ...[
          const SizedBox(height: 12),
          ImprovementCard(pre: pre, post: post),
        ],
        const SizedBox(height: 24),
        Text(
          'Perjalanan Belajar',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        CourseTimeline(steps: _buildSteps(item, entries)),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: onOpenCourse,
          child: Text(
            item.status == CourseStatus.notStarted
                ? 'Mulai Course'
                : 'Buka Course',
          ),
        ),
      ],
    );
  }
}

List<TimelineStep> _buildSteps(CourseItem item, List<HistoryEntry> entries) {
  final p = item.progress;

  DateTime? timeOf(HistoryType type) {
    for (final e in entries) {
      if (e.type == type) return e.at;
    }
    return null;
  }

  final preDone = p?.preTestCompleted ?? false;
  final postDone = p?.postTestCompleted ?? false;
  final materialsDone =
      item.materialCount > 0 && item.materialsDone >= item.materialCount;
  final lock = item.postTestLock;

  final String postSubtitle;
  if (postDone) {
    postSubtitle = 'Nilai ${scoreText(p?.postTestScore)}';
  } else if (lock != PostTestLock.none) {
    postSubtitle = lock.message;
  } else {
    postSubtitle = 'Belum dikerjakan';
  }

  return [
    TimelineStep(
      title: 'Memulai course',
      subtitle: p?.startedAt != null ? 'Sudah dimulai' : 'Belum dimulai',
      done: p?.startedAt != null,
      time: p?.startedAt,
    ),
    TimelineStep(
      title: 'Pre-test',
      subtitle: preDone
          ? 'Nilai ${scoreText(p?.preTestScore)}'
          : 'Belum dikerjakan',
      done: preDone,
      time: timeOf(HistoryType.preTest),
    ),
    TimelineStep(
      title: 'Materi',
      subtitle: item.materialCount == 0
          ? 'Belum ada materi'
          : '${item.materialsDone} dari ${item.materialCount} materi selesai',
      done: materialsDone,
    ),
    if (item.course.hasGame)
      TimelineStep(
        title: 'Simulasi 3D',
        subtitle:
            (p?.gameCompleted ?? false) ? 'Simulasi selesai' : 'Belum dimainkan',
        done: p?.gameCompleted ?? false,
      ),
    TimelineStep(
      title: 'Post-test',
      subtitle: postSubtitle,
      done: postDone,
      time: timeOf(HistoryType.postTest),
    ),
    TimelineStep(
      title: 'Course selesai',
      subtitle: item.status == CourseStatus.completed
          ? 'Selamat, course ini sudah selesai'
          : 'Selesaikan semua langkah di atas',
      done: item.status == CourseStatus.completed,
      time: p?.completedAt,
    ),
  ];
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.item});

  final CourseItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
                  child: CircularProgressIndicator(
                    value: item.percentage / 100,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFE2E8F0),
                  ),
                ),
                Text(
                  '${item.percentage}%',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progress Course',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CourseStatusBadge(status: item.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MaterialsCard extends StatelessWidget {
  const _MaterialsCard({required this.item});

  final CourseItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = item.materialCount;
    final done = item.materialsDone;
    final complete = total > 0 && done >= total;

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
          Row(
            children: [
              const Icon(Icons.menu_book_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Materi',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                total == 0 ? '-' : '$done / $total',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (complete) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 20, color: Colors.green.shade600),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (done / total).clamp(0.0, 1.0).toDouble(),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = done ? Colors.green.shade700 : Colors.blueGrey;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Simulasi 3D',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Icon(done ? Icons.check_circle : Icons.hourglass_empty,
              size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            done ? 'Selesai' : 'Belum',
            style: theme.textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}