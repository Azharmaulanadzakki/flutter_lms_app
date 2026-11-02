import '../../core/errors/failure_guard.dart';
import '../../domain/entities/ar_item.dart';
import '../../domain/repositories/ar_repository.dart';
import '../datasources/ar_remote_datasource.dart';

class ArRepositoryImpl implements ArRepository {
  ArRepositoryImpl(this._remote);

  final ArRemoteDataSource _remote;

  @override
  Future<List<ArItem>> getPublishedItems() =>
      guardFirebase<List<ArItem>>(_remote.getPublishedItems);

  @override
  Future<List<ArItem>> getAllItems() =>
      guardFirebase<List<ArItem>>(_remote.getAllItems);

  @override
  Future<ArItem> getItem(String id) =>
      guardFirebase<ArItem>(() => _remote.getItem(id));

  @override
  Future<String> saveItem(ArItem item) =>
      guardFirebase<String>(() => _remote.saveItem(item));

  @override
  Future<void> setPublished(String id, bool published) =>
      guardFirebase<void>(() => _remote.setPublished(id, published));

  @override
  Future<void> deleteItem(String id) =>
      guardFirebase<void>(() => _remote.deleteItem(id));
}
