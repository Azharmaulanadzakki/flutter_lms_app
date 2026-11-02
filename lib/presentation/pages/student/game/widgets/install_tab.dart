import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/game/game_models.dart';
import '../../../../blocs/game/game_cubits.dart';
import '../../../../widgets/app_snackbar.dart';
import 'device_icons.dart';

class InstallTab extends StatelessWidget {
  const InstallTab({super.key, required this.mission});

  final MissionDefinition mission;

  Future<void> _pickSlot(BuildContext context, DeviceItem device) async {
    final cubit = context.read<GameSessionCubit>();
    final circuit = cubit.state.session.circuit;

    final free = [
      for (final s in mission.slots)
        if (s.kind == device.kind.slotKind &&
            !circuit.installed.containsValue(s.id))
          s,
    ];
    if (free.isEmpty) {
      showAppSnackBar(
        context,
        'Tidak ada dudukan kosong untuk perangkat ini.',
        isError: true,
      );
      return;
    }

    final slot = await showModalBottomSheet<MountSlot>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Pasang ${device.displayName} di...',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            for (final s in free)
              ListTile(
                leading: const Icon(Icons.place_outlined),
                title: Text(s.label),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );

    if (slot != null) cubit.install(device.id, slot.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<GameSessionCubit, GameSessionState>(
      buildWhen: (p, c) =>
          !identical(p.session.circuit, c.session.circuit) ||
          p.selectedDeviceId != c.selectedDeviceId,
      builder: (context, state) {
        final cubit = context.read<GameSessionCubit>();
        final circuit = state.session.circuit;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Pilih komponen, lalu ketuk dudukan hijau di panggung 3D. '
              'Atau tekan Pasang. Ketuk dudukan yang terisi untuk melepasnya.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final device in mission.devices)
              Builder(
                builder: (context) {
                  final slotId = circuit.slotOf(device.id);
                  final slotLabel = slotId == null
                      ? null
                      : mission.slotById(slotId)?.label;
                  final selected = state.selectedDeviceId == device.id;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(25),
                          child: Icon(
                            deviceIcon(device.kind),
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device.displayName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                slotLabel == null
                                    ? 'Di rak · butuh ${device.kind.slotKind.label.toLowerCase()}'
                                    : 'Terpasang di $slotLabel',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (slotId == null) ...[
                          IconButton(
                            tooltip: selected ? 'Batalkan pilihan' : 'Pilih',
                            icon: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.touch_app_outlined,
                            ),
                            onPressed: () =>
                                cubit.selectDevice(selected ? null : device.id),
                          ),
                          TextButton(
                            onPressed: () => _pickSlot(context, device),
                            child: const Text('Pasang'),
                          ),
                        ] else
                          TextButton(
                            onPressed: () => cubit.uninstall(device.id),
                            child: const Text('Lepas'),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
