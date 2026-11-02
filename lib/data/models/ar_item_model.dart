import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/ar_item.dart';

class ArItemModel extends ArItem {
  const ArItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.markerUrl,
    required super.modelUrl,
    super.markerImageUrl,
    super.credit,
    super.scale,
    super.offsetY,
    super.rotationX,
    super.rotationY,
    super.rotationZ,
    super.animate,
    super.order,
    super.isPublished,
  });

  factory ArItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};

    double number(String key, double fallback) =>
        (d[key] as num?)?.toDouble() ?? fallback;

    return ArItemModel(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      markerUrl: (d['markerUrl'] as String?) ?? '',
      modelUrl: (d['modelUrl'] as String?) ?? '',
      markerImageUrl: (d['markerImageUrl'] as String?) ?? '',
      credit: (d['credit'] as String?) ?? '',
      scale: number('scale', 1),
      offsetY: number('offsetY', 0),
      rotationX: number('rotationX', 0),
      rotationY: number('rotationY', 0),
      rotationZ: number('rotationZ', 0),
      animate: (d['animate'] as bool?) ?? true,
      order: (d['order'] as num?)?.toInt() ?? 0,
      isPublished: (d['isPublished'] as bool?) ?? false,
    );
  }
}
