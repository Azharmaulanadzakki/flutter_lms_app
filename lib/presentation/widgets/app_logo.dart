import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Logo sementara. Ganti isinya dengan Image.asset kalau sudah punya logo.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

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