/// Error yang sudah diterjemahkan ke pesan yang ramah untuk pengguna.
class Failure implements Exception {
  const Failure(this.message);

  final String message;

  @override
  String toString() => message;
}