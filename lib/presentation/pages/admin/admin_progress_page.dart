import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/class_overview_cubit.dart';
import '../../widgets/state_views.dart';
import '../student/widgets/stat_card.dart';

/// Tab Progress admin: statistik kelas dan per course.
class AdminProgressPage extends StatelessWidget {
  const AdminProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: BlocBuilder<ClassOverviewCubit, ClassOverviewState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == AdminLoadStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat progress kelas.',
                onRetry: () => context.read<ClassOverviewCubit>().load(),
              );
            }
            return const LoadingView();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ClassOverviewCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Progress Kelas',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _ClassCard(
                  percent: overview.averagePercent,
                  studentCount: overview.studentCount,
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.quiz_outlined,
                          label: 'Rata-rata pre-test',
                          value: scoreText(overview.averagePre),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.fact_check_outlined,
                          label: 'Rata-rata post-test',
                          value: scoreText(overview.averagePost),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.trending_up,
                          label: 'Rata-rata peningkatan',
                          value: deltaText(overview.averageImprovement),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/admin/weights').then((_) {
                    if (context.mounted) {
                      context.read<ClassOverviewCubit>().load();
                    }
                  }),
                  icon: const Icon(Icons.tune),
                  label: const Text('Atur Bobot Progress'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Statistik per Course',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (overview.courseStats.isEmpty)
                  Text(
                    'Belum ada course yang dipublikasikan.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  for (final stats in overview.courseStats) ...[
                    _CourseStatsTile(stats: stats),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({required this.percent, required this.studentCount});

  final double percent;
  final int studentCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${percent.round()}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
                  'Rata-rata Progress Kelas',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari $studentCount siswa',
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseStatsTile extends StatelessWidget {
  const _CourseStatsTile({required this.stats});

  final CourseStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            stats.course.title,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (stats.averagePercent / 100).clamp(0.0, 1.0),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${stats.averagePercent.round()}%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai ${stats.startedCount} · Selesai ${stats.completedCount} '
            'dari ${stats.studentCount} siswa',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Mini(label: 'Pre-test', value: scoreText(stats.averagePre)),
              _Mini(label: 'Post-test', value: scoreText(stats.averagePost)),
              _Mini(
                label: 'Peningkatan',
                value: deltaText(stats.averageImprovement),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value});

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
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}