import 'package:flutter/material.dart';

import '../../../../../core/utils/external_link.dart';
import '../../../../widgets/app_snackbar.dart';

/// Ditampilkan jika materi kosong atau link tidak valid.
class UnavailableMaterialView extends StatelessWidget {
  const UnavailableMaterialView({super.key, required this.message, this.url});

  final String message;

  /// Jika diisi, muncul tombol untuk membuka link tersebut.
  final String? url;

  @override
  Widget build(BuildContext context) {
    final link = url;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (link != null && link.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final ok = await openExternalUrl(link);
                  if (!ok && context.mounted) {
                    showAppSnackBar(context, 'Link tidak bisa dibuka.',
                        isError: true);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka link'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}