import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/entities/course_material.dart';

String materialTypeLabel(MaterialKind type) {
  switch (type) {
    case MaterialKind.text:
      return 'Bacaan';
    case MaterialKind.video:
      return 'Video';
    case MaterialKind.pdf:
      return 'PDF';
  }
}

IconData materialTypeIcon(MaterialKind type) {
  switch (type) {
    case MaterialKind.text:
      return Icons.article_outlined;
    case MaterialKind.video:
      return Icons.play_circle_outline;
    case MaterialKind.pdf:
      return Icons.picture_as_pdf_outlined;
  }
}

class MaterialTile extends StatelessWidget {
  const MaterialTile({
    super.key,
    required this.index,
    required this.material,
    required this.done,
    required this.onTap,
  });

  /// Nomor urut tampilan (mulai dari 1).
  final int index;
  final CourseMaterial material;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withAlpha(25),
                  child: Text(
                    '$index',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            materialTypeIcon(material.type),
                            size: 14,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            materialTypeLabel(material.type),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (done)
                  Icon(Icons.check_circle, color: Colors.green.shade600)
                else
                  const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}