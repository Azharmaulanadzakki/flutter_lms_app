import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/game/game_sync_cubit.dart';

/// Ikon status sinkronisasi di AppBar. Ketuk untuk melihat rincian.
class SyncAction extends StatelessWidget {
  const SyncAction({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameSyncCubit, GameSyncState>(
      builder: (context, state) {
        final Widget icon;
        final String tooltip;

        if (state.syncing) {
          tooltip = 'Mengirim hasil...';
          icon = const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        } else if (state.blocked > 0) {
          tooltip = '${state.blocked} hasil ditolak server';
          icon = Icon(Icons.error_outline, color: Colors.red.shade700);
        } else if (state.pending > 0) {
          tooltip = '${state.pending} hasil menunggu dikirim';
          icon = Badge(
            label: Text('${state.pending}'),
            child: Icon(state.offline ? Icons.cloud_off : Icons.cloud_upload_outlined),
          );
        } else {
          tooltip = 'Semua hasil sudah terkirim';
          icon = Icon(Icons.cloud_done_outlined, color: Colors.green.shade700);
        }

        return IconButton(
          tooltip: tooltip,
          icon: icon,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => BlocProvider.value(
              value: context.read<GameSyncCubit>(),
              child: _SyncSheet(userId: userId),
            ),
          ),
        );
      },
    );
  }
}

class _SyncSheet extends StatelessWidget {
  const _SyncSheet({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSyncCubit, GameSyncState>(
      builder: (context, state) {
        final String title;
        final String body;

        if (state.syncing) {
          title = 'Mengirim hasil...';
          body = 'Mohon tunggu sebentar.';
        } else if (state.blocked > 0) {
          title = '${state.blocked} hasil ditolak server';
          body = 'Hasil ini tetap tersimpan di perangkat. Tekan Kirim sekarang untuk mencoba lagi. '
              'Jika tetap ditolak, hubungi guru.';
        } else if (state.pending > 0) {
          title = '${state.pending} hasil menunggu dikirim';
          body = state.offline
              ? 'Perangkat sedang offline. Hasil aman di perangkat dan dikirim otomatis saat kamu membuka game dengan internet.'
              : 'Hasil tersimpan di perangkat dan belum terkirim.';
        } else {
          title = 'Semua hasil sudah terkirim';
          body = 'Tidak ada hasil yang menunggu.';
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(body),
                if (state.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    state.lastError!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                  ),
                ],
                if (state.pending > 0 || state.blocked > 0) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: state.syncing
                        ? null
                        : () => context.read<GameSyncCubit>().sync(userId, manual: true),
                    child: const Text('Kirim sekarang'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}