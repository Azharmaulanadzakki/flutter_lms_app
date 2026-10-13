import 'package:flutter/material.dart';

import 'unavailable_material_view.dart';

class TextMaterialView extends StatelessWidget {
  const TextMaterialView({super.key, required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const UnavailableMaterialView(
        message: 'Isi materi belum tersedia.',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SelectableText(
        content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7),
      ),
    );
  }
}