import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../widgets/improvement_card.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/quiz_test.dart';
import '../../../../../domain/entities/test_result.dart';

String formatScore(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

class ResultView extends StatelessWidget {
  const ResultView({super.key, required this.result, required this.type});

  final TestResult result;
  final TestType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result.score;

    return Scaffold(
      appBar: AppBar(title: Text('Hasil ${type.label}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ScoreCard(score: score, label: 'Nilai ${type.label}'),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.check_circle_outline,
                    color: Colors.green.shade600,
                    label: 'Benar',
                    value: '${result.correctCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    icon: Icons.cancel_outlined,
                    color: Colors.red.shade600,
                    label: 'Salah',
                    value: '${result.wrongCount}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Stat(
                    icon: Icons.list_alt,
                    color: AppColors.primary,
                    label: 'Total soal',
                    value: '${result.items.length}',
                  ),
                ),
              ],
            ),
          ),

          if (type == TestType.post) ...[
            const SizedBox(height: 16),
            ImprovementCard(pre: result.preTestScore, post: result.score),
            if (result.courseCompleted) ...[
              const SizedBox(height: 12),
              const CourseCompletedBanner(),
            ],
          ],

          if (type == TestType.pre) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score < 60
                    ? 'Tidak apa-apa, ini baru awal. Pelajari materinya, lalu ukur peningkatanmu di post-test.'
                    : 'Pengetahuan awalmu sudah baik. Tetap pelajari materinya untuk memperdalam.',
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Pembahasan',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < result.items.length; i++) ...[
            _ReviewCard(number: i + 1, item: result.items[i]),
            const SizedBox(height: 12),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Kembali ke Course'),
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.label});

  final double score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
                Text(
                  formatScore(score),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dari skala 0 sampai 100',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.number, required this.item});

  final int number;
  final GradedQuestion item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String badge;
    final Color badgeColor;
    if (!item.isAnswered) {
      badge = 'Tidak dijawab';
      badgeColor = Colors.blueGrey;
    } else if (item.isCorrect) {
      badge = 'Benar';
      badgeColor = Colors.green.shade700;
    } else {
      badge = 'Salah';
      badgeColor = Colors.red.shade700;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Soal $number',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.question.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < item.question.options.length; i++)
            _ReviewOption(
              label: String.fromCharCode(65 + i),
              text: item.question.options[i],
              isCorrectOption: i == item.correctIndex,
              isSelected: i == item.selectedIndex,
            ),
          if (item.explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pembahasan',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(item.explanation),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewOption extends StatelessWidget {
  const _ReviewOption({
    required this.label,
    required this.text,
    required this.isCorrectOption,
    required this.isSelected,
  });

  final String label;
  final String text;
  final bool isCorrectOption;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final Color? background;
    final IconData icon;
    final Color iconColor;

    if (isCorrectOption) {
      background = Colors.green.withAlpha(30);
      icon = Icons.check_circle;
      iconColor = Colors.green.shade700;
    } else if (isSelected) {
      background = Colors.red.withAlpha(30);
      icon = Icons.cancel;
      iconColor = Colors.red.shade700;
    } else {
      background = null;
      icon = Icons.radio_button_unchecked;
      iconColor = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text('$label. $text')),
        ],
      ),
    );
  }
}
