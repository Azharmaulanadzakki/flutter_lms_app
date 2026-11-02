import 'package:equatable/equatable.dart';

enum MaterialKind { text, video, pdf }

class CourseMaterial extends Equatable {
  const CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    required this.content,
    required this.type,
    required this.mediaUrl,
    required this.order,
    this.isPublished = true,
  });

  final String id;
  final String courseId;
  final String title;

  /// Isi teks (untuk type text).
  final String content;
  final MaterialKind type;

  /// Link YouTube / PDF (untuk type video atau pdf).
  final String mediaUrl;
  final int order;
  final bool isPublished;

  @override
  List<Object?> get props =>
      [id, courseId, title, content, type, mediaUrl, order, isPublished];
}