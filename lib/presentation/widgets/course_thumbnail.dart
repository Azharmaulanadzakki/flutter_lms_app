import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Gambar course. Jika URL kosong atau gagal dimuat,
/// tampil placeholder bergradasi.
class CourseThumbnail extends StatelessWidget {
  const CourseThumbnail({super.key, required this.url, this.height = 120});

  final String url;
  final double height;

  @override
  Widget build(BuildContext context) {
    const placeholder = DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Icon(Icons.memory, color: Colors.white54, size: 40),
      ),
    );

    return SizedBox(
      height: height,
      width: double.infinity,
      child: url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => placeholder,
              errorWidget: (context, url, error) => placeholder,
            ),
    );
  }
}