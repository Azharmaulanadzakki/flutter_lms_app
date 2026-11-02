import 'dart:typed_data';

import '../../domain/repositories/ar_storage_repository.dart';
import '../datasources/supabase_storage_datasource.dart';

class ArStorageRepositoryImpl implements ArStorageRepository {
  ArStorageRepositoryImpl(this._remote);

  final SupabaseStorageDataSource _remote;

  @override
  Future<String> upload({
    required Uint8List bytes,
    required String objectPath,
    required String contentType,
  }) =>
      _remote.upload(
        bytes: bytes,
        objectPath: objectPath,
        contentType: contentType,
      );
}