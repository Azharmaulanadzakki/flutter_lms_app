import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/ar_item.dart';
import '../../../blocs/ar/ar_cubits.dart';
import '../../../widgets/ar_widgets.dart';
import '../../../widgets/state_views.dart';

class ArScannerPage extends StatelessWidget {
  const ArScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: BlocBuilder<ArListCubit, ArListState>(
        builder: (context, state) {
          final items = state.items;

          if (items == null) {
            if (state.status == ArLoadStatus.failure) {
              return ErrorView(
                message: state.error ?? 'Gagal memuat model AR.',
                onRetry: () => context.read<ArListCubit>().load(),
              );
            }
            return const LoadingView();
          }

          return RefreshIndicator(
            onRefresh: () => context.read<ArListCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'AR Scanner',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Lihat model 3D komponen komputer: putar di layar, letakkan di meja, atau scan marker.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const _SelfTestTile(),
                const SizedBox(height: 20),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('Belum ada model AR yang tersedia.'),
                    ),
                  )
                else
                  for (final item in items) ...[
                    _ArItemCard(item: item),
                    const SizedBox(height: 12),
                  ],
                const SizedBox(height: 12),
                const _StageDemoTile(),

                const SizedBox(height: 12),
                const _GameTile(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelfTestTile extends StatelessWidget {
  const _SelfTestTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tes Render',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Cek apakah HP-mu bisa menampilkan 3D (tanpa internet).',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/ar/test'),
            child: const Text('Coba'),
          ),
        ],
      ),
    );
  }
}

class _ArItemCard extends StatelessWidget {
  const _ArItemCard({required this.item});

  final ArItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MarkerThumb(url: item.markerImageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: () => context.push('/ar/${item.id}'),
            icon: const Icon(Icons.view_in_ar),
            label: const Text('Buka'),
          ),
        ],
      ),
    );
  }
}

class _StageDemoTile extends StatelessWidget {
  const _StageDemoTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Panggung 3D (smart home)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Uji ruangan 3D, pemasangan perangkat, dan simulasi IoT.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push('/game/stage-demo'),
            child: const Text('Coba'),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.sports_esports_outlined, color: AppColors.primary),
          
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Game Smart Home (IoT)',
          //         style: theme.textTheme.titleSmall?.copyWith(
          //           fontWeight: FontWeight.bold,
          //         ),
          //       ),
          //       Text(
          //         'Rakit, sambung kabel, dan program rumah pintar.',
          //         style: theme.textTheme.bodySmall,
          //       ),
          //     ],
          //   ),
          // ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Game Smart Home (IoT)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rakit, sambung kabel, dan program rumah pintar.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: FilledButton(
              onPressed: () => context.push('/game'),
              child: const Text('Main'),
            ),
          ),
        ],
      ),
    );
  }
}
