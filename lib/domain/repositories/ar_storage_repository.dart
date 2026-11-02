import 'dart:typed_data';

abstract class ArStorageRepository {
  /// Mengunggah file dan mengembalikan link publiknya.
  Future<String> upload({
    required Uint8List bytes,
    required String objectPath,
    required String contentType,
  });
}
