import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> authStateChanges();
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection(FirestorePaths.users).doc(uid);

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth
        .authStateChanges()
        .asyncMap<UserModel?>((user) async => user == null ? null : _loadUser(user));
  }

  /// Membaca profil dari Firestore. Saat register, event login muncul
  /// sebelum dokumen selesai ditulis, jadi kita tunggu sebentar.
  Future<UserModel> _loadUser(User user) async {
    try {
      final ref = _userRef(user.uid);
      final snap = await ref.get();
      if (snap.exists) return UserModel.fromFirestore(snap);

      final waited = await ref
          .snapshots()
          .firstWhere((s) => s.exists)
          .timeout(const Duration(seconds: 5));
      return UserModel.fromFirestore(waited);
    } catch (_) {
      return UserModel.fallback(user);
    }
  }

  @override
  Future<UserModel> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;

    try {
      await _userRef(user.uid).update({'lastLogin': FieldValue.serverTimestamp()});
    } catch (_) {
      // Gagal mencatat lastLogin tidak boleh menggagalkan login.
    }
    return _loadUser(user);
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    final cred = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final user = cred.user!;

    try {
      await user.updateDisplayName(cleanName);
      await _userRef(user.uid).set({
        'name': cleanName,
        'email': cleanEmail,
        'role': 'student', // role admin hanya boleh diatur lewat console/admin
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Hindari akun "yatim" (ada di Auth, tidak ada di Firestore).
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    }

    return UserModel(uid: user.uid, name: cleanName, email: cleanEmail);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());
}