/// Bobot tiap aktivitas dalam menghitung persentase progress course.
/// Tidak harus berjumlah 100: hasil akhirnya dinormalkan.
class ProgressWeights {
  const ProgressWeights({
    this.preTest = 10,
    this.materials = 40,
    this.game = 30,
    this.postTest = 20,
  });

  final double preTest;
  final double materials;
  final double game;
  final double postTest;

  static const defaults = ProgressWeights();

  /// Membaca bobot dari data Firestore.
  /// Mengembalikan null jika ada field hilang, bukan angka, negatif,
  /// atau seluruh bobot bernilai 0.
  static ProgressWeights? tryParse(Map<String, dynamic>? data) {
    if (data == null) return null;

    double? read(String key) {
      final value = data[key];
      if (value is! num) return null;
      final number = value.toDouble();
      if (number.isNaN || number.isInfinite || number < 0) return null;
      return number;
    }

    final pre = read('preTest');
    final materials = read('materials');
    final game = read('game');
    final post = read('postTest');

    if (pre == null || materials == null || game == null || post == null) {
      return null;
    }
    if (pre + materials + game + post <= 0) return null;

    return ProgressWeights(
      preTest: pre,
      materials: materials,
      game: game,
      postTest: post,
    );
  }
}
