import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/firestore_paths.dart';
import '../../domain/entities/branding.dart';

class BrandingRemoteDataSource {
  BrandingRemoteDataSource(this._db);

  final FirebaseFirestore _db;

  /// Dokumen settings/branding. Nama dokumen ini juga dipakai di Firestore Rules.
  static const _docId = 'branding';

  DocumentReference<Map<String, dynamic>> get _ref =>
      _db.collection(FirestorePaths.settings).doc(_docId);

  /// Null jika dokumen belum dibuat.
  Future<Branding?> get() async {
    final data = (await _ref.get()).data();
    if (data == null) return null;

    final name = ((data['appName'] as String?) ?? '').trim();
    return Branding(
      appName: name.isEmpty ? AppStrings.appName : name,
      logoUrl: ((data['logoUrl'] as String?) ?? '').trim(),
    );
  }

  Future<void> save(Branding branding) {
    return _ref.set(
      {
        'appName': branding.appName,
        'logoUrl': branding.logoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}