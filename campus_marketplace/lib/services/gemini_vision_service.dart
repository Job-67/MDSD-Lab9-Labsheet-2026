import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/listing_draft.dart';

class GeminiVisionService {
  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-3.1-flash-lite';
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';
  static const _timeout = Duration(seconds: 20);

  Future<ListingDraft> analyzeProductImage(File imageFile, String prompt) async {
    final uri = Uri.parse('$_baseUrl?key=$_apiKey');

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                    {
                      'inlineData': {'mimeType': 'image/jpeg', 'data': base64Image},
                    },
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': {
                  'type': 'OBJECT',
                  'properties': {
                    'title': {'type': 'STRING'},
                    'category': {'type': 'STRING'},
                    'description': {'type': 'STRING'},
                  },
                  'required': ['title', 'category', 'description'],
                },
              },
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'เรียก Gemini Vision API ไม่สำเร็จ (รหัส ${response.statusCode}) กรุณาลองใหม่ภายหลัง',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;

      if (candidates == null || candidates.isEmpty) {
        throw Exception(
          'AI ไม่สามารถวิเคราะห์ภาพนี้ได้ อาจเข้าข่ายเนื้อหาที่ไม่เหมาะสม ลองใช้ภาพอื่น',
        );
      }

      final firstCandidate = candidates.first as Map<String, dynamic>;
      final finishReason = firstCandidate['finishReason'] as String?;
      if (finishReason == 'SAFETY') {
        throw Exception(
          'เนื้อหาที่วิเคราะห์เข้าข่ายไม่ปลอดภัยตามนโยบายของ Gemini กรุณาใช้ภาพอื่น',
        );
      }

      final content = firstCandidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List<dynamic>;
      final rawText = parts.first['text'] as String;

      // jsonDecode ชั้นที่ 2: ข้อความที่ Gemini ตอบกลับมาเป็น JSON string อีกชั้นหนึ่ง (ร่างประกาศ)
      final draftJson = jsonDecode(rawText) as Map<String, dynamic>;
      return ListingDraft.fromJson(draftJson);
    } on TimeoutException {
      throw Exception('การเชื่อมต่อกับ Gemini หมดเวลา กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException {
      throw Exception('ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ');
    } on FormatException {
      throw Exception('ข้อมูลที่ได้รับจาก Gemini ไม่อยู่ในรูปแบบที่ถูกต้อง');
    }
  }
}
