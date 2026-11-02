import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/admin_question.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/question_cubits.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminQuestionListPage extends StatelessWidget {
  const AdminQuestionListPage({super.key, required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuestionListCubit>()..load(testId),
      child: _View(testId: testId),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.testId});

  final String testId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<QuestionListCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Soal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context
            .push('/admin/test/$testId/questions/new')
            .then((_) => cubit.reload()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Soal'),
      ),
      body: BlocConsumer<QuestionListCubit, QuestionListState>(
        listenWhen: (prev, curr) => curr.error != null || curr.info != null,
        listener: (context, state) {
          if (state.error != null) {
            showAppSnackBar(context, state.error!, isError: true);
          } else if (state.info != null) {
            showAppSnackBar(context, state.info!);
          }
        },
        builder: (context, state) {
          final data = state.data;

          if (data == null) {
            if (state.status == AdminLoadStatus.failure) {
              return ErrorView(
                message: state.loadError ?? 'Gagal memuat soal.',
                onRetry: cubit.reload,
              );
            }
            return const LoadingView();
          }

          return Column(
            children: [
              if (state.isBusy) const LinearProgressIndicator(minHeight: 3),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: cubit.reload,
                  child: ReorderableListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    buildDefaultDragHandles: false,
                    header: _Header(data: data),
                    footer: data.questions.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'Belum ada soal. Tekan Tambah Soal untuk membuat yang pertama.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : null,
                    itemCount: data.questions.length,
                    onReorder: cubit.reorder,
                    itemBuilder: (context, index) {
                      final q = data.questions[index];
                      return _QuestionCard(
                        key: ValueKey(q.id),
                        index: index,
                        question: q,
                        busy: state.isBusy,
                        testId: testId,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final QuestionListData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final test = data.test;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (data.courseTitle.isNotEmpty)
                Text(data.courseTitle, style: theme.textTheme.bodySmall),
              const SizedBox(height: 10),
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
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${data.questions.length} soal · ${data.activeCount} aktif · '
                'tampil ${test.questionCount == 0 ? 'semua' : '${test.questionCount}'} soal per siswa',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (data.attemptCount > 0) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${data.attemptCount} siswa sudah mengerjakan test ini. Nilai mereka tidak '
              'berubah jika soal diedit, tetapi pembahasan yang mereka lihat mengikuti '
              'kunci terbaru. Untuk menarik soal, lebih aman menonaktifkannya daripada menghapus.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          'Tahan ikon ⠿ lalu geser untuk mengubah urutan soal.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    super.key,
    required this.index,
    required this.question,
    required this.busy,
    required this.testId,
  });

  final int index;
  final AdminQuestion question;
  final bool busy;
  final String testId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<QuestionListCubit>();
    final q = question;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(8, 12, 4, 12),
      decoration: BoxDecoration(
        color: q.isActive ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 8, 4),
              child: Icon(Icons.drag_indicator),
            ),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${index + 1}',
              style: theme.textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.text.isEmpty ? '(tanpa teks)' : q.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    q.isActive
                        ? StatusPill(label: 'Aktif', color: Colors.green.shade700)
                        : StatusPill(label: 'Nonaktif', color: Colors.orange.shade800),
                    q.hasKey
                        ? StatusPill(
                            label: 'Kunci: ${optionLetter(q.correctIndex)}',
                            color: Colors.indigo,
                          )
                        : StatusPill(
                            label: 'Tanpa kunci',
                            color: Colors.red.shade700,
                          ),
                    StatusPill(label: '${q.points} poin', color: Colors.blueGrey),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  context
                      .push('/admin/test/$testId/questions/${q.id}')
                      .then((_) => cubit.reload());
                case 'duplicate':
                  cubit.duplicate(q.id);
                case 'toggle':
                  cubit.setActive(q, !q.isActive);
                case 'delete':
                  final ok = await confirmAction(
                    context,
                    title: 'Hapus soal?',
                    message:
                        'Soal ini dan kunci jawabannya akan dihapus permanen. '
                        'Untuk menarik soal sementara, gunakan Nonaktifkan.',
                    confirmLabel: 'Hapus',
                    destructive: true,
                  );
                  if (ok) cubit.delete(q);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplikasi')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(q.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}