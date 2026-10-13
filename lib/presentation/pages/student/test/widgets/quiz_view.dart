import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/quiz_test.dart';
import '../../../../blocs/test/test_bloc.dart';
import 'test_dialogs.dart';

class QuizView extends StatelessWidget {
  const QuizView({super.key, required this.state, required this.type});

  final TestState state;
  final TestType type;

  Future<void> _submit(BuildContext context) async {
    final bloc = context.read<TestBloc>();
    final unanswered = state.questions.length - state.answers.length;
    final ok = await confirmSubmitDialog(context, unanswered: unanswered);
    if (ok) bloc.add(const TestSubmitPressed());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bloc = context.read<TestBloc>();

    final questions = state.questions;
    final question = questions[state.index];
    final selected = state.answers[question.id];
    final isFirst = state.index == 0;
    final isLast = state.index == questions.length - 1;
    final hasTimer = state.attempt?.hasTimer ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(type.label),
        actions: [
          if (hasTimer)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: _TimerChip()),
            ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (state.index + 1) / questions.length,
            minHeight: 4,
          ),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: questions.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final answered = state.answers.containsKey(questions[i].id);
                final current = i == state.index;
                return InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => bloc.add(TestIndexChanged(i)),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current
                          ? AppColors.primary
                          : answered
                              ? AppColors.primary.withAlpha(40)
                              : Colors.white,
                      border: Border.all(
                        color: (current || answered)
                            ? AppColors.primary
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: current ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  'Soal ${state.index + 1} dari ${questions.length}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    question.text,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < question.options.length; i++) ...[
                  _OptionTile(
                    label: String.fromCharCode(65 + i),
                    text: question.options[i],
                    selected: selected == i,
                    onTap: () => bloc.add(TestOptionSelected(
                      questionId: question.id,
                      optionIndex: i,
                    )),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isFirst
                      ? null
                      : () => bloc.add(TestIndexChanged(state.index - 1)),
                  child: const Text('Sebelumnya'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: isLast
                      ? () => _submit(context)
                      : () => bloc.add(TestIndexChanged(state.index + 1)),
                  child: Text(isLast ? 'Kirim Jawaban' : 'Berikutnya'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dipisah supaya hanya chip ini yang dibangun ulang tiap detik.
class _TimerChip extends StatelessWidget {
  const _TimerChip();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TestBloc, TestState, int?>(
      selector: (state) => state.remainingSeconds,
      builder: (context, seconds) {
        if (seconds == null) return const SizedBox.shrink();

        final m = (seconds ~/ 60).toString().padLeft(2, '0');
        final s = (seconds % 60).toString().padLeft(2, '0');
        final urgent = seconds <= 60;
        final color = urgent ? Colors.red.shade700 : AppColors.primary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.timer_outlined, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                '$m:$s',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withAlpha(25) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
          width: selected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor:
                      selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}