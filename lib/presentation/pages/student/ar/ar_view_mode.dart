enum ArViewMode { model3d, marker, selfTest }

extension ArViewModeX on ArViewMode {
  String get title {
    switch (this) {
      case ArViewMode.model3d:
        return 'Lihat 3D';
      case ArViewMode.marker:
        return 'AR Marker';
      case ArViewMode.selfTest:
        return 'Tes Render';
    }
  }

  /// Jalur pustaka yang harus tersedia di aplikasi untuk mode ini.
  List<String> get requiredLibs {
    switch (this) {
      case ArViewMode.model3d:
      case ArViewMode.selfTest:
        return const ['/lib/model-viewer.min.js'];
      case ArViewMode.marker:
        return const [
          '/lib/aframe.min.js',
          '/lib/mindar-image-aframe.prod.js',
        ];
    }
  }
}