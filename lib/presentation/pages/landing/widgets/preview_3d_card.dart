import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Placeholder preview simulasi 3D.
/// Nanti ganti isi Stack dengan screenshot game:
/// Image.asset('assets/images/preview_3d.png', fit: BoxFit.cover)
class Preview3dCard extends StatelessWidget {
  const Preview3dCard({super.key});

  static const _modes = ['Learning', 'Challenge', 'Assembly', 'Free'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: AppColors.dark,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.developer_board, color: AppColors.accent, size: 44),
                  Icon(Icons.memory, color: Colors.white, size: 44),
                  Icon(Icons.storage, color: AppColors.accent, size: 44),
                  Icon(Icons.power_settings_new, color: Colors.greenAccent, size: 44),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Simulasi Perakitan PC 3D',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final mode in _modes)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mode,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}