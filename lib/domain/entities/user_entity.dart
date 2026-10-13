import 'package:equatable/equatable.dart';

enum UserRole { student, admin }

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.photoUrl,
    this.createdAt,
    this.lastLogin,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props =>
      [uid, name, email, role, photoUrl, createdAt, lastLogin];
}