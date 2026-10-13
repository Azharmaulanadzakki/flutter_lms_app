import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            name: _nameCtrl.text,
            email: _emailCtrl.text,
            password: _passCtrl.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => curr.error != null,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        showAppSnackBar(context, state.error!, isError: true);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Buat Akun')),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'Nama lengkap',
                        icon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            Validators.requiredField(v, field: 'Nama'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passCtrl,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                        validator: Validators.password,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmCtrl,
                        label: 'Konfirmasi password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: _submit,
                        validator: (v) =>
                            Validators.confirmPassword(v, _passCtrl.text),
                      ),
                      const SizedBox(height: 24),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (p, c) => p.isLoading != c.isLoading,
                        builder: (context, state) => FilledButton(
                          onPressed: state.isLoading ? null : _submit,
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Daftar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}