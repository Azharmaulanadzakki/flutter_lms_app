import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

enum ActivityState { available, done, locked }

/// Baris aktivitas: pre-test, simulasi 3D, post-test.
class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final ActivityState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = state == ActivityState.locked;

    final Widget trailing;
    switch (state) {
      case ActivityState.done:
        trailing = Icon(Icons.check_circle, color: Colors.green.shade600);
      case ActivityState.locked:
        trailing = const Icon(Icons.lock_outline, color: Colors.grey);
      case ActivityState.available:
        trailing = const Icon(Icons.chevron_right);
    }

    return Opacity(
      opacity: locked ? 0.6 : 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}