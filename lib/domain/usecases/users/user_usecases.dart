import '../../../core/errors/failures.dart';
import '../../../core/utils/validators.dart';
import '../../entities/user_entity.dart';
import '../../entities/user_form_data.dart';
import '../../repositories/user_admin_repository.dart';

class GetAllUsersUseCase {
  const GetAllUsersUseCase(this._repo);

  final UserAdminRepository _repo;

  Future<List<UserEntity>> call() => _repo.getAllUsers();
}

/// Data awal form: pengguna yang diedit, atau form kosong jika [uid] null.
class GetUserFormUseCase {
  const GetUserFormUseCase(this._repo);

  final UserAdminRepository _repo;

  Future<UserFormData> call(String? uid) async {
    if (uid == null) return const UserFormData();

    final user = await _repo.getUser(uid);
    return UserFormData(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: user.role,
    );
  }
}

class SaveUserUseCase {
  const SaveUserUseCase(this._repo);

  final UserAdminRepository _repo;

  Future<void> call({
    required String actorUid,
    required UserFormData data,
  }) async {
    final name = data.name.trim();
    if (name.isEmpty) throw const Failure('Nama wajib diisi.');

    if (data.isNew) {
      final emailError = Validators.email(data.email);
      if (emailError != null) throw Failure('$emailError.');

      final passwordError = Validators.password(data.password);
      if (passwordError != null) throw Failure('$passwordError.');

      await _repo.createUser(
        name: name,
        email: data.email.trim(),
        password: data.password,
        role: data.role,
      );
      return;
    }

    final current = await _repo.getUser(data.uid);
    if (data.uid == actorUid && data.role != current.role) {
      throw const Failure('Kamu tidak bisa mengubah role akunmu sendiri.');
    }

    await _repo.updateUser(uid: data.uid, name: name, role: data.role);
  }
}

class SetUserActiveUseCase {
  const SetUserActiveUseCase(this._repo);

  final UserAdminRepository _repo;

  Future<void> call({
    required String actorUid,
    required String uid,
    required bool active,
  }) async {
    if (!active && uid == actorUid) {
      throw const Failure('Kamu tidak bisa menonaktifkan akunmu sendiri.');
    }
    await _repo.setActive(uid, active);
  }
}

class SendUserPasswordResetUseCase {
  const SendUserPasswordResetUseCase(this._repo);

  final UserAdminRepository _repo;

  Future<void> call(String email) async {
    final error = Validators.email(email);
    if (error != null) throw Failure('$error.');
    await _repo.sendPasswordReset(email.trim());
  }
}
