import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../blocs/admin/admin_courses_cubit.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/class_overview_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/state_views.dart';
import '../student/widgets/stat_card.dart';
import 'admin_widgets.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key, required this.onOpenTab});

  /// Pindah ke tab lain (0 sampai 4).
  final ValueChanged<int> onOpenTab;

  Future<void> _logout(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Keluar?',
      message: 'Kamu harus login lagi untuk membuka panel admin.',
      confirmLabel: 'Keluar',
    );
    if (ok && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }

  void _reloadAll(BuildContext context) {
    context.read<ClassOverviewCubit>().load();
    context.read<AdminCoursesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthBloc>().state.user;
    final firstName = (user?.name ?? '').trim().split(' ').first;

    return SafeArea(
      child: BlocBuilder<ClassOverviewCubit, ClassOverviewState>(
        builder: (context, state) {
          final overview = state.overview;

          if (overview == null) {
            if (state.status == AdminLoadStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat data kelas.',
                onRetry: () => context.read<ClassOverviewCubit>().load(),
              );
            }
            return const LoadingView();
          }

          final recent = overview.recentlyActive;

          return RefreshIndicator(
            onRefresh: () => context.read<ClassOverviewCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${firstName.isEmpty ? 'Admin' : firstName} ',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Panel Admin',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Keluar',
                      icon: const Icon(Icons.logout),
                      onPressed: () => _logout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.groups_outlined,
                          label: 'Siswa terdaftar',
                          value: '${overview.studentCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.menu_book_outlined,
                          label: 'Course aktif',
                          value: '${overview.activeCourseCount}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Course selesai',
                          value: '${overview.completedCourses}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          icon: Icons.insights,
                          label: 'Rata-rata progress',
                          value: '${overview.averagePercent.round()}%',
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  'Aksi Cepat',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/admin/course/new').then((_) {
                    if (context.mounted) _reloadAll(context);
                  }),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Course'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/admin/weights').then((_) {
                    if (context.mounted) _reloadAll(context);
                  }),
                  icon: const Icon(Icons.tune),
                  label: const Text('Atur Bobot Progress'),
                ),
                if (user?.isAdmin == true) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => context.push('/admin/branding'),
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('Pengaturan Aplikasi'),
                  ),
                ],

                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => onOpenTab(3),
                  icon: const Icon(Icons.groups_outlined),
                  label: const Text('Lihat Siswa'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => context.push('/admin/ar'),
                  icon: const Icon(Icons.view_in_ar_outlined),
                  label: const Text('Kelola Model AR'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Terakhir Masuk',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (recent.isEmpty)
                  Text(
                    overview.studentCount == 0
                        ? 'Belum ada siswa yang mendaftar.'
                        : 'Belum ada aktivitas login.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  for (final s in recent)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Text(
                                s.user.name.isEmpty
                                    ? '?'
                                    : s.user.name[0].toUpperCase(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.user.name,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    formatDateTime(s.user.lastLogin!),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${s.overview.overallPercent.round()}%',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}
