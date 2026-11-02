import '../entities/user_entity.dart';

abstract class UserAdminRepository {
  Future<List<UserEntity>> getAllUsers();
  Future<UserEntity> getUser(String uid);

  /// Mengembalikan uid akun baru. Akun super admin yang sedang login tidak terganggu.
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> updateUser({
    required String uid,
    required String name,
    required UserRole role,
  });

  Future<void> setActive(String uid, bool active);
  Future<void> sendPasswordReset(String email);
}
