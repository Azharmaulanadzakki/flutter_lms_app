import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/admin_entities.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/class_overview_cubit.dart';
import '../../widgets/state_views.dart';

class AdminStudentsPage extends StatefulWidget {
  const AdminStudentsPage({super.key});

  @override
  State<AdminStudentsPage> createState() => _AdminStudentsPageState();
}

class _AdminStudentsPageState extends State<AdminStudentsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: BlocBuilder<ClassOverviewCubit, ClassOverviewState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == AdminStatusAlias.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat daftar siswa.',
                onRetry: () => context.read<ClassOverviewCubit>().load(),
              );
            }
            return const LoadingView();
          }

          if (overview.students.isEmpty) {
            return const EmptyView(
              icon: Icons.groups_outlined,
              message: 'Belum ada siswa yang mendaftar.',
            );
          }

          final q = _query.trim().toLowerCase();
          final filtered = q.isEmpty
              ? overview.students
              : overview.students
                  .where((s) =>
                      s.user.name.toLowerCase().contains(q) ||
                      s.user.email.toLowerCase().contains(q))
                  .toList();

          return RefreshIndicator(
            onRefresh: () => context.read<ClassOverviewCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Siswa (${overview.students.length})',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari nama atau email',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Tidak ada siswa yang cocok.')),
                  )
                else
                  for (final s in filtered) ...[
                    _StudentTile(
                      summary: s,
                      onTap: () => context.push('/admin/student/${s.user.uid}'),
                    ),
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

/// Alias supaya file ini tidak perlu mengimpor enum dari dua tempat.
typedef AdminStatusAlias = AdminLoadStatus;

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.summary, required this.onTap});

  final StudentSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = summary.user;
    final overview = summary.overview;
    final percent = overview.overallPercent;

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
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        user.name.isEmpty ? '?' : user.name[0].toUpperCase(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: theme.textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(user.email, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${percent.round()}%',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${overview.completedCount}/${overview.items.length} course selesai'
                  '${user.lastLogin == null ? '' : ' · Terakhir masuk ${formatDateTime(user.lastLogin!)}'}',
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