import 'package:equatable/equatable.dart';

/// Satu model AR: marker (.mind) dan model 3D (.glb) yang dihosting di internet.
class ArItem extends Equatable {
  const ArItem({
    required this.id,
    required this.title,
    required this.description,
    required this.markerUrl,
    required this.modelUrl,
    this.markerImageUrl = '',
    this.credit = '',
    this.scale = 1,
    this.offsetY = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.animate = true,
    this.order = 1,
    this.isPublished = false,
  });

  final String id;
  final String title;
  final String description;

  /// Link file .mind (hasil kompilasi gambar marker).
  final String markerUrl;

  /// Link file .glb (model 3D).
  final String modelUrl;

  /// Link gambar marker, untuk ditampilkan ke siswa (opsional).
  final String markerImageUrl;

  /// Atribusi pembuat model (opsional).
  final String credit;

  /// Ukuran model. 1 = kira-kira selebar marker.
  final double scale;

  /// Geser model naik atau turun dari marker.
  final double offsetY;

  /// Rotasi dalam derajat.
  final double rotationX;
  final double rotationY;
  final double rotationZ;

  /// Putar animasi bawaan model, jika ada.
  final bool animate;
  final int order;
  final bool isPublished;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    markerUrl,
    modelUrl,
    markerImageUrl,
    credit,
    scale,
    offsetY,
    rotationX,
    rotationY,
    rotationZ,
    animate,
    order,
    isPublished,
  ];
}
