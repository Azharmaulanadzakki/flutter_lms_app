// Di Android memakai implementasi penuh. Di web (dashboard online)
// memakai versi sederhana tanpa dart:io dan WebView.
export 'ar_viewer_stub.dart' if (dart.library.io) 'ar_viewer_native.dart';
