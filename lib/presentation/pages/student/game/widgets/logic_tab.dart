import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/game/game_models.dart';
import '../../../../../domain/game/game_session.dart';
import '../../../../../domain/game/logic_blocks.dart';
import '../../../../../domain/game/rule_text.dart';
import '../../../../blocs/game/game_cubits.dart';
import 'rule_editor_sheet.dart';

class LogicTab extends StatelessWidget {
  const LogicTab({super.key, required this.mission});

  final MissionDefinition mission;

  Future<void> _edit(BuildContext context, {int? index}) async {
    final cubit = context.read<GameSessionCubit>();
    final initial = index == null ? null : cubit.state.session.rules[index];

    final rule = await showModalBottomSheet<Rule>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => RuleEditorSheet(mission: mission, initial: initial),
    );
    if (rule == null) return;

    if (index == null) {
      cubit.addRule(rule);
    } else {
      cubit.replaceRule(index, rule);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) => !identical(p.session.rules, c.session.rules),
      builder: (context, state) {
        final cubit = context.read<GameSessionCubit>();
        final rules = state.session.rules;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Aturan dibaca dari atas ke bawah tiap 0,1 detik. Jika dua aturan memberi '
              'perintah ke perangkat yang sama, aturan paling bawah menang. Perangkat '
              'tanpa perintah mempertahankan keadaannya.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (rules.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text('Belum ada aturan. Tekan Tambah aturan.'),
              ),
            for (var i = 0; i < rules.length; i++)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        describeRule(mission, rules[i]),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _edit(context, index: i);
                        } else {
                          cubit.removeRule(i);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ],
                ),
              ),
            OutlinedButton.icon(
              onPressed: state.session.canAddRule ? () => _edit(context) : null,
              icon: const Icon(Icons.add),
              label: Text(
                state.session.canAddRule
                    ? 'Tambah aturan'
                    : 'Batas ${GameSession.maxRules} aturan tercapai',
              ),
            ),
          ],
        );
      },
    );
  }
}
