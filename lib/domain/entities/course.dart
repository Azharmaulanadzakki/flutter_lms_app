import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.level,
    required this.duration,
    required this.order,
    this.objectives = const [],
    this.hasGame = false,
    this.missionIds = const [],
    this.isPublished = true,
  });

  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String level;

  /// Estimasi durasi dalam menit.
  final int duration;
  final int order;

  /// Tujuan pembelajaran.
  final List<String> objectives;

  /// True jika course punya simulasi (game).
  final bool hasGame;

  /// Misi simulasi milik course ini. Kosong berarti semua misi.
  final List<String> missionIds;

  /// Course yang belum dipublikasikan tidak tampil untuk siswa.
  final bool isPublished;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        thumbnailUrl,
        level,
        duration,
        order,
        objectives,
        hasGame,
        missionIds,
        isPublished,
      ];
}