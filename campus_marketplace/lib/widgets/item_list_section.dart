import 'package:flutter/material.dart';
import '../models/item.dart';
import '../repositories/favorites_repository.dart';
import 'item_card.dart';

class ItemListSection extends StatelessWidget {
  final List<Item> catalog;
  final FavoritesRepository favoritesRepository;
  final int favoritesVersion; // เปลี่ยนค่าเพื่อให้การ์ดอ่านสถานะถูกใจจากฐานข้อมูลใหม่

  const ItemListSection({
    super.key,
    required this.catalog,
    required this.favoritesRepository,
    this.favoritesVersion = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      // เว้นที่ด้านล่างไม่ให้ปุ่มลอย (FAB) บังการ์ดใบสุดท้าย
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: catalog.length,
      itemBuilder: (context, index) => ItemCard(
        key: ValueKey('${catalog[index].id}-$favoritesVersion'),
        item: catalog[index],
        favoritesRepository: favoritesRepository,
      ),
    );
  }
}
