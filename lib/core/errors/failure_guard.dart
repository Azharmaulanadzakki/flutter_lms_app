import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

import 'failures.dart';

/// Membungkus operasi Firebase: timeout dan error teknis
/// diubah menjadi [Failure] dengan pesan yang ramah.
Future<T> guardFirebase<T>(
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  try {
    return await action().timeout(timeout);
  } on Failure {
    rethrow;
  } on TimeoutException {
    throw const Failure('Koneksi terlalu lama. Periksa internet lalu coba lagi.');
  } on FirebaseException catch (e) {
    switch (e.code) {
      case 'permission-denied':
        throw const Failure('Akses ditolak oleh Firestore. Periksa Security Rules.');
      case 'unavailable':
        throw const Failure('Server tidak dapat dijangkau. Periksa internet kamu.');
      default:
        throw Failure('Terjadi kesalahan database (${e.code}).');
    }
  } catch (_) {
    throw const Failure('Terjadi kesalahan tak terduga. Coba lagi.');
  }
}