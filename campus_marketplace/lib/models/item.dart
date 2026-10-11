import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  // nullable เพราะสินค้าจาก Fake Store API ไม่มี sellerId
  final String? sellerId;
  // id ของเอกสารใน Firestore (เป็น String) มีค่าเฉพาะสินค้าที่โพสต์ผ่านแอป
  final String? docId;

  const Item({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    this.sellerId,
    this.docId,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      category: json['category'] as String,
      imageUrl: json['image'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      // เก็บ id แบบตัวเลขไว้ด้วย เพราะรายการโปรด/ตะกร้าเดิมอ้างอิงสินค้าด้วย int
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'sellerId': sellerId,
    };
  }

  factory Item.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Item(
      id: (data['id'] as num?)?.toInt() ?? doc.id.hashCode,
      title: data['title'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sellerId: data['sellerId'] as String?,
      docId: doc.id,
    );
  }
}
