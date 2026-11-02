import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PdfMaterialView extends StatelessWidget {
  const PdfMaterialView({super.key, required this.url});

  final String url;

  Future<void> _openPdf(BuildContext context) async {
    final uri = Uri.tryParse(url.trim());

    if (uri == null ||
        !uri.hasScheme ||
        !{'http', 'https'}.contains(uri.scheme)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('URL PDF tidak valid.')));
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF gagal dibuka. Periksa URL atau akses file.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuka PDF: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return const Center(child: Text('URL PDF belum tersedia.'));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Materi PDF',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buka dokumen untuk membaca materi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openPdf(context),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Buka PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
