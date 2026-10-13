import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../core/utils/external_link.dart';
import '../../../../../core/utils/media_links.dart';
import '../../../../widgets/app_snackbar.dart';
import 'unavailable_material_view.dart';

class PdfMaterialView extends StatefulWidget {
  const PdfMaterialView({super.key, required this.url});

  final String url;

  @override
  State<PdfMaterialView> createState() => _PdfMaterialViewState();
}

class _PdfMaterialViewState extends State<PdfMaterialView> {
  WebViewController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (!isValidHttpUrl(widget.url)) return;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && (error.isForMainFrame ?? true)) {
              setState(() {
                _failed = true;
                _loading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(pdfViewerUrl(widget.url)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (widget.url.trim().isEmpty) {
      return const UnavailableMaterialView(message: 'PDF belum tersedia.');
    }
    if (controller == null) {
      return UnavailableMaterialView(
        message: 'Link PDF tidak valid.',
        url: widget.url,
      );
    }
    if (_failed) {
      return UnavailableMaterialView(
        message: 'PDF gagal ditampilkan. Periksa koneksi internet.',
        url: widget.url,
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              WebViewWidget(controller: controller),
              if (_loading) const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: OutlinedButton.icon(
            onPressed: () async {
              final ok = await openExternalUrl(widget.url);
              if (!ok && context.mounted) {
                showAppSnackBar(context, 'Link tidak bisa dibuka.',
                    isError: true);
              }
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('Buka di browser'),
          ),
        ),
      ],
    );
  }
}