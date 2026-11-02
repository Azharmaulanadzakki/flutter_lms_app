import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import 'admin/admin_shell.dart';
import 'student/main_shell.dart';

/// Memilih tampilan utama berdasarkan role pengguna:
/// guru, admin, dan super admin ke panel admin, siswa ke aplikasi belajar.
class HomeGate extends StatelessWidget {
  const HomeGate({super.key});

  @override
  Widget build(BuildContext context) {
    final isStaff =
        context.select((AuthBloc b) => b.state.user?.isStaff ?? false);
    return isStaff ? const AdminShell() : const MainShell();
  }
}