import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/admin_entities.dart';
import '../../blocs/admin/admin_courses_cubit.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/class_overview_cubit.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminCoursesPage extends StatelessWidget {
  const AdminCoursesPage({super.key});

  void _reloadAll(BuildContext context) {
    context.read<AdminCoursesCubit>().load();
    context.read<ClassOverviewCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/course/new').then((_) {
          if (context.mounted) _reloadAll(context);
        }),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Course'),
      ),
      body: SafeArea(
        child: BlocBuilder<AdminCoursesCubit, AdminCoursesState>(
          builder: (context, state) {
            final rows = state.rows;

            if (rows == null) {
              if (state.status == AdminLoadStatus.failure) {
                return ErrorView(
                  message: state.error ?? 'Gagal memuat daftar course.',
                  onRetry: () => context.read<AdminCoursesCubit>().load(),
                );
              }
              return const LoadingView();
            }

            if (rows.isEmpty) {
              return const EmptyView(
                icon: Icons.school_outlined,
                message: 'Belum ada course. Tekan Tambah Course untuk membuat yang pertama.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<AdminCoursesCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  Text(
                    'Course (${rows.length})',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tekan course untuk mengelola materi dan test.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  for (final row in rows) ...[
                    _CourseRowCard(
                      row: row,
                      onTap: () => context
                          .push('/admin/course/${row.course.id}')
                          .then((_) {
                        if (context.mounted) _reloadAll(context);
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CourseRowCard extends StatelessWidget {
  const _CourseRowCard({required this.row, required this.onTap});

  final AdminCourseRow row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final course = row.course;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${course.order}',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        course.title.isEmpty ? '(tanpa judul)' : course.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    course.isPublished
                        ? StatusPill(
                            label: 'Dipublikasikan',
                            color: Colors.green.shade700,
                          )
                        : StatusPill(label: 'Draft', color: Colors.orange.shade800),
                    if (course.hasGame)
                      const StatusPill(label: 'Simulasi 3D', color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '${course.level} · ${course.duration} menit · '
                  '${row.materialCount} materi (${row.publishedMaterialCount} tayang)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}