// Di Android memakai panggung 3D penuh. Di web (dashboard online) memakai
// versi sederhana tanpa dart:io dan WebView.
export 'stage_stub.dart' if (dart.library.io) 'stage_native.dart';