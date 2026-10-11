import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/gemini_vision_service.dart';
import 'models/listing_draft.dart';
import 'my_drafts_page.dart';
import 'repositories/listing_draft_repository.dart';

class SellItemPage extends StatefulWidget {
  final ListingDraftRepository draftRepository;
  const SellItemPage({super.key, required this.draftRepository});

  @override
  State<SellItemPage> createState() => _SellItemPageState();
}

class _SellItemPageState extends State<SellItemPage> {
  static const _prompt = '''
คุณคือผู้ช่วยเขียนประกาศขายของมือสองในตลาดนัดออนไลน์สำหรับนักศึกษามหาวิทยาลัย
จากรูปภาพสินค้าที่แนบมา ให้วิเคราะห์แล้วตอบกลับเป็น JSON เท่านั้น ตามโครงสร้างนี้:
{
  "title": "ชื่อประกาศสั้นกระชับ ไม่เกิน 40 ตัวอักษร",
  "category": "หมวดหมู่ที่เหมาะสมที่สุด เลือกจาก: หนังสือเรียน, อุปกรณ์อิเล็กทรอนิกส์, ของแต่งหอพัก, เสื้อผ้า, อื่นๆ",
  "description": "คำบรรยายสินค้า 2-3 ประโยค ที่ดึงดูดผู้ซื้อและบอกสภาพของสินค้าตามที่เห็นในภาพ"
}
ห้ามตอบข้อความอื่นนอกเหนือจาก JSON ดังกล่าว
''';

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  String? _errorMessage;

  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (result == null) return;

    setState(() {
      _selectedImage = File(result.path);
    });
  }

  Future<void> _askAiForSuggestion() async {
    if (_selectedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final draft = await GeminiVisionService().analyzeProductImage(
        _selectedImage!,
        _prompt,
      );
      setState(() {
        _titleController.text = draft.title;
        _categoryController.text = draft.category;
        _descriptionController.text = draft.description;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isAnalyzing = false;
      });
    }
  }

  Future<void> _confirmDraft() async {
    final image = _selectedImage;
    if (image == null) {
      setState(() => _errorMessage = 'กรุณาเลือกรูปภาพสินค้าก่อนบันทึกร่าง');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final draft = ListingDraft(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      await widget.draftRepository.saveDraft(draft, image.path);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกร่างประกาศเรียบร้อยแล้ว')),
      );
      setState(() {
        _selectedImage = null;
        _titleController.clear();
        _categoryController.clear();
        _descriptionController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'บันทึกร่างไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDraft = _titleController.text.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศขายสินค้า'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'ร่างประกาศของฉัน',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MyDraftsPage(repository: widget.draftRepository),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, height: 240, fit: BoxFit.cover)
            else
              Container(
                height: 240,
                width: double.infinity,
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 64, color: Colors.grey),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('เลือกรูปภาพสินค้า'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _selectedImage == null || _isAnalyzing
                  ? null
                  : _askAiForSuggestion,
              child: const Text('ให้ AI ช่วยแนะนำ'),
            ),
            if (_isAnalyzing) ...[
              const SizedBox(height: 16),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('AI กำลังวิเคราะห์ภาพสินค้า...'),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ชื่อประกาศ'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'หมวดหมู่'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'คำบรรยายสินค้า'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: hasDraft && !_isSaving ? _confirmDraft : null,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('ยืนยันร่างประกาศ'),
            ),
          ],
        ),
      ),
    );
  }
}
