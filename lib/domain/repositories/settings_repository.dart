import '../entities/progress_weights.dart';

abstract class SettingsRepository {
  /// Bobot progress dari Firestore. Memakai bobot bawaan jika dokumen
  /// belum ada, tidak valid, atau gagal dibaca.
  Future<ProgressWeights> getProgressWeights();
}