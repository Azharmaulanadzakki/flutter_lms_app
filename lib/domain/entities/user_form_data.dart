import 'package:equatable/equatable.dart';

import 'user_entity.dart';

/// Isi form tambah atau ubah pengguna. `uid` kosong berarti pengguna baru.
class UserFormData extends Equatable {
  const UserFormData({
    this.uid = '',
    this.name = '',
    this.email = '',
    this.password = '',
    this.role = UserRole.student,
  });

  final String uid;
  final String name;
  final String email;
  final String password;
  final UserRole role;

  bool get isNew => uid.isEmpty;

  @override
  List<Object?> get props => [uid, name, email, password, role];
}
