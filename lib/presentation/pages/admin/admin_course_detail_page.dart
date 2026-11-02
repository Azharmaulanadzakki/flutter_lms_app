import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/admin_entities.dart';
import '../../../domain/entities/course_material.dart';
import '../../../domain/entities/quiz_test.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_course_detail_cubit.dart';
import '../../blocs/admin/admin_status.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/state_views.dart';
import '../student/course_detail/widgets/material_tile.dart';
import 'admin_widgets.dart';

class AdminCourseDetailPage extends StatelessWidget {
  const AdminCourseDetailPage({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminCourseDetailCubit>()..load(courseId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Kelola Course')),
        body: BlocConsumer<AdminCourseDetailCubit, AdminCourseDetailState>(
          listenWhen: (prev, curr) =>
              curr.error != null || curr.info != null || curr.deleted,
          listener: (context, state) {
            if (state.deleted) {
              showAppSnackBar(context, 'Course dihapus.');
              context.pop();
            } else if (state.error != null) {
              showAppSnackBar(context, state.error!, isError: true);
            } else if (state.info != null) {
              showAppSnackBar(context, state.info!);
            }
          },
          builder: (context, state) {
            final cubit = context.read<AdminCourseDetailCubit>();
            final detail = state.detail;

            if (detail == null) {
              if (state.status == AdminLoadStatus.failure) {
                return ErrorView(
                  message: state.loadError ?? 'Gagal memuat course.',
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
                    child: _Content(
                      detail: detail,
                      busy: state.isBusy,
                      courseId: courseId,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.detail,
    required this.busy,
    required this.courseId,
  });

  final AdminCourseDetail detail;
  final bool busy;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AdminCourseDetailCubit>();
    final course = detail.course;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        // ---------- Info course ----------
        Container(
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
                course.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  course.isPublished
                      ? StatusPill(
                          label: 'Dipublikasikan',
                          color: Colors.green.shade700,
                        )
                      : StatusPill(
                          label: 'Draft',
                          color: Colors.orange.shade800,
                        ),
                  if (course.hasGame)
                    const StatusPill(
                      label: 'Simulasi 3D',
                      color: Colors.indigo,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${course.level} · ${course.duration} menit · urutan ${course.order}',
                style: theme.textTheme.bodySmall,
              ),
              if (course.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(course.description),
              ],
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dipublikasikan'),
                subtitle: const Text(
                  'Siswa hanya melihat course yang dipublikasikan.',
                ),
                value: course.isPublished,
                onChanged: busy ? null : cubit.setCoursePublished,
              ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => context
                                .push('/admin/course/$courseId/edit')
                                .then((_) => cubit.reload()),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      onPressed: busy
                          ? null
                          : () async {
                              final ok = await confirmAction(
                                context,
                                title: 'Hapus course?',
                                message:
                                    'Course "${course.title}" akan dihapus permanen. '
                                    'Jika sudah dipakai siswa, sebaiknya gunakan Sembunyikan '
                                    '(matikan saklar Dipublikasikan).',
                                confirmLabel: 'Hapus',
                                destructive: true,
                              );
                              if (ok) cubit.deleteCourse();
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ---------- Materi ----------
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Materi (${detail.materials.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => context
                        .push('/admin/course/$courseId/material/new')
                        .then((_) => cubit.reload()),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (detail.materials.isEmpty)
          Text(
            'Belum ada materi untuk course ini.',
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final m in detail.materials) ...[
            _MaterialRow(
              material: m,
              busy: busy,
              onEdit: () => context
                  .push('/admin/course/$courseId/material/${m.id}')
                  .then((_) => cubit.reload()),
              onTogglePublished: () =>
                  cubit.setMaterialPublished(m.id, !m.isPublished),
              onDelete: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Hapus materi?',
                  message: 'Materi "${m.title}" akan dihapus permanen.',
                  confirmLabel: 'Hapus',
                  destructive: true,
                );
                if (ok) cubit.deleteMaterial(m.id);
              },
            ),
            const SizedBox(height: 10),
          ],

        // ---------- Test ----------
        const SizedBox(height: 24),
        Text(
          'Test',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (final type in TestType.values) ...[
          _TestCard(
            courseId: courseId,
            type: type,
            info: detail.testOf(type),
            busy: busy,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({
    required this.material,
    required this.busy,
    required this.onEdit,
    required this.onTogglePublished,
    required this.onDelete,
  });

  final CourseMaterial material;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onTogglePublished;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              '${material.order}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  material.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      materialTypeIcon(material.type),
                      size: 14,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      materialTypeLabel(material.type),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    material.isPublished
                        ? StatusPill(
                            label: 'Tayang',
                            color: Colors.green.shade700,
                          )
                        : StatusPill(
                            label: 'Draft',
                            color: Colors.orange.shade800,
                          ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  onEdit();
                case 'toggle':
                  onTogglePublished();
                case 'delete':
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(
                  material.isPublished ? 'Sembunyikan' : 'Publikasikan',
                ),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TestCard extends StatelessWidget {
  const _TestCard({
    required this.courseId,
    required this.type,
    required this.info,
    required this.busy,
  });

  final String courseId;
  final TestType type;
  final AdminTestInfo? info;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AdminCourseDetailCubit>();
    final test = info?.test;

    return Container(
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
            type.label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          if (test == null) ...[
            Text('Belum dibuat.', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: busy
                  ? null
                  : () => context
                        .push('/admin/course/$courseId/test/${type.value}')
                        .then((_) => cubit.reload()),
              icon: const Icon(Icons.add),
              label: Text('Buat ${type.label}'),
            ),
          ] else ...[
            Text(test.title, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${info!.questionCount} soal di bank soal · '
              'tampil ${test.questionCount == 0 ? 'semua' : '${test.questionCount}'} soal · '
              '${test.hasTimer ? '${test.durationMinutes} menit' : 'tanpa timer'}',
              style: theme.textTheme.bodySmall,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Aktif'),
              subtitle: const Text('Test nonaktif tidak tampil untuk siswa.'),
              value: test.isActive,
              onChanged: busy
                  ? null
                  : (value) => cubit.setTestActive(test.id, value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => context
                            .push('/admin/course/$courseId/test/${type.value}')
                            .then((_) => cubit.reload()),
                  icon: const Icon(Icons.tune),
                  label: const Text('Pengaturan'),
                ),
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => context
                            .push('/admin/test/${test.id}/questions')
                            .then((_) => cubit.reload()),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('Kelola Soal'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: busy
                      ? null
                      : () async {
                          final ok = await confirmAction(
                            context,
                            title: 'Hapus ${type.label}?',
                            message:
                                'Pengaturan ${type.label} akan dihapus. Test yang masih punya soal tidak bisa dihapus.',
                            confirmLabel: 'Hapus',
                            destructive: true,
                          );
                          if (ok) cubit.deleteTest(test.id);
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
