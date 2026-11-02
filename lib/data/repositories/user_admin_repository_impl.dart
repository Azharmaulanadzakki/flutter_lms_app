import '../../core/errors/failure_guard.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_admin_repository.dart';
import '../datasources/user_admin_remote_datasource.dart';

class UserAdminRepositoryImpl implements UserAdminRepository {
  UserAdminRepositoryImpl(this._remote);

  final UserAdminRemoteDataSource _remote;

  @override
  Future<List<UserEntity>> getAllUsers() =>
      guardFirebase<List<UserEntity>>(_remote.getAllUsers);

  @override
  Future<UserEntity> getUser(String uid) =>
      guardFirebase<UserEntity>(() => _remote.getUser(uid));

  @override
  Future<String> createUser({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) =>
      // Pembuatan akun butuh beberapa langkah, jadi batas waktunya lebih panjang.
      guardFirebase<String>(
        () => _remote.createUser(
          name: name,
          email: email,
          password: password,
          role: role,
        ),
        timeout: const Duration(seconds: 30),
      );

  @override
  Future<void> updateUser({
    required String uid,
    required String name,
    required UserRole role,
  }) => guardFirebase<void>(
    () => _remote.updateUser(uid: uid, name: name, role: role),
  );

  @override
  Future<void> setActive(String uid, bool active) =>
      guardFirebase<void>(() => _remote.setActive(uid, active));

  @override
  Future<void> sendPasswordReset(String email) =>
      guardFirebase<void>(() => _remote.sendPasswordReset(email));
}
