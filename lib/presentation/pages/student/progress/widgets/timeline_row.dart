import 'package:flutter/material.dart';

/// Satu baris timeline vertikal: ikon, garis penghubung, dan teks.
class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.isLast,
    this.subtitle,
    this.time,
    this.dimmed = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// Waktu yang sudah diformat.
  final String? time;
  final bool isLast;

  /// Dibuat pudar untuk langkah yang belum tercapai.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Icon(icon, size: 24, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Opacity(
                opacity: dimmed ? 0.6 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    if (time != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          time!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
