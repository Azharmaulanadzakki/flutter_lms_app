import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/app_logo.dart';
import 'widgets/feature_card.dart';
import 'widgets/preview_3d_card.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _features = [
    (Icons.menu_book, 'Course Terstruktur', 'Materi dari pengenalan komponen sampai troubleshooting.'),
    (Icons.quiz, 'Pre-Test & Post-Test', 'Ukur peningkatan belajarmu di setiap course.'),
    (Icons.memory, 'Simulasi 3D', 'Praktik merakit PC tanpa takut salah pasang.'),
    (Icons.insights, 'Pantau Progress', 'Lihat nilai dan perkembangan belajarmu.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _Hero(theme: theme),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Preview Pembelajaran 3D',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Preview3dCard(),
                      const SizedBox(height: 32),
                      Text('Fitur Utama',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const gap = 12.0;
                          final width = (constraints.maxWidth - gap) / 2;
                          return Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final f in _features)
                                SizedBox(
                                  width: width,
                                  child: FeatureCard(
                                    icon: f.$1,
                                    title: f.$2,
                                    subtitle: f.$3,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () => context.push('/register'),
                        child: const Text('Register'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => context.push('/login'),
                        child: const Text('Login'),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '© ${DateTime.now().year} ${AppStrings.appName}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const AppLogo(size: 36),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.appName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        onPressed: () => context.push('/login'),
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    AppStrings.tagline,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.description,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => context.push('/register'),
                    child: const Text('Mulai Belajar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}