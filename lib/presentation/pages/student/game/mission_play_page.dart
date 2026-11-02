import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/game/game_models.dart';
import '../../../../domain/game/missions.dart';
import '../../../../domain/usecases/game/game_sync_usecases.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/game/game_cubits.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/state_views.dart';
import 'stage/stage_entry.dart';
import 'widgets/fallback_stage.dart';
import 'widgets/install_tab.dart';
import 'widgets/logic_tab.dart';
import 'widgets/mission_tab.dart';
import 'widgets/result_sheet.dart';
import 'widgets/wire_tab.dart';
import '../../../../domain/game/course_game.dart';
import '../../../../domain/usecases/game/game_usecases.dart';

class MissionPlayPage extends StatelessWidget {
  const MissionPlayPage({
    super.key,
    required this.missionId,
    this.courseContext,
  });

  final String missionId;

  /// Terisi jika misi dimainkan sebagai bagian dari course.
  final GameCourseContext? courseContext;

  @override
  Widget build(BuildContext context) {
    final mission = missionById(missionId);

    if (mission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Misi')),
        body: const EmptyView(
          icon: Icons.sports_esports_outlined,
          message: 'Misi tidak ditemukan.',
        ),
      );
    }

    final uid = context.read<AuthBloc>().state.user?.uid ?? '';
    final course = courseContext;

    return BlocProvider(
      create: (_) => GameSessionCubit(
        mission: mission,
        userId: uid,
        submitRun: sl<SubmitMissionRunUseCase>(),
        syncResults: sl<SyncGameResultsUseCase>(),
        loadProgress: sl<LoadGameProgressUseCase>(),
        courseId: course?.courseId ?? '',
        courseMissions: course == null
            ? const []
            : missionsForCourse(course.missionIds),
      ),
      child: _PlayView(mission: mission, courseContext: course),
    );
  }
}

class _PlayView extends StatelessWidget {
  const _PlayView({required this.mission, this.courseContext});

  final MissionDefinition mission;
  final GameCourseContext? courseContext;

  List<MissionDefinition> get _scope => courseContext == null
      ? bundledMissions
      : missionsForCourse(courseContext!.missionIds);

  Future<void> _showResult(BuildContext context) async {
    final cubit = context.read<GameSessionCubit>();
    final next = nextMissionIn(_scope, mission);

    final action = await showModalBottomSheet<ResultAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ResultSheet(mission: mission, next: next),
      ),
    );

    if (!context.mounted || cubit.isClosed) return;

    switch (action) {
      case ResultAction.next:
        cubit.backToEditing();
        if (next != null) {
          context.pushReplacement(
            '/game/mission/${next.id}',
            extra: courseContext,
          );
        }
      case ResultAction.leave:
        context.pop();
      case ResultAction.edit:
      case null:
        cubit.backToEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<GameSessionCubit, GameSessionState>(
          listenWhen: (prev, curr) => curr.notice != null,
          listener: (context, state) => showAppSnackBar(
            context,
            state.notice!,
            isError: state.noticeIsError,
          ),
        ),
        BlocListener<GameSessionCubit, GameSessionState>(
          listenWhen: (prev, curr) =>
              prev.phase != PlayPhase.finished &&
              curr.phase == PlayPhase.finished,
          listener: (context, state) => _showResult(context),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(title: Text(mission.title)),
        body: DefaultTabController(
          length: 4,
          child: Column(
            children: [
              Expanded(flex: 5, child: _StageArea(mission: mission)),
              const TabBar(
                tabs: [
                  Tab(text: 'Misi'),
                  Tab(text: 'Pasang'),
                  Tab(text: 'Kabel'),
                  Tab(text: 'Logika'),
                ],
              ),
              Expanded(flex: 6, child: _Panel(mission: mission)),
            ],
          ),
        ),
        bottomNavigationBar: _RunBar(mission: mission),
      ),
    );
  }
}

class _StageArea extends StatefulWidget {
  const _StageArea({required this.mission});

  final MissionDefinition mission;

  @override
  State<_StageArea> createState() => _StageAreaState();
}

class _StageAreaState extends State<_StageArea> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameSessionCubit>();

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) =>
          !identical(p.frame, c.frame) ||
          !identical(p.session.circuit, c.session.circuit) ||
          p.selectedDeviceId != c.selectedDeviceId,
      builder: (context, state) {
        if (_failed) {
          return FallbackStage(
            mission: widget.mission,
            session: state.session,
            frame: state.frame,
            onRetry: () => setState(() => _failed = false),
          );
        }

        final selected = state.selectedDeviceId;
        final highlight = selected == null
            ? null
            : widget.mission.deviceById(selected)?.kind.slotKind;

        return SmartHomeStage(
          mission: widget.mission,
          installed: state.session.circuit.installed,
          wires: state.session.circuit.wires,
          frame: state.frame,
          highlightKind: highlight,
          onSlotTap: cubit.tapSlot,
          onFailed: () {
            if (mounted) setState(() => _failed = true);
          },
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.mission});

  final MissionDefinition mission;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GameSessionCubit, GameSessionState, bool>(
      selector: (state) => state.phase == PlayPhase.editing,
      builder: (context, editing) => IgnorePointer(
        ignoring: !editing,
        child: Opacity(
          opacity: editing ? 1 : 0.5,
          child: TabBarView(
            children: [
              MissionTab(mission: mission),
              InstallTab(mission: mission),
              WireTab(mission: mission),
              LogicTab(mission: mission),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunBar extends StatelessWidget {
  const _RunBar({required this.mission});

  final MissionDefinition mission;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: BlocBuilder<GameSessionCubit, GameSessionState>(
            buildWhen: (p, c) =>
                p.phase != c.phase ||
                p.playTick != c.playTick ||
                p.speed != c.speed ||
                !identical(p.session, c.session),
            builder: (context, state) {
              final cubit = context.read<GameSessionCubit>();
              final session = state.session;

              if (state.phase == PlayPhase.editing) {
                final total = mission.devices.length;
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Terpasang ${session.circuit.installed.length}/$total · '
                        'kabel ${session.circuit.wires.length}/$total · '
                        '${session.rules.length} aturan',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: cubit.run,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Jalankan simulasi'),
                    ),
                  ],
                );
              }

              final report = session.report;
              final last = report == null ? 1 : report.snapshots.length - 1;
              final seconds = (state.playTick / 10).toStringAsFixed(1);
              final duration = mission.scenario.durationSec;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: last == 0 ? 0 : state.playTick / last,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Detik $seconds / $duration',
                        style: theme.textTheme.labelLarge,
                      ),
                      const Spacer(),
                      if (state.phase == PlayPhase.playing) ...[
                        for (final s in const [1, 2, 4]) ...[
                          ChoiceChip(
                            label: Text('${s}x'),
                            selected: state.speed == s,
                            onSelected: (_) => cubit.setSpeed(s),
                          ),
                          const SizedBox(width: 6),
                        ],
                        TextButton(
                          onPressed: cubit.skip,
                          child: const Text('Lewati'),
                        ),
                      ] else
                        const Text('Menampilkan hasil...'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
