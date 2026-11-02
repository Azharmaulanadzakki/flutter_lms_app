import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/entities/ar_item.dart';

/// Gambar kecil marker. Jika URL kosong atau gagal dimuat, tampil ikon AR.
class MarkerThumb extends StatelessWidget {
  const MarkerThumb({super.key, required this.url, this.size = 72});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: AppColors.primary.withAlpha(25),
      child: const Icon(Icons.view_in_ar, color: AppColors.primary),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (context, url) => placeholder,
              errorWidget: (context, url, error) => placeholder,
            ),
    );
  }
}

/// Menampilkan gambar marker supaya bisa diarahkan kamera
/// (dari layar lain atau hasil cetak).
Future<void> showMarkerDialog(BuildContext context, ArItem item) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Marker: ${item.title}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.markerImageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.markerImageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const SizedBox(
                    height: 160,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => const SizedBox(
                    height: 160,
                    child: Center(child: Text('Gambar marker gagal dimuat.')),
                  ),
                ),
              )
            else
              const Text('Gambar marker belum tersedia.'),
            const SizedBox(height: 12),
            const Text(
              'Arahkan kamera HP ke gambar ini. Tampilkan di layar lain atau '
              'cetak, pastikan seluruh gambar terlihat dan pencahayaan cukup.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

Future<void> showCreditDialog(BuildContext context, ArItem item) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Kredit model 3D'),
      content: SelectableText(item.credit),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}
