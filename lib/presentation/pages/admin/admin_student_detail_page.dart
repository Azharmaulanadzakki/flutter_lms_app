import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smk_tkj_lms/domain/game/game_result_view.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/progress_overview.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/admin_student_detail_cubit.dart';
import '../../widgets/state_views.dart';
import '../student/progress/widgets/course_progress_tile.dart';
import '../student/progress/widgets/history_list.dart';
import '../student/widgets/overall_progress_card.dart';
import '../student/widgets/stat_card.dart';
import 'game_results_section.dart';
import '../../../domain/game/game_result_view.dart';

class AdminStudentDetailPage extends StatelessWidget {
  const AdminStudentDetailPage({super.key, required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminStudentDetailCubit>()..load(uid),
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail Siswa')),
        body: BlocBuilder<AdminStudentDetailCubit, AdminStudentDetailState>(
          builder: (context, state) {
            final user = state.user;
            final overview = state.overview;

            if (user == null || overview == null) {
              if (state.status == AdminLoadStatus.failure) {
                return ErrorView(
                  message: state.error ?? 'Gagal memuat data siswa.',
                  onRetry: () =>
                      context.read<AdminStudentDetailCubit>().load(uid),
                );
              }
              return const LoadingView();
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<AdminStudentDetailCubit>().load(uid),
              child: _Content(
                user: user,
                overview: overview,
                results: state.results,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.user,
    required this.overview,
    required this.results,
  });

  final UserEntity user;
  final ProgressOverview overview;
  final List<GameResultView> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = overview.history.take(20).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(user.email, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Terdaftar: ${user.createdAt == null ? '-' : formatDateTime(user.createdAt!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Terakhir masuk: ${user.lastLogin == null ? '-' : formatDateTime(user.lastLogin!)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OverallProgressCard(
          percent: overview.overallPercent,
          completed: overview.completedCount,
          total: overview.items.length,
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
        const SizedBox(height: 24),
        Text(
          'Progress per Course',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in overview.items) ...[
          CourseProgressTile(item: item),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text(
          'Riwayat Pembelajaran',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Text('Belum ada aktivitas.', style: theme.textTheme.bodyMedium)
        else
          HistoryList(entries: history),
        const SizedBox(height: 24),
        GameResultsSection(results: results),
      ],
    );
  }
}
