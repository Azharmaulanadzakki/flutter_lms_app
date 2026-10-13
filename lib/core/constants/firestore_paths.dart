class FirestorePaths {
  FirestorePaths._();

  static const users = 'users';
  static const courses = 'courses';
  static const materials = 'materials';
  static const questions = 'questions';
  static const questionKeys = 'questionKeys';
  static const tests = 'tests';
  static const testAttempts = 'testAttempts';
  static const courseProgress = 'courseProgress';
  static const gameResults = 'gameResults';
  static const announcements = 'announcements';
  static const settings = 'settings';

  /// Dokumen bobot progress di koleksi settings.
  static const progressWeightsDoc = 'progressWeights';

  /// ID dokumen progress: satu dokumen per siswa per course.
  static String progressId(String userId, String courseId) =>
      '${userId}_$courseId';

  /// ID dokumen attempt: satu percobaan per siswa per test.
  static String attemptId(String userId, String testId) => '${userId}_$testId';
}