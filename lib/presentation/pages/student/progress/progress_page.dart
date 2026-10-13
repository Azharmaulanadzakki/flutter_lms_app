import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/formatters.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/progress/progress_bloc.dart';
import '../../../widgets/state_views.dart';
import '../widgets/overall_progress_card.dart';
import '../widgets/stat_card.dart';
import 'widgets/course_progress_tile.dart';
import 'widgets/history_list.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  static const _previewCount = 8;
  bool _showAll = false;

  void _load() {
    final uid = context.read<AuthBloc>().state.user?.uid;
    if (uid == null) return;
    context.read<ProgressBloc>().add(ProgressRequested(uid));
  }

  Future<void> _refresh() async {
    final bloc = context.read<ProgressBloc>();
    _load();
    await bloc.stream.firstWhere((s) => s.status != ProgressStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: BlocBuilder<ProgressBloc, ProgressState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == ProgressStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat progress.',
                onRetry: _load,
              );
            }
            return const LoadingView();
          }

          if (overview.items.isEmpty) {
            return EmptyView(
              icon: Icons.insights_outlined,
              message: 'Belum ada course yang tersedia.',
              onAction: _load,
            );
          }

          final history = overview.history;
          final shown = _showAll
              ? history
              : history.take(_previewCount).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Progress',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pantau perkembangan belajarmu.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
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
                  CourseProgressTile(
                    item: item,
                    onTap: () => context.push('/progress/${item.course.id}'),
                  ),
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
                  Text(
                    'Belum ada aktivitas. Mulai dengan mengerjakan pre-test di salah satu course.',
                    style: theme.textTheme.bodyMedium,
                  )
                else ...[
                  HistoryList(entries: shown),
                  if (history.length > _previewCount)
                    TextButton(
                      onPressed: () => setState(() => _showAll = !_showAll),
                      child: Text(
                        _showAll
                            ? 'Tampilkan lebih sedikit'
                            : 'Tampilkan semua (${history.length})',
                      ),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
