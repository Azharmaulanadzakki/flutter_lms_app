import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/ar_item.dart';
import '../models/ar_item_model.dart';

class ArRemoteDataSource {
  ArRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  static const _collection = 'arItems';

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(_collection);

  FieldValue get _now => FieldValue.serverTimestamp();

  Future<List<ArItem>> getPublishedItems() async {
    final snap = await _col.where('isPublished', isEqualTo: true).get();
    return _sorted(snap);
  }

  Future<List<ArItem>> getAllItems() async {
    final snap = await _col.get();
    return _sorted(snap);
  }

  List<ArItem> _sorted(QuerySnapshot<Map<String, dynamic>> snap) {
    // Diurutkan di sisi aplikasi supaya tidak butuh composite index.
    final list = snap.docs.map(ArItemModel.fromFirestore).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  Future<ArItem> getItem(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) throw const Failure('Model AR tidak ditemukan.');
    return ArItemModel.fromFirestore(snap);
  }

  Future<String> saveItem(ArItem item) async {
    final data = <String, dynamic>{
      'title': item.title,
      'description': item.description,
      'markerUrl': item.markerUrl,
      'modelUrl': item.modelUrl,
      'markerImageUrl': item.markerImageUrl,
      'credit': item.credit,
      'scale': item.scale,
      'offsetY': item.offsetY,
      'rotationX': item.rotationX,
      'rotationY': item.rotationY,
      'rotationZ': item.rotationZ,
      'animate': item.animate,
      'order': item.order,
      'isPublished': item.isPublished,
      'updatedAt': _now,
    };

    if (item.id.isEmpty) {
      final ref = _col.doc();
      await ref.set({...data, 'createdAt': _now});
      return ref.id;
    }

    await _col.doc(item.id).update(data);
    return item.id;
  }

  Future<void> setPublished(String id, bool published) =>
      _col.doc(id).update({'isPublished': published, 'updatedAt': _now});

  Future<void> deleteItem(String id) => _col.doc(id).delete();
}
