import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/constants/firestore_paths.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Operasi pengguna khusus super admin. Rules menolak semua operasi ini
/// untuk akun yang bukan super admin.
class UserAdminRemoteDataSource {
  UserAdminRemoteDataSource(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _helperAppName = 'userAdminHelper';

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  FieldValue get _now => FieldValue.serverTimestamp();

  Future<List<UserModel>> getAllUsers() async {
    final snap = await _users.get();
    return snap.docs.map(UserModel.fromFirestore).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<UserModel> getUser(String uid) async {
    final snap = await _users.doc(uid).get();
    if (!snap.exists) throw const Failure('Pengguna tidak ditemukan.');
    return UserModel.fromFirestore(snap);
  }

  /// Instance FirebaseAuth kedua. Akun baru dibuat di sini, sehingga sesi
  /// super admin di instance utama tidak tergantikan.
  Future<FirebaseAuth> _helperAuth() async {
    final existing = Firebase.apps.where((a) => a.name == _helperAppName);
    final app = existing.isNotEmpty
        ? existing.first
        : await Firebase.initializeApp(
            name: _helperAppName,
            options: Firebase.app().options,
          );

    final auth = FirebaseAuth.instanceFor(app: app);
    if (kIsWeb) {
      // Di web, jangan simpan sesi akun baru di penyimpanan browser.
      try {
        await auth.setPersistence(Persistence.NONE);
      } catch (_) {}
    }
    return auth;
  }

  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final helper = await _helperAuth();
    User? created;

    try {
      final cred = await helper.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      created = cred.user!;

      try {
        await created.updateDisplayName(name);
      } catch (_) {
        // Nama tampilan di Auth tidak kritis; profil Firestore yang dipakai aplikasi.
      }

      await _users.doc(created.uid).set({
        'name': name,
        'email': email,
        'role': role.value,
        'photoUrl': null,
        'isActive': true,
        'createdAt': _now,
        'lastLogin': null,
        'createdBy': _auth.currentUser?.uid,
      });

      return created.uid;
    } on FirebaseAuthException catch (e) {
      throw Failure(_createMessage(e.code));
    } catch (_) {
      // Profil gagal ditulis: hapus akun Auth yang terlanjur dibuat
      // agar tidak ada akun yatim.
      if (created != null) {
        try {
          await created.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      try {
        await helper.signOut();
      } catch (_) {}
    }
  }

  Future<void> updateUser({
    required String uid,
    required String name,
    required UserRole role,
  }) {
    return _users.doc(uid).update({
      'name': name,
      'role': role.value,
      'updatedAt': _now,
    });
  }

  Future<void> setActive(String uid, bool active) {
    return _users.doc(uid).update({'isActive': active, 'updatedAt': _now});
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Failure(_createMessage(e.code));
    }
  }

  String _createMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah terdaftar. Gunakan email lain, atau aktifkan kembali akun yang ada.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter).';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'operation-not-allowed':
        return 'Login Email/Password belum diaktifkan di Firebase Console.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      default:
        return 'Operasi akun gagal ($code).';
    }
  }
}
