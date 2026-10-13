import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.role,
    super.photoUrl,
    super.createdAt,
    super.lastLogin,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return UserModel(
      uid: doc.id,
      name: (data['name'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      role: data['role'] == 'admin' ? UserRole.admin : UserRole.student,
      photoUrl: data['photoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  /// Dipakai jika dokumen Firestore belum/tidak bisa dibaca.
  factory UserModel.fallback(fb.User user) {
    final displayName = user.displayName?.trim() ?? '';
    final email = user.email ?? '';
    return UserModel(
      uid: user.uid,
      name: displayName.isNotEmpty ? displayName : email.split('@').first,
      email: email,
      photoUrl: user.photoURL,
    );
  }
}