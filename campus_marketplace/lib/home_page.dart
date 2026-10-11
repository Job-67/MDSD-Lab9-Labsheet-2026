import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/item.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository.dart';
import 'repositories/favorites_repository.dart';
import 'widgets/item_list_section.dart';
import 'cart_page.dart';
import 'services/gemini_service.dart';
import 'services/auth_service.dart';

class HomePage extends StatefulWidget {
  final List<ItemRepository> repositories;
  final FavoritesRepository favoritesRepository;
  final int favoritesVersion;

  const HomePage({
    super.key,
    required this.repositories,
    required this.favoritesRepository,
    this.favoritesVersion = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // กลับมาที่ Tab หน้าหลัก → โหลดใหม่ เพื่อให้เห็นประกาศที่เพิ่งโพสต์ขายจริง
    if (oldWidget.favoritesVersion != widget.favoritesVersion) {
      _retry();
    }
  }

  // เรียก getItems() จากทุก Repository พร้อมกัน แล้วรวมผลลัพธ์เป็น List เดียว
  // HomePage รู้จักแค่ Interface ItemRepository ไม่รู้ว่าเบื้องหลังเป็น API หรือ Firestore
  Future<List<Item>> _loadItems() async {
    final results = await Future.wait(
      widget.repositories.map((repository) => repository.getItems()),
    );
    return results.expand((items) => items).toList();
  }

  void _retry() {
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  // ปุ่มทดสอบชั่วคราวสำหรับ Checkpoint 2.1 เท่านั้น: ทดสอบว่า GeminiService เชื่อมต่อ API ได้ถูกต้อง
  Future<void> _testGemini() async {
    try {
      final result = await GeminiService().generateText(
        'ช่วยแต่งประโยคทักทายลูกค้าร้านค้าออนไลน์แบบเป็นกันเอง',
      );
      debugPrint('Gemini response: $result');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
    } catch (e) {
      debugPrint('Gemini error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Marketplace'),
        actions: [
          IconButton(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart),
                // .watch ทำให้ตัวเลขนี้อัปเดตเองทุกครั้งที่ CartModel เปลี่ยน ไม่ว่าจะเปลี่ยนจากจุดไหน
                Text(' ${context.watch<CartModel>().itemCount}'),
              ],
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
          // ไม่ต้อง Navigate เอง — AuthGate จะสลับกลับไปหน้า Login ให้เมื่อสถานะล็อกอินเปลี่ยน
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final message = snapshot.error is Exception
                ? snapshot.error.toString().replaceFirst('Exception: ', '')
                : 'เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final catalog = snapshot.data ?? [];
          return ItemListSection(
            catalog: catalog,
            favoritesRepository: widget.favoritesRepository,
            favoritesVersion: widget.favoritesVersion,
          );
        },
      ),
      // ปุ่มทดสอบชั่วคราวสำหรับ Checkpoint 2.1 เท่านั้น
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _testGemini,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('ทดสอบ Gemini'),
      ),
    );
  }
}
