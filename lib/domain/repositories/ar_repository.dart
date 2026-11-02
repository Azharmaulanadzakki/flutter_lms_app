import '../entities/ar_item.dart';

abstract class ArRepository {
  /// Model AR yang dipublikasikan, terurut berdasarkan `order`.
  Future<List<ArItem>> getPublishedItems();

  /// Semua model AR (khusus admin).
  Future<List<ArItem>> getAllItems();

  Future<ArItem> getItem(String id);

  /// Mengembalikan ID. Jika `item.id` kosong, dokumen baru dibuat.
  Future<String> saveItem(ArItem item);

  Future<void> setPublished(String id, bool published);
  Future<void> deleteItem(String id);
}
