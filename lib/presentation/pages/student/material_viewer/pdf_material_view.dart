// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PdfMaterialView extends StatefulWidget {
  const PdfMaterialView({
    super.key,
    required this.url,
  });

  final String url;

  @override
  State<PdfMaterialView> createState() => _PdfMaterialViewState();
}

class _PdfMaterialViewState extends State<PdfMaterialView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();

    final pdfUrl = Uri.encodeComponent(widget.url);
    final viewerUrl =
        'https://docs.google.com/gview?embedded=1&url=$pdfUrl';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _isLoading = false;
                _error = 'Gagal memuat PDF: ${error.description}';
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(viewerUrl));
  }

  @override
  void didUpdateWidget(covariant PdfMaterialView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      final pdfUrl = Uri.encodeComponent(widget.url);
      final viewerUrl =
          'https://docs.google.com/gview?embedded=1&url=$pdfUrl';

      setState(() {
        _isLoading = true;
        _error = null;
      });

      _controller.loadRequest(Uri.parse(viewerUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) {
      return const Center(
        child: Text('URL PDF belum tersedia.'),
      );
    }

    return Stack(
      children: [
        if (_error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      final pdfUrl = Uri.encodeComponent(widget.url);
                      final viewerUrl =
                          'https://docs.google.com/gview?embedded=1&url=$pdfUrl';

                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });

                      _controller.loadRequest(Uri.parse(viewerUrl));
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          )
        else
          WebViewWidget(controller: _controller),
        if (_isLoading && _error == null)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}