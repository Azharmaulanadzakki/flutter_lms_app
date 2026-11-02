import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smk_tkj_lms/domain/entities/quiz_test.dart';

import '../../../domain/entities/admin_question.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/question_cubits.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminQuestionsPage extends StatelessWidget {
  const AdminQuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<QuestionOverviewCubit>();

    return SafeArea(
      child: BlocBuilder<QuestionOverviewCubit, QuestionOverviewState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == AdminLoadStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat daftar soal.',
                onRetry: cubit.load,
              );
            }
            return const LoadingView();
          }

          if (overview.groups.isEmpty) {
            return const EmptyView(
              icon: Icons.quiz_outlined,
              message:
                  'Belum ada course. Buat course dan test di tab Course dulu.',
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Soal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pilih test untuk mengelola soalnya. Test dibuat di tab Course.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                for (final group in overview.groups) ...[
                  Text(
                    group.course.title.isEmpty
                        ? '(tanpa judul)'
                        : group.course.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (group.tests.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Belum ada test. Buat Pre-Test atau Post-Test di detail course.',
                        style: theme.textTheme.bodySmall,
                      ),
                    )
                  else
                    for (final summary in group.tests) ...[
                      _TestTile(
                        summary: summary,
                        onTap: () => context
                            .push('/admin/test/${summary.test.id}/questions')
                            .then((_) {
                              if (context.mounted) cubit.load();
                            }),
                      ),
                      const SizedBox(height: 10),
                    ],
                  const SizedBox(height: 14),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TestTile extends StatelessWidget {
  const _TestTile({required this.summary, required this.onTap});

  final TestQuestionSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final test = summary.test;
    final count = summary.count;
    final problem = test.isActive && count.active == 0;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: problem ? Colors.red.shade300 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: const Icon(Icons.quiz_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.type.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${count.total} soal · ${count.active} aktif',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          test.isActive
                              ? StatusPill(
                                  label: 'Test aktif',
                                  color: Colors.green.shade700,
                                )
                              : StatusPill(
                                  label: 'Test nonaktif',
                                  color: Colors.orange.shade800,
                                ),
                          if (problem)
                            StatusPill(
                              label: 'Tidak ada soal aktif',
                              color: Colors.red.shade700,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
