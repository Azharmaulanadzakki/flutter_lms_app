import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/quiz_test.dart';

class TestIntroView extends StatelessWidget {
  const TestIntroView({
    super.key,
    required this.test,
    required this.resume,
    required this.isBusy,
    required this.onStart,
  });

  final QuizTest test;

  /// True jika ada sesi yang belum selesai.
  final bool resume;
  final bool isBusy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countText = test.questionCount > 0
        ? '${test.questionCount} soal'
        : 'Semua soal yang tersedia';
    final timeText = test.hasTimer
        ? '${test.durationMinutes} menit'
        : 'Tanpa batas waktu';

    return Scaffold(
      appBar: AppBar(title: Text(test.type.label)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.quiz_outlined, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                Text(
                  test.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _InfoRow(icon: Icons.format_list_numbered, text: countText),
          _InfoRow(icon: Icons.timer_outlined, text: timeText),
          const _InfoRow(icon: Icons.shuffle, text: 'Urutan soal diacak'),
          const _InfoRow(
            icon: Icons.lock_outline,
            text: 'Jawaban tidak bisa diubah setelah dikirim',
          ),
          const _InfoRow(
            icon: Icons.looks_one_outlined,
            text: 'Hanya bisa dikerjakan satu kali',
          ),
          if (test.hasTimer)
            const _InfoRow(
              icon: Icons.hourglass_bottom,
              text: 'Waktu tetap berjalan walau aplikasi ditutup',
            ),
          if (resume) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Kamu punya sesi yang belum selesai. Tekan Lanjutkan untuk meneruskannya.',
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: isBusy ? null : onStart,
            child: isBusy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(resume ? 'Lanjutkan' : 'Mulai'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
