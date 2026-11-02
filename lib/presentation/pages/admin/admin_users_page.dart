import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../domain/entities/user_entity.dart';
import '../../blocs/admin/admin_status.dart';
import '../../blocs/admin/users_cubit.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

Color roleColor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return Colors.blueGrey;
    case UserRole.teacher:
      return Colors.teal.shade700;
    case UserRole.admin:
      return Colors.indigo;
    case UserRole.superAdmin:
      return Colors.deepPurple;
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String _query = '';
  UserRole? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<UsersCubit>();
    final actorUid = context.select((AuthBloc b) => b.state.user?.uid ?? '');

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/admin/users/new').then((_) => cubit.load()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Pengguna'),
      ),
      body: SafeArea(
        child: BlocConsumer<UsersCubit, UsersState>(
          listenWhen: (prev, curr) => curr.error != null || curr.info != null,
          listener: (context, state) {
            if (state.error != null) {
              showAppSnackBar(context, state.error!, isError: true);
            } else if (state.info != null) {
              showAppSnackBar(context, state.info!);
            }
          },
          builder: (context, state) {
            final users = state.users;

            if (users == null) {
              if (state.status == AdminLoadStatus.failure) {
                return ErrorView(
                  message: state.error ?? 'Gagal memuat daftar pengguna.',
                  onRetry: cubit.load,
                );
              }
              return const LoadingView();
            }

            int count(UserRole? role) => role == null
                ? users.length
                : users.where((u) => u.role == role).length;

            final q = _query.trim().toLowerCase();
            final filtered = users.where((u) {
              if (_roleFilter != null && u.role != _roleFilter) return false;
              if (q.isEmpty) return true;
              return u.name.toLowerCase().contains(q) ||
                  u.email.toLowerCase().contains(q);
            }).toList();

            return Column(
              children: [
                if (state.isBusy) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: cubit.load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                      children: [
                        Text(
                          'Pengguna (${users.length})',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Cari nama atau email',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ChoiceChip(
                                label: Text('Semua (${count(null)})'),
                                selected: _roleFilter == null,
                                onSelected: (_) =>
                                    setState(() => _roleFilter = null),
                              ),
                              for (final role in UserRole.values) ...[
                                const SizedBox(width: 8),
                                ChoiceChip(
                                  label: Text('${role.label} (${count(role)})'),
                                  selected: _roleFilter == role,
                                  onSelected: (_) =>
                                      setState(() => _roleFilter = role),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (filtered.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text('Tidak ada pengguna yang cocok.'),
                            ),
                          )
                        else
                          for (final user in filtered) ...[
                            _UserRow(
                              user: user,
                              isSelf: user.uid == actorUid,
                              busy: state.isBusy,
                              actorUid: actorUid,
                            ),
                            const SizedBox(height: 12),
                          ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Nonaktifkan membuat pengguna tidak bisa login dan bisa dibalik. '
                            'Untuk menghapus akun secara permanen, gunakan skrip '
                            'seed/delete_user.js atau Firebase Console.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isSelf,
    required this.busy,
    required this.actorUid,
  });

  final UserEntity user;
  final bool isSelf;
  final bool busy;
  final String actorUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<UsersCubit>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: user.isActive ? Colors.white : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(user.name.isEmpty ? '?' : user.name[0].toUpperCase()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSelf ? '${user.name} (kamu)' : user.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(user.email, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    StatusPill(
                      label: user.role.label,
                      color: roleColor(user.role),
                    ),
                    if (!user.isActive)
                      StatusPill(label: 'Nonaktif', color: Colors.red.shade700),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  user.lastLogin == null
                      ? 'Belum pernah login'
                      : 'Terakhir masuk ${formatDateTime(user.lastLogin!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  context
                      .push('/admin/users/${user.uid}')
                      .then((_) => cubit.load());
                case 'reset':
                  final ok = await confirmAction(
                    context,
                    title: 'Kirim reset password?',
                    message:
                        'Email berisi link untuk mengatur ulang password akan dikirim ke ${user.email}.',
                    confirmLabel: 'Kirim',
                  );
                  if (ok) cubit.sendReset(user.email);
                case 'toggle':
                  if (user.isActive) {
                    final ok = await confirmAction(
                      context,
                      title: 'Nonaktifkan akun?',
                      message:
                          '${user.name} tidak akan bisa login sampai akunnya diaktifkan lagi.',
                      confirmLabel: 'Nonaktifkan',
                      destructive: true,
                    );
                    if (!ok) return;
                  }
                  cubit.setActive(
                    actorUid: actorUid,
                    uid: user.uid,
                    active: !user.isActive,
                  );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                value: 'reset',
                child: Text('Kirim reset password'),
              ),
              PopupMenuItem(
                value: 'toggle',
                enabled: !isSelf,
                child: Text(user.isActive ? 'Nonaktifkan' : 'Aktifkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
