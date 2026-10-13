import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Emit user saat login, `null` saat logout.
  Stream<UserEntity?> authStateChanges();

  Future<UserEntity> signIn({required String email, required String password});

  Future<UserEntity> register({
    required String name,
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);
}