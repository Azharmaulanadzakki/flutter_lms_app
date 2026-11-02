import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../domain/entities/ar_item.dart';
import '../../../../injection_container.dart';
import '../../../blocs/ar/ar_cubits.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/ar_widgets.dart';
import '../../../widgets/state_views.dart';
import 'ar_viewer_entry.dart';

/// Halaman pilih mode untuk satu model AR.
class ArItemPage extends StatelessWidget {
  const ArItemPage({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ArItemCubit>()..load(itemId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Model AR')),
        body: BlocBuilder<ArItemCubit, ArItemState>(
          builder: (context, state) {
            final item = state.item;

            if (item == null) {
              if (state.status == ArLoadStatus.failure) {
                return ErrorView(
                  message: state.error ?? 'Gagal memuat model AR.',
                  onRetry: () => context.read<ArItemCubit>().load(itemId),
                );
              }
              return const LoadingView();
            }
            return _Content(item: item);
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.item});

  final ArItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supported = isArPlatformSupported;
    final hasMarker = item.markerUrl.trim().isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkerThumb(url: item.markerImageUrl, size: 96),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.description, style: theme.textTheme.bodyMedium),
                  ],
                  if (item.credit.isNotEmpty)
                    TextButton(
                      onPressed: () => showCreditDialog(context, item),
                      child: const Text('Kredit model'),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (!supported)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('AR hanya tersedia di aplikasi Android.'),
          ),
        _ModeTile(
          icon: Icons.threed_rotation,
          title: 'Lihat 3D',
          subtitle: 'Putar dan zoom model. Tanpa kamera dan tanpa marker.',
          enabled: supported,
          onTap: () => context.push('/ar/${item.id}/view'),
        ),
        const SizedBox(height: 12),
        _ModeTile(
          icon: Icons.view_in_ar,
          title: 'AR tanpa marker',
          subtitle: 'Letakkan model di meja atau lantai. Butuh HP yang mendukung ARCore.',
          enabled: supported,
          onTap: () async {
            final error = await launchSceneViewer(
              modelUrl: item.modelUrl,
              title: item.title,
            );
            if (error != null && context.mounted) {
              showAppSnackBar(context, error, isError: true);
            }
          },
        ),
        const SizedBox(height: 12),
        _ModeTile(
          icon: Icons.center_focus_strong,
          title: 'AR marker (eksperimental)',
          subtitle: hasMarker
              ? 'Arahkan kamera ke gambar marker. Paling bergantung pada kualitas gambar dan HP.'
              : 'Model ini belum punya marker.',
          enabled: supported && hasMarker,
          onTap: () => context.push('/ar/${item.id}/marker'),
        ),
        if (item.markerImageUrl.isNotEmpty) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showMarkerDialog(context, item),
            icon: const Icon(Icons.image_outlined),
            label: const Text('Lihat gambar marker'),
          ),
        ],
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
