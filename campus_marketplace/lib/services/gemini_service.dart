import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.1-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  // ตั้งไว้ 20 วินาที (นานกว่า OpenWeather ที่ 10 วินาที) เพราะ Gemini ต้องใช้เวลาประมวลผล (inference)
  // ของโมเดลภาษาขนาดใหญ่ ไม่ใช่แค่ค้นข้อมูลจากฐานข้อมูลเหมือน REST API ทั่วไป
  static const _timeout = Duration(seconds: 20);

  Future<String> generateText(String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'เรียก Gemini API ไม่สำเร็จ (รหัส ${response.statusCode}) กรุณาลองใหม่ภายหลัง',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;

      if (candidates == null || candidates.isEmpty) {
        throw Exception(
          'Gemini ไม่ได้ส่งคำตอบกลับมา (อาจถูกบล็อกด้วยระบบความปลอดภัยของ Gemini)',
        );
      }

      final content = candidates.first['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      return parts.first['text'] as String;
    } on TimeoutException {
      throw Exception('การเชื่อมต่อกับ Gemini หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจาก Gemini ไม่อยู่ในรูปแบบที่ถูกต้อง');
    }
  }
}
