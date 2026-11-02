import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/ar_item.dart';
import '../../../injection_container.dart';
import '../../blocs/ar/admin_ar_cubit.dart';
import '../../blocs/ar/ar_cubits.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/ar_widgets.dart';
import '../../widgets/state_views.dart';
import 'admin_widgets.dart';

class AdminArListPage extends StatelessWidget {
  const AdminArListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AdminArCubit>()..load(),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AdminArCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Model AR')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/admin/ar/new').then((_) => cubit.load()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Model AR'),
      ),
      body: BlocConsumer<AdminArCubit, AdminArState>(
        listenWhen: (prev, curr) => curr.error != null || curr.info != null,
        listener: (context, state) {
          if (state.error != null) {
            showAppSnackBar(context, state.error!, isError: true);
          } else if (state.info != null) {
            showAppSnackBar(context, state.info!);
          }
        },
        builder: (context, state) {
          final items = state.items;

          if (items == null) {
            if (state.status == ArLoadStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat daftar model AR.',
                onRetry: cubit.load,
              );
            }
            return const LoadingView();
          }

          if (items.isEmpty) {
            return const EmptyView(
              icon: Icons.view_in_ar_outlined,
              message: 'Belum ada model AR. Tekan Tambah Model AR untuk membuat yang pertama.',
            );
          }

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
                      for (final item in items) ...[
                        _ArRow(item: item, busy: state.isBusy),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ArRow extends StatelessWidget {
  const _ArRow({required this.item, required this.busy});

  final ArItem item;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<AdminArCubit>();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          MarkerThumb(url: item.markerImageUrl, size: 60),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? '(tanpa judul)' : item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    item.isPublished
                        ? StatusPill(
                            label: 'Dipublikasikan',
                            color: Colors.green.shade700,
                          )
                        : StatusPill(
                            label: 'Draft',
                            color: Colors.orange.shade800,
                          ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Urutan ${item.order} · skala ${item.scale}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            enabled: !busy,
            onSelected: (value) async {
              switch (value) {
                case 'try':
                  context.push('/ar/${item.id}');
                case 'edit':
                  context
                      .push('/admin/ar/${item.id}')
                      .then((_) => cubit.load());
                case 'toggle':
                  cubit.setPublished(item.id, !item.isPublished);
                case 'delete':
                  final ok = await confirmAction(
                    context,
                    title: 'Hapus model AR?',
                    message:
                        'Model "${item.title}" akan dihapus permanen. File di GitHub tidak ikut terhapus.',
                    confirmLabel: 'Hapus',
                    destructive: true,
                  );
                  if (ok) cubit.delete(item.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'try', child: Text('Coba AR')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(item.isPublished ? 'Sembunyikan' : 'Publikasikan'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Hapus')),
            ],
          ),
        ],
      ),
    );
  }
}
