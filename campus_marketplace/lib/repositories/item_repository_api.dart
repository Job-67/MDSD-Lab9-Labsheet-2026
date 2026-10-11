import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/item.dart';
import 'item_repository.dart';

class ItemRepositoryApi implements ItemRepository {
  static const _baseUrl = 'https://fakestoreapi.com/products';
  static const _timeout = Duration(seconds: 10);

  @override
  Future<List<Item>> getItems() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl)).timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'เซิร์ฟเวอร์ขัดข้อง (รหัส ${response.statusCode}) กรุณาลองใหม่ภายหลัง',
        );
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList();
    } on TimeoutException {
      throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจากเซิร์ฟเวอร์ไม่อยู่ในรูปแบบที่ถูกต้อง');
    }
  }
}
