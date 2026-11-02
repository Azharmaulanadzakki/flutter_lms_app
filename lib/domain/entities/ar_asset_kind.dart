enum ArAssetKind { model, marker, image }

extension ArAssetKindX on ArAssetKind {
  String get label {
    switch (this) {
      case ArAssetKind.model:
        return 'model 3D (.glb)';
      case ArAssetKind.marker:
        return 'marker (.mind)';
      case ArAssetKind.image:
        return 'gambar marker';
    }
  }

  String get folder {
    switch (this) {
      case ArAssetKind.model:
        return 'models';
      case ArAssetKind.marker:
        return 'markers';
      case ArAssetKind.image:
        return 'images';
    }
  }

  List<String> get extensions {
    switch (this) {
      case ArAssetKind.model:
        return const ['glb'];
      case ArAssetKind.marker:
        return const ['mind'];
      case ArAssetKind.image:
        return const ['png', 'jpg', 'jpeg', 'webp'];
    }
  }

  int get maxBytes {
    switch (this) {
      case ArAssetKind.model:
        return 30 * 1024 * 1024;
      case ArAssetKind.marker:
        return 10 * 1024 * 1024;
      case ArAssetKind.image:
        return 5 * 1024 * 1024;
    }
  }

  String contentTypeFor(String ext) {
    switch (ext) {
      case 'glb':
        return 'model/gltf-binary';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
