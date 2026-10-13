import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';

abstract class SettingsRemoteDataSource {
  /// Data mentah dokumen bobot progress, atau null jika dokumen tidak ada.
  Future<Map<String, dynamic>?> getProgressWeightsData();
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  SettingsRemoteDataSourceImpl(this._db);

  final FirebaseFirestore _db;

  @override
  Future<Map<String, dynamic>?> getProgressWeightsData() async {
    final snap = await _db
        .collection(FirestorePaths.settings)
        .doc(FirestorePaths.progressWeightsDoc)
        .get();
    return snap.data();
  }
}