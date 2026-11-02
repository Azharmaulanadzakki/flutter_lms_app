import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  static const _timeout = Duration(seconds: 15);

  @override
  Stream<UserEntity?> authStateChanges() => _remote.authStateChanges();

  @override
  Future<UserEntity> signIn({required String email, required String password}) =>
      _guard(() => _remote.signIn(email, password));

  @override
  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  }) =>
      _guard(() => _remote.register(name, email, password));

  @override
  Future<void> signOut() => _guard(_remote.signOut);

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _remote.sendPasswordReset(email));

  /// Semua error teknis diubah menjadi [Failure] berpesan ramah.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action().timeout(_timeout);
    } on Failure {
      // Pesan yang sudah ramah (misalnya akun dinonaktifkan) diteruskan apa adanya.
      rethrow;
    } on TimeoutException {
      throw const Failure('Koneksi terlalu lama. Periksa internet lalu coba lagi.');
    } on FirebaseAuthException catch (e) {
      throw Failure(_authMessage(e.code));
    } on FirebaseException catch (e) {
      throw Failure(_databaseMessage(e.code));
    } catch (_) {
      throw const Failure('Terjadi kesalahan tak terduga. Coba lagi.');
    }
  }

  String _authMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Silakan login.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan. Hubungi admin.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Login Email/Password belum diaktifkan di Firebase Console.';
      default:
        return 'Autentikasi gagal ($code).';
    }
  }

  String _databaseMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'Akses ditolak oleh Firestore. Periksa Security Rules.';
      case 'unavailable':
        return 'Server tidak dapat dijangkau. Periksa internet kamu.';
      default:
        return 'Terjadi kesalahan database ($code).';
    }
  }
}