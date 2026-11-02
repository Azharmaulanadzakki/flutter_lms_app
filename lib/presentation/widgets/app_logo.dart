import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../blocs/branding/branding_cubit.dart';

/// Logo aplikasi: logo unggahan admin jika ada, jika tidak logo bawaan.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final url = context.select((BrandingCubit c) => c.state.branding.logoUrl);
    return BrandLogo(url: url, size: size);
  }
}

/// Logo dari link tertentu. Dipakai juga untuk pratinjau di form admin.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, required this.url, this.size = 48});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final link = url.trim();
    if (link.isEmpty) return _DefaultLogo(size: size);

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Container(
        width: size,
        height: size,
        color: Colors.white,
        padding: EdgeInsets.all(size * 0.1),
        child: CachedNetworkImage(
          imageUrl: link,
          fit: BoxFit.contain,
          placeholder: (context, url) => const SizedBox.shrink(),
          errorWidget: (context, url, error) => Icon(
            Icons.memory,
            color: AppColors.primary,
            size: size * 0.58,
          ),
        ),
      ),
    );
  }
}

class _DefaultLogo extends StatelessWidget {
  const _DefaultLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.accent, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(Icons.memory, color: Colors.white, size: size * 0.58),
    );
  }
}