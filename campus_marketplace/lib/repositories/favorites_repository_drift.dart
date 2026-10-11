import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'favorites_repository.dart';

class FavoritesRepositoryDrift implements FavoritesRepository {
  final AppDatabase _db;

  FavoritesRepositoryDrift(this._db);

  @override
  Future<void> addFavorite(
    int itemId,
    String title,
    double price,
    String imageUrl,
  ) async {
    // insertOrIgnore: itemId เป็น .unique() กดซ้ำแล้วต้องไม่ Error (แค่ไม่เกิดอะไรขึ้น)
    await _db.into(_db.favoriteItems).insert(
          FavoriteItemsCompanion.insert(
            itemId: itemId,
            title: title,
            price: price,
            imageUrl: imageUrl,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<FavoriteItem>> getAllFavorites() {
    // เรียงจากกดถูกใจล่าสุดก่อน (addedAt เก็บเป็นวินาที จึงใช้ id เป็นตัวตัดสินเมื่อกดในวินาทีเดียวกัน)
    return (_db.select(_db.favoriteItems)
          ..orderBy([
            (t) => OrderingTerm(expression: t.addedAt, mode: OrderingMode.desc),
            (t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc),
          ]))
        .get();
  }

  @override
  Future<bool> isFavorite(int itemId) async {
    final row = await (_db.select(_db.favoriteItems)
          ..where((t) => t.itemId.equals(itemId)))
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> removeFavorite(int itemId) async {
    await (_db.delete(_db.favoriteItems)..where((t) => t.itemId.equals(itemId)))
        .go();
  }
}
