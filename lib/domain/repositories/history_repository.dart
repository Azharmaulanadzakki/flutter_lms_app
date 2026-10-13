import '../entities/test_attempt.dart';

abstract class HistoryRepository {
  /// Percobaan test milik siswa yang sudah dinilai.
  Future<List<TestAttempt>> getGradedAttempts(String userId);
}