import 'package:equatable/equatable.dart';

enum UserRole { student, teacher, admin, superAdmin }

extension UserRoleX on UserRole {
  /// Nilai yang disimpan di Firestore (field `role`).
  String get value {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.teacher:
        return 'teacher';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'superadmin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Siswa';
      case UserRole.teacher:
        return 'Guru';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  /// Guru, admin, dan super admin memakai panel admin.
  bool get isStaff => this != UserRole.student;
}

UserRole userRoleFromValue(String? value) {
  switch (value) {
    case 'teacher':
      return UserRole.teacher;
    case 'admin':
      return UserRole.admin;
    case 'superadmin':
      return UserRole.superAdmin;
    default:
      return UserRole.student;
  }
}

class UserEntity extends Equatable {
  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.role = UserRole.student,
    this.photoUrl,
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? photoUrl;

  /// Akun nonaktif tidak bisa login. Dokumen lama tanpa field ini dianggap aktif.
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  /// Guru, admin, atau super admin (boleh membuka panel admin).
  bool get isStaff => role.isStaff;

  bool get isSuperAdmin => role == UserRole.superAdmin;

  /// Role `admin` atau `superadmin`. Untuk hak akses panel, pakai [isStaff].
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;

  @override
  List<Object?> get props =>
      [uid, name, email, role, photoUrl, isActive, createdAt, lastLogin];
}