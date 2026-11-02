import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/entities/user_form_data.dart';
import '../../../domain/usecases/users/user_usecases.dart';
import '../../../injection_container.dart';
import '../../blocs/admin/admin_form_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminUserFormPage extends StatelessWidget {
  const AdminUserFormPage({super.key, this.uid});

  /// Null = pengguna baru.
  final String? uid;

  @override
  Widget build(BuildContext context) {
    final actorUid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) => AdminFormCubit<UserFormData>(
        load: () => sl<GetUserFormUseCase>()(uid),
        save: (data) => sl<SaveUserUseCase>()(actorUid: actorUid, data: data),
      )..init(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(uid == null ? 'Tambah Pengguna' : 'Edit Pengguna'),
        ),
        body:
            BlocConsumer<
              AdminFormCubit<UserFormData>,
              AdminFormState<UserFormData>
            >(
              listenWhen: (prev, curr) =>
                  prev.status != curr.status || curr.error != null,
              listener: (context, state) => handleAdminFormState(
                context,
                state,
                savedMessage: 'Pengguna tersimpan.',
              ),
              builder: (context, state) {
                final initial = state.initial;

                if (initial == null) {
                  if (state.status == AdminFormStatus.failure) {
                    return ErrorView(
                      message: state.loadError ?? 'Gagal memuat data.',
                      onRetry: () =>
                          context.read<AdminFormCubit<UserFormData>>().init(),
                    );
                  }
                  return const LoadingView();
                }

                return _UserForm(
                  initial: initial,
                  isSaving: state.status == AdminFormStatus.saving,
                  isSelf: !initial.isNew && initial.uid == actorUid,
                );
              },
            ),
      ),
    );
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({
    required this.initial,
    required this.isSaving,
    required this.isSelf,
  });

  final UserFormData initial;
  final bool isSaving;
  final bool isSelf;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _email;
  final _password = TextEditingController();
  late UserRole _role;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial.name);
    _email = TextEditingController(text: widget.initial.email);
    _role = widget.initial.role;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AdminFormCubit<UserFormData>>().submit(
      UserFormData(
        uid: widget.initial.uid,
        name: _name.text,
        email: _email.text,
        password: _password.text,
        role: _role,
      ),
    );
  }

  String _roleHint(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'Belajar di aplikasi: course, materi, test, dan progress.';
      case UserRole.teacher:
        return 'Memakai panel admin: kelola course, materi, test, dan melihat progress siswa.';
      case UserRole.admin:
        return 'Sama seperti guru. Cocok untuk pengelola konten.';
      case UserRole.superAdmin:
        return 'Semua hak admin, ditambah mengelola pengguna.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.initial.isNew;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Nama lengkap',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    enabled: isNew,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      helperText: isNew
                          ? null
                          : 'Email tidak bisa diubah setelah akun dibuat',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: isNew ? Validators.email : null,
                  ),
                  if (isNew) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password sementara',
                        helperText: 'Minimal 6 karakter',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<UserRole>(
                    initialValue: _role,
                    decoration: InputDecoration(
                      labelText: 'Role',
                      helperText: widget.isSelf
                          ? 'Kamu tidak bisa mengubah role akunmu sendiri'
                          : null,
                    ),
                    items: [
                      for (final role in UserRole.values)
                        DropdownMenuItem(value: role, child: Text(role.label)),
                    ],
                    onChanged: widget.isSelf
                        ? null
                        : (value) => setState(() => _role = value ?? _role),
                  ),
                  const SizedBox(height: 8),
                  Text(_roleHint(_role), style: theme.textTheme.bodySmall),
                  if (isNew) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Berikan email dan password sementara ini kepada pengguna. '
                        'Mereka bisa menggantinya lewat "Lupa password" di halaman login.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: widget.isSaving ? null : _submit,
                    child: widget.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isNew ? 'Buat Akun' : 'Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
