import 'package:flutter/material.dart';

import 'ar_view_mode.dart';

bool get isArPlatformSupported => false;

Future<String?> launchSceneViewer({
  required String modelUrl,
  required String title,
}) async => 'AR hanya tersedia di aplikasi Android.';

class ArViewerScreen extends StatelessWidget {
  const ArViewerScreen({super.key, this.itemId, required this.mode});

  final String? itemId;
  final ArViewMode mode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(mode.title)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Fitur ini hanya tersedia di aplikasi Android.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
