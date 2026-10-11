import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

// โยนเมื่อโปรเจกต์ยังไม่ได้เปิดใช้ Firebase Storage (ต้องใช้แผน Blaze) แยกจาก Error เครือข่ายทั่วไป
class StorageUnavailableException implements Exception {
  @override
  String toString() => 'ยังไม่ได้เปิดใช้งาน Firebase Storage ในโปรเจกต์นี้';
}

class StorageService {
  static const _timeout = Duration(seconds: 30);

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // อัปโหลดรูปประกาศขึ้น Storage แล้วคืน Download URL
  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    // ตั้งชื่อใหม่ไม่ให้ซ้ำกัน ไม่ใช้ชื่อไฟล์เดิมจากเครื่องผู้ใช้
    final fileName = '${sellerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('listings/$fileName');
    final task = ref.putFile(imageFile);

    try {
      // ต้องรอให้ putFile() เสร็จสมบูรณ์ก่อน จึงค่อยขอ Download URL
      await task.timeout(_timeout);
      return await ref.getDownloadURL().timeout(_timeout);
    } on TimeoutException {
      await task.cancel();
      throw Exception('อัปโหลดรูปไม่ทันเวลา กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่');
    } on FirebaseException catch (e) {
      if (_unavailableCodes.contains(e.code)) {
        throw StorageUnavailableException();
      }
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // code ที่ได้เมื่อไม่มี Bucket ให้เขียน (เซิร์ฟเวอร์ตอบกลับมาแล้ว ไม่ใช่ปัญหาเครือข่าย)
  static const _unavailableCodes = {
    'object-not-found',
    'bucket-not-found',
    'project-not-found',
    'unknown',
  };

  String _translateErrorCode(String code) {
    switch (code) {
      case 'unauthorized':
        return 'ไม่มีสิทธิ์อัปโหลดรูปขึ้น Storage (unauthorized)';
      case 'retry-limit-exceeded':
        return 'อัปโหลดรูปไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';
      case 'canceled':
        return 'การอัปโหลดรูปถูกยกเลิก';
      default:
        return 'เกิดข้อผิดพลาดกับ Storage ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}
