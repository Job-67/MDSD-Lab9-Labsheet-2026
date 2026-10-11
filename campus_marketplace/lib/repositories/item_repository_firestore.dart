import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryFirestore implements ItemRepository {
  static const _timeout = Duration(seconds: 15);

  final CollectionReference<Map<String, dynamic>> _items =
      FirebaseFirestore.instance.collection('items');

  // อ่านทุกเอกสารครั้งเดียว ให้ HomePage เรียกใช้ได้เหมือน ItemRepositoryApi ทุกประการ
  @override
  Future<List<Item>> getItems() async {
    try {
      final snapshot = await _items.get().timeout(_timeout);
      return snapshot.docs.map(Item.fromFirestore).toList();
    } on TimeoutException {
      throw Exception('โหลดประกาศจาก Firestore ไม่ทันเวลา กรุณาลองใหม่อีกครั้ง');
    } on FirebaseException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  Future<void> postItem(Item item) async {
    try {
      await _items.add(item.toFirestore()).timeout(_timeout);
    } on TimeoutException {
      throw Exception('บันทึกประกาศไม่ทันเวลา กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
    } on FirebaseException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // ฟังแบบ Real-time เฉพาะประกาศของผู้ขายคนนี้ (ต่างจาก getItems ที่อ่านครั้งเดียว)
  Stream<List<Item>> watchMyListings(String sellerId) {
    return _items
        .where('sellerId', isEqualTo: sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Item.fromFirestore).toList());
  }

  String _translateErrorCode(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ไม่มีสิทธิ์เข้าถึงข้อมูลประกาศ (permission-denied)';
      case 'unavailable':
        return 'เชื่อมต่อ Firestore ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาดกับ Firestore ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}
