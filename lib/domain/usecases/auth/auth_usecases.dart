import '../../entities/user_entity.dart';
import '../../repositories/auth_repository.dart';

class WatchAuthStateUseCase {
  const WatchAuthStateUseCase(this._repository);
  final AuthRepository _repository;

  Stream<UserEntity?> call() => _repository.authStateChanges();
}

class SignInUseCase {
  const SignInUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity> call({required String email, required String password}) =>
      _repository.signIn(email: email, password: password);
}

class RegisterUseCase {
  const RegisterUseCase(this._repository);
  final AuthRepository _repository;

  Future<UserEntity> call({
    required String name,
    required String email,
    required String password,
  }) =>
      _repository.register(name: name, email: email, password: password);
}

class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call() => _repository.signOut();
}

class SendPasswordResetUseCase {
  const SendPasswordResetUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call(String email) => _repository.sendPasswordReset(email);
}