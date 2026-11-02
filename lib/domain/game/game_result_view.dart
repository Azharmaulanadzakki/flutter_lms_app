/// Satu hasil permainan di server, untuk ditampilkan ke guru.
class GameResultView {
  const GameResultView({
    required this.id,
    required this.missionId,
    required this.courseId,
    required this.score,
    required this.errors,
    required this.durationSec,
    required this.completed,
    required this.playedAt,
  });

  final String id;
  final String missionId;
  final String courseId;
  final int score;
  final int errors;
  final int durationSec;
  final bool completed;
  final DateTime playedAt;
}
