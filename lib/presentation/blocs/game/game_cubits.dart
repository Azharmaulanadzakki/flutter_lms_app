import 'dart:async';
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/game/circuit.dart';
import '../../../domain/game/game_models.dart';
import '../../../domain/game/game_session.dart';
import '../../../domain/game/logic_blocks.dart';
import '../../../domain/game/mission_record.dart';
import '../../../domain/game/simulation_engine.dart';
import '../../../domain/usecases/game/game_sync_usecases.dart';
import '../../../domain/usecases/game/game_usecases.dart';
import '../../../domain/game/course_game.dart';

// ---------- Daftar misi ----------

enum GameLoadStatus { loading, success, failure }

class GameHomeState extends Equatable {
  const GameHomeState({
    this.status = GameLoadStatus.loading,
    this.progress = GameProgress.empty,
    this.error,
  });

  final GameLoadStatus status;
  final GameProgress progress;
  final String? error;

  GameHomeState copyWith({
    GameLoadStatus? status,
    GameProgress? progress,
    String? error,
  }) {
    return GameHomeState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, progress, error];
}

class GameHomeCubit extends Cubit<GameHomeState> {
  GameHomeCubit(this._load) : super(const GameHomeState());

  final LoadGameProgressUseCase _load;

  Future<void> load(String userId) async {
    emit(state.copyWith(status: GameLoadStatus.loading));
    try {
      final progress = await _load(userId);
      if (isClosed) return;
      emit(state.copyWith(status: GameLoadStatus.success, progress: progress));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: GameLoadStatus.failure,
          error: 'Gagal memuat progres game. Coba lagi.',
        ),
      );
    }
  }
}

// ---------- Sesi bermain ----------

enum PlayPhase { editing, playing, finished }

class RunOutcome extends Equatable {
  const RunOutcome({
    required this.report,
    required this.stars,
    this.record,
    this.saved = false,
    this.queued = false,
    this.synced = false,
    this.courseGameDone = false,
    this.saveError,
  });

  final SimulationReport report;
  final int stars;
  final MissionRecord? record;

  /// Rekap lokal tersimpan.
  final bool saved;

  /// Hasil masuk antrean pengiriman.
  final bool queued;

  /// Antrean sudah terkirim ke server.
  final bool synced;

  /// Run ini menuntaskan seluruh misi simulasi course.
  final bool courseGameDone;
  final String? saveError;

  RunOutcome copyWith({bool? synced}) {
    return RunOutcome(
      report: report,
      stars: stars,
      record: record,
      saved: saved,
      queued: queued,
      synced: synced ?? this.synced,
      courseGameDone: courseGameDone,
      saveError: saveError,
    );
  }

  /// Teks status penyimpanan untuk lembar hasil.
  String get statusText {
    if (saveError != null) return saveError!;
    if (!saved && !queued) return 'Menyimpan hasil...';
    if (synced) return 'Hasil tersimpan dan terkirim ke server.';
    if (queued) {
      return 'Hasil tersimpan di perangkat dan akan dikirim ke server saat online.';
    }
    return 'Hasil tersimpan di perangkat ini.';
  }

  @override
  List<Object?> get props => [
    report,
    stars,
    record,
    saved,
    queued,
    synced,
    courseGameDone,
    saveError,
  ];
}

class GameSessionState extends Equatable {
  const GameSessionState({
    required this.session,
    required this.frame,
    this.selectedDeviceId,
    this.phase = PlayPhase.editing,
    this.playTick = 0,
    this.speed = 1,
    this.outcome,
    this.notice,
    this.noticeIsError = false,
  });

  final GameSession session;

  /// Keadaan yang digambar panggung. Selalu terisi.
  final TickSnapshot frame;

  /// Perangkat di rak yang sedang dipilih untuk dipasang.
  final String? selectedDeviceId;
  final PlayPhase phase;
  final int playTick;
  final int speed;
  final RunOutcome? outcome;

  /// Pesan sementara untuk snackbar: hilang pada emit berikutnya.
  final String? notice;
  final bool noticeIsError;

  GameSessionState copyWith({
    GameSession? session,
    TickSnapshot? frame,
    String? selectedDeviceId,
    bool clearSelection = false,
    PlayPhase? phase,
    int? playTick,
    int? speed,
    RunOutcome? outcome,
    bool clearOutcome = false,
    String? notice,
    bool noticeIsError = false,
  }) {
    return GameSessionState(
      session: session ?? this.session,
      frame: frame ?? this.frame,
      selectedDeviceId: clearSelection
          ? null
          : (selectedDeviceId ?? this.selectedDeviceId),
      phase: phase ?? this.phase,
      playTick: playTick ?? this.playTick,
      speed: speed ?? this.speed,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      notice: notice,
      noticeIsError: noticeIsError,
    );
  }

  @override
  List<Object?> get props => [
    session,
    frame,
    selectedDeviceId,
    phase,
    playTick,
    speed,
    outcome,
    notice,
    noticeIsError,
  ];
}

class GameSessionCubit extends Cubit<GameSessionState> {
  GameSessionCubit({
    required this.mission,
    required this.userId,
    required SubmitMissionRunUseCase submitRun,
    required SyncGameResultsUseCase syncResults,
    required LoadGameProgressUseCase loadProgress,
    this.courseId = '',
    this.courseMissions = const [],
  }) : _submitRun = submitRun,
       _syncResults = syncResults,
       _loadProgress = loadProgress,
       _startedAt = DateTime.now(),
       super(_initial(mission)) {
    _rest = state.frame;
  }

  final MissionDefinition mission;
  final String userId;

  /// Kosong jika dimainkan di luar course.
  final String courseId;

  /// Misi yang harus selesai untuk menuntaskan simulasi course.
  final List<MissionDefinition> courseMissions;
  final SubmitMissionRunUseCase _submitRun;
  final SyncGameResultsUseCase _syncResults;
  final LoadGameProgressUseCase _loadProgress;
  final DateTime _startedAt;

  late final TickSnapshot _rest;
  Timer? _timer;

  static GameSessionState _initial(MissionDefinition mission) {
    final session = GameSession.start(mission);
    return GameSessionState(session: session, frame: session.restFrame);
  }

  bool get _locked => state.phase != PlayPhase.editing;

  // ---------- pasang dan kabel ----------

  void selectDevice(String? deviceId) {
    if (_locked) return;
    emit(
      state.copyWith(
        selectedDeviceId: deviceId,
        clearSelection: deviceId == null,
      ),
    );
  }

  /// Ketukan pada dudukan di panggung 3D.
  void tapSlot(String slotId) {
    if (_locked) return;
    final session = state.session;

    String? occupant;
    for (final entry in session.circuit.installed.entries) {
      if (entry.value == slotId) {
        occupant = entry.key;
        break;
      }
    }
    if (occupant != null) {
      _apply(session.uninstall(occupant), okNotice: 'Perangkat dilepas.');
      return;
    }

    final selected = state.selectedDeviceId;
    if (selected == null) {
      emit(
        state.copyWith(
          notice: 'Pilih perangkat di tab Pasang dulu, lalu ketuk dudukannya.',
        ),
      );
      return;
    }
    _apply(session.install(selected, slotId), clearSelection: true);
  }

  void install(String deviceId, String slotId) {
    if (_locked) return;
    _apply(state.session.install(deviceId, slotId), clearSelection: true);
  }

  void uninstall(String deviceId) {
    if (_locked) return;
    _apply(state.session.uninstall(deviceId));
  }

  /// [pinId] null berarti melepas kabel.
  void connect(String deviceId, String? pinId) {
    if (_locked) return;
    _apply(
      pinId == null
          ? state.session.disconnect(deviceId)
          : state.session.connect(deviceId, pinId),
    );
  }

  void _apply(
    SessionChange change, {
    String? okNotice,
    bool clearSelection = false,
  }) {
    if (change.ok) {
      emit(
        state.copyWith(
          session: change.session,
          frame: _rest,
          clearSelection: clearSelection,
          clearOutcome: true,
          notice: okNotice,
        ),
      );
    } else {
      emit(
        state.copyWith(
          session: change.session,
          notice: change.issue!.message,
          noticeIsError: true,
        ),
      );
    }
  }

  // ---------- logika ----------

  void addRule(Rule rule) {
    if (_locked) return;
    emit(
      state.copyWith(
        session: state.session.addRule(rule),
        frame: _rest,
        clearOutcome: true,
      ),
    );
  }

  void replaceRule(int index, Rule rule) {
    if (_locked) return;
    emit(
      state.copyWith(
        session: state.session.replaceRule(index, rule),
        frame: _rest,
        clearOutcome: true,
      ),
    );
  }

  void removeRule(int index) {
    if (_locked) return;
    emit(
      state.copyWith(
        session: state.session.removeRule(index),
        frame: _rest,
        clearOutcome: true,
      ),
    );
  }

  // ---------- simulasi ----------

  void run() {
    if (_locked) return;
    if (state.session.circuit.installed.isEmpty) {
      emit(
        state.copyWith(
          notice: 'Pasang minimal satu perangkat dulu sebelum menjalankan simulasi.',
          noticeIsError: true,
        ),
      );
      return;
    }

    final session = state.session.run();
    final report = session.report!;

    emit(
      state.copyWith(
        session: session,
        phase: PlayPhase.playing,
        playTick: 0,
        frame: report.snapshots.first,
        clearOutcome: true,
      ),
    );

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _step());
  }

  void _step() {
    final report = state.session.report;
    if (report == null || state.phase != PlayPhase.playing) {
      _timer?.cancel();
      return;
    }

    // Kecepatan 2x dan 4x melompati tick, supaya laju pembaruan tetap 10 kali
    // per detik. Hasil akhir selalu dihitung dari seluruh rekaman.
    final last = report.snapshots.length - 1;
    final next = math.min(last, state.playTick + state.speed);

    if (next >= last) {
      _timer?.cancel();
      emit(state.copyWith(playTick: last, frame: report.snapshots[last]));
      unawaited(_finish());
      return;
    }
    emit(state.copyWith(playTick: next, frame: report.snapshots[next]));
  }

  void setSpeed(int speed) => emit(state.copyWith(speed: speed));

  void skip() {
    final report = state.session.report;
    if (report == null || state.phase != PlayPhase.playing) return;

    _timer?.cancel();
    final last = report.snapshots.length - 1;
    emit(state.copyWith(playTick: last, frame: report.snapshots[last]));
    unawaited(_finish());
  }

  /// Rangkaian dan aturan pemain, disimpan bersama hasil untuk verifikasi ulang.
  Map<String, dynamic> _solutionOf(GameSession session) => {
    'circuit': session.circuit.toJson(),
    'rules': [for (final r in session.rules) r.toJson()],
  };

  Future<void> _finish() async {
    if (state.phase != PlayPhase.playing) return;

    final session = state.session;
    final report = session.report!;
    final stars = starsFor(score: report.score, completed: report.completed);

    emit(
      state.copyWith(
        phase: PlayPhase.finished,
        outcome: RunOutcome(report: report, stars: stars),
      ),
    );

    final now = DateTime.now();
    final run = RunSummary(
      missionId: mission.id,
      score: report.score,
      completed: report.completed,
      mistakes: report.mistakes,
      durationSec: now.difference(_startedAt).inSeconds,
      at: now,
    );

    // Simulasi course selesai jika semua misinya selesai, termasuk run ini.
    var completesCourse = false;
    double? courseScore;
    if (courseId.isNotEmpty && courseMissions.isNotEmpty && report.completed) {
      try {
        final progress = await _loadProgress(userId);
        final status = courseGameAfterRun(
          missions: courseMissions,
          progress: progress,
          run: run,
        );
        completesCourse = status.completed;
        courseScore = status.averageScore;
      } catch (_) {
        // Gagal membaca progres lokal: hasil tetap dikirim tanpa penanda selesai.
      }
    }

    final submission = await _submitRun(
      userId: userId,
      run: run,
      courseId: courseId,
      solution: _solutionOf(session),
      completesCourseGame: completesCourse,
      courseGameScore: courseScore,
    );
    if (isClosed) return;

    String? problem;
    if (submission.record == null && !submission.queued) {
      problem = 'Hasil belum tersimpan di perangkat.';
    } else if (!submission.queued) {
      problem = 'Hasil tersimpan di perangkat, tetapi belum masuk antrean pengiriman.';
    }

    emit(
      state.copyWith(
        outcome: RunOutcome(
          report: report,
          stars: stars,
          record: submission.record,
          saved: submission.record != null,
          queued: submission.queued,
          courseGameDone: completesCourse && submission.queued,
          saveError: problem,
        ),
      ),
    );

    if (!submission.queued) return;

    // Kirim di latar belakang. Berlanjut walau pemain sudah meninggalkan layar ini.
    final sync = await _syncResults(userId);
    if (isClosed) return;

    final current = state.outcome;
    if (current != null && identical(current.report, report) && sync.isClear) {
      emit(state.copyWith(outcome: current.copyWith(synced: true)));
    }
  }

  /// Kembali ke mode merakit dan menyetel rumah ke keadaan awal.
  void backToEditing() {
    _timer?.cancel();
    emit(
      state.copyWith(
        phase: PlayPhase.editing,
        playTick: 0,
        frame: _rest,
        clearOutcome: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
