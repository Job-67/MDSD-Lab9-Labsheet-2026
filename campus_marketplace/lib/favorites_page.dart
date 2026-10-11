import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'repositories/favorites_repository.dart';

class FavoritesPage extends StatefulWidget {
  final FavoritesRepository repository;

  const FavoritesPage({super.key, required this.repository});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<FavoriteItem>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = widget.repository.getAllFavorites();
  }

  void _reload() {
    setState(() {
      _favoritesFuture = widget.repository.getAllFavorites();
    });
  }

  Future<void> _remove(FavoriteItem item) async {
    await widget.repository.removeFavorite(item.itemId);
    if (!mounted) return;
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายการโปรดของฉัน')),
      body: FutureBuilder<List<FavoriteItem>>(
        future: _favoritesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final favorites = snapshot.data ?? [];
          if (favorites.isEmpty) {
            return const Center(
              child: Text('ยังไม่มีรายการโปรด ลองกดหัวใจที่หน้าหลักดูสิ'),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return ListTile(
                leading: Image.network(
                  item.imageUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                  // ออฟไลน์แล้วโหลดรูปไม่ได้ ต้องไม่ให้หน้าพัง
                  errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported),
                ),
                title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('฿${item.price.toStringAsFixed(0)}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _remove(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
