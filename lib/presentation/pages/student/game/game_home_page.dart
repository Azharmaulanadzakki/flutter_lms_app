import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/game/course_game.dart';
import '../../../../domain/game/game_models.dart';
import '../../../../domain/game/mission_record.dart';
import '../../../../domain/game/missions.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/game/game_cubits.dart';
import '../../../blocs/game/game_sync_cubit.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/state_views.dart';
import 'widgets/sync_action.dart';

/// Daftar misi. Tanpa parameter: latihan bebas dengan semua misi.
/// Dengan [courseId]: misi milik sebuah course, yang hasilnya ikut
/// menentukan penyelesaian simulasi course itu.
class GameHomePage extends StatelessWidget {
  const GameHomePage({
    super.key,
    this.courseId = '',
    this.courseTitle,
    this.missions,
    this.serverGameDone = false,
  });

  final String courseId;
  final String? courseTitle;
  final List<MissionDefinition>? missions;

  /// Server sudah mencatat simulasi course ini selesai.
  final bool serverGameDone;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<GameHomeCubit>()..load(uid)),
        // Kirim hasil yang tertunda setiap layar ini dibuka.
        BlocProvider(create: (_) => sl<GameSyncCubit>()..sync(uid)),
      ],
      child: _View(
        uid: uid,
        courseId: courseId,
        courseTitle: courseTitle,
        missions: missions ?? bundledMissions,
        serverGameDone: serverGameDone,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.uid,
    required this.courseId,
    required this.courseTitle,
    required this.missions,
    required this.serverGameDone,
  });

  final String uid;
  final String courseId;
  final String? courseTitle;
  final List<MissionDefinition> missions;
  final bool serverGameDone;

  bool get _inCourse => courseId.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          courseTitle == null
              ? 'Game Smart Home (IoT)'
              : 'Simulasi: $courseTitle',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [SyncAction(userId: uid)],
      ),
      body: BlocBuilder<GameHomeCubit, GameHomeState>(
        builder: (context, state) {
          final cubit = context.read<GameHomeCubit>();

          if (state.status == GameLoadStatus.loading &&
              state.progress.records.isEmpty) {
            return const LoadingView();
          }
          if (state.status == GameLoadStatus.failure) {
            return ErrorView(
              message: state.error ?? 'Gagal memuat progres game.',
              onRetry: () => cubit.load(uid),
            );
          }

          final progress = state.progress;
          final status = courseGameStatus(missions, progress);
          final done = status.doneCount;
          final total = missions.length;
          final average = status.averageScore;

          final courseContext = _inCourse
              ? GameCourseContext(
                  courseId: courseId,
                  missionIds: [for (final m in missions) m.id],
                )
              : null;

          return RefreshIndicator(
            onRefresh: () => cubit.load(uid),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$done dari $total misi selesai',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : done / total,
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        average == null
                            ? 'Selesaikan misi pertama untuk mendapat nilai.'
                            : 'Rata-rata nilai terbaik: ${average.round()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_inCourse) ...[
                  const SizedBox(height: 12),
                  _CourseBanner(
                    serverDone: serverGameDone,
                    localDone: status.completed,
                  ),
                ],
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const ExpansionTile(
                    title: Text('Cara bermain'),
                    childrenPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. Baca tujuan dan kondisi awal misi.'),
                      Text('2. Pasang komponen ke dudukannya.'),
                      Text(
                        '3. Sambungkan kabel dari tiap komponen ke pin yang cocok.',
                      ),
                      Text(
                        '4. Susun blok logika: JIKA kondisi MAKA perintah LAINNYA perintah.',
                      ),
                      Text('5. Jalankan simulasi dan amati respons perangkat.'),
                      Text(
                        '6. Selesaikan semua objektif untuk mendapat nilai dan bintang.',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Misi',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                for (final mission in missions) ...[
                  _MissionCard(
                    mission: mission,
                    record: progress.recordOf(mission.id),
                    unlocked: progress.isUnlocked(mission, missions),
                    onTap: () {
                      if (!progress.isUnlocked(mission, missions)) {
                        showAppSnackBar(
                          context,
                          'Selesaikan misi sebelumnya dulu.',
                        );
                        return;
                      }
                      context
                          .push(
                            '/game/mission/${mission.id}',
                            extra: courseContext,
                          )
                          .then((_) {
                            if (context.mounted) {
                              cubit.load(uid);
                              context.read<GameSyncCubit>().refresh(uid);
                            }
                          });
                    },
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

class _CourseBanner extends StatelessWidget {
  const _CourseBanner({required this.serverDone, required this.localDone});

  final bool serverDone;
  final bool localDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String text;
    final Color color;
    final IconData icon;

    if (serverDone) {
      text = 'Simulasi course ini sudah tercatat selesai.';
      color = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (localDone) {
      text =
          'Semua misi selesai. Hasilnya tercatat ke course saat terkirim (butuh internet). '
          'Ikon awan di pojok kanan atas menunjukkan statusnya.';
      color = Colors.orange.shade800;
      icon = Icons.cloud_upload_outlined;
    } else {
      text =
          'Selesaikan semua misi di bawah untuk menyelesaikan simulasi course ini '
          'dan membuka post-test.';
      color = AppColors.primary;
      icon = Icons.flag_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.mission,
    required this.record,
    required this.unlocked,
    required this.onTap,
  });

  final MissionDefinition mission;
  final MissionRecord record;
  final bool unlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stars = starsFor(
      score: record.bestScore ?? 0,
      completed: record.completed,
    );

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
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
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: unlocked
                        ? Text(
                            '${mission.order}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          )
                        : const Icon(Icons.lock_outline),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unlocked
                              ? mission.goal
                              : 'Selesaikan misi sebelumnya untuk membuka.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (record.attempts > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              record.completed
                                  ? 'Nilai terbaik ${record.bestScore} · ${record.attempts} percobaan'
                                  : '${record.attempts} percobaan, belum selesai',
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < stars ? Icons.star : Icons.star_border,
                          size: 18,
                          color: Colors.amber.shade700,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
