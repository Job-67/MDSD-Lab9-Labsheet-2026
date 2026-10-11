import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/cart_model.dart';
import '../repositories/favorites_repository.dart';

class ItemCard extends StatefulWidget {
  final Item item;
  final FavoritesRepository favoritesRepository;

  const ItemCard({
    super.key,
    required this.item,
    required this.favoritesRepository,
  });

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
  }

  // อ่านสถานะจากฐานข้อมูลจริง เพื่อให้หัวใจทึบหลังปิดเปิดแอปด้วย
  Future<void> _loadFavoriteStatus() async {
    final saved = await widget.favoritesRepository.isFavorite(widget.item.id);
    if (!mounted) return;
    setState(() => _isFavorite = saved);
  }

  Future<void> _addFavorite() async {
    final item = widget.item;
    final messenger = ScaffoldMessenger.of(context);
    final wasFavorite = _isFavorite;
    try {
      await widget.favoritesRepository.addFavorite(
        item.id,
        item.title,
        item.price,
        item.imageUrl,
      );
      if (!mounted) return;
      setState(() => _isFavorite = true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? '${item.title} อยู่ในรายการโปรดแล้ว'
                : 'บันทึก ${item.title} ไว้ในรายการโปรดแล้ว',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('บันทึกรายการโปรดไม่สำเร็จ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.imageUrl.isEmpty
                      ? const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(Icons.image_not_supported),
                        )
                      : Image.network(
                          item.imageUrl,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          // รูปโหลดไม่ได้ (ลิงก์เสีย/ออฟไลน์) ต้องไม่ทำให้การ์ดพัง
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(Icons.image_not_supported),
                              ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('฿${item.price.toStringAsFixed(0)}'),
                      const SizedBox(height: 4),
                      // สินค้าที่มี sellerId คือประกาศจริงจาก Firestore ที่เหลือมาจาก API
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          item.sellerId != null
                              ? '🎓 โพสต์โดยนักศึกษา'
                              : '🏪 จาก API',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addFavorite,
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
                    label: Text(_isFavorite ? 'ถูกใจแล้ว' : 'ถูกใจ'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      context.read<CartModel>().add(item);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เพิ่ม ${item.title} ลงตะกร้าแล้ว')),
                      );
                    },
                    child: const Text('🛒 เพิ่มลงตะกร้า'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
