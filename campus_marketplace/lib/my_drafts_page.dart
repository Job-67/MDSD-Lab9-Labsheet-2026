import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'database/app_database.dart';
import 'models/item.dart';
import 'repositories/item_repository_firestore.dart';
import 'repositories/listing_draft_repository.dart';
import 'services/storage_service.dart';

class MyDraftsPage extends StatefulWidget {
  final ListingDraftRepository repository;

  const MyDraftsPage({super.key, required this.repository});

  @override
  State<MyDraftsPage> createState() => _MyDraftsPageState();
}

class _MyDraftsPageState extends State<MyDraftsPage> {
  late Future<List<ListingDraftRow>> _draftsFuture;
  // id ของร่างที่กำลังอัปโหลด/โพสต์อยู่ ใช้แสดง Progress และกันกดซ้ำ
  int? _postingDraftId;

  @override
  void initState() {
    super.initState();
    _draftsFuture = widget.repository.getAllDrafts();
  }

  void _reload() {
    setState(() {
      _draftsFuture = widget.repository.getAllDrafts();
    });
  }

  Future<void> _delete(ListingDraftRow draft) async {
    await widget.repository.deleteDraft(draft.id);
    if (!mounted) return;
    _reload();
  }

  // ร่างไม่มีราคาเก็บไว้ จึงต้องถามจากผู้ใช้ก่อนโพสต์เสมอ คืน null เมื่อกดยกเลิก
  Future<double?> _askPrice() {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ตั้งราคาสินค้า'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'ราคา (บาท)',
              prefixText: '฿ ',
            ),
            validator: (value) {
              final price = double.tryParse((value ?? '').trim());
              if (price == null) return 'กรุณากรอกราคาเป็นตัวเลข';
              if (price <= 0) return 'ราคาต้องมากกว่า 0';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, double.parse(controller.text.trim()));
              }
            },
            child: const Text('โพสต์ขาย'),
          ),
        ],
      ),
    );
  }

  Future<void> _postForReal(ListingDraftRow draft) async {
    final messenger = ScaffoldMessenger.of(context);
    final price = await _askPrice();
    if (price == null || !mounted) return;

    setState(() => _postingDraftId = draft.id);
    try {
      final sellerId = FirebaseAuth.instance.currentUser!.uid;

      // ต้องอัปโหลดรูปให้ได้ Download URL ก่อน แล้วค่อยเขียนเอกสารลง Firestore พร้อม URL นั้น
      // ⚠️ ชั่วคราว: โปรเจกต์ยังเปิด Storage ไม่ได้ (ต้องใช้แผน Blaze) จึงยอมโพสต์แบบไม่มีรูปไปก่อน
      // เมื่อเปิด Storage แล้วโค้ดนี้จะอัปโหลดรูปตามปกติเองโดยไม่ต้องแก้อะไร
      String imageUrl = '';
      var hasImage = true;
      try {
        imageUrl = await StorageService().uploadListingImage(
          File(draft.imagePath),
          sellerId,
        );
      } on StorageUnavailableException {
        hasImage = false;
      }

      final item = Item(
        id: DateTime.now().millisecondsSinceEpoch,
        title: draft.title,
        price: price,
        description: draft.description,
        category: draft.category,
        imageUrl: imageUrl,
        sellerId: sellerId,
      );
      await ItemRepositoryFirestore().postItem(item);

      // ลบร่างออกจาก Local Database กันกดโพสต์ซ้ำร่างเดิม
      await widget.repository.deleteDraft(draft.id);
      if (!mounted) return;
      _reload();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            hasImage
                ? 'โพสต์ขาย "${draft.title}" เรียบร้อยแล้ว'
                : 'โพสต์ขาย "${draft.title}" แล้ว (ไม่มีรูป เพราะยังไม่ได้เปิด Storage)',
          ),
        ),
      );
    } catch (e) {
      final message = e is Exception
          ? e.toString().replaceFirst('Exception: ', '')
          : 'โพสต์ขายไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _postingDraftId = null);
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ร่างประกาศของฉัน')),
      body: FutureBuilder<List<ListingDraftRow>>(
        future: _draftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }

          final drafts = snapshot.data ?? [];
          if (drafts.isEmpty) {
            return const Center(child: Text('ยังไม่มีร่างประกาศ'));
          }

          return ListView.builder(
            itemCount: drafts.length,
            itemBuilder: (context, index) {
              final draft = drafts[index];
              final imageFile = File(draft.imagePath);
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  // ไฟล์รูปอาจถูกระบบลบได้ ต้องไม่ให้หน้าพังเมื่อไม่พบไฟล์
                  child: imageFile.existsSync()
                      ? Image.file(imageFile, fit: BoxFit.cover)
                      : const Icon(Icons.image_not_supported),
                ),
                title: Text(draft.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${draft.category} • แก้ไขล่าสุด ${_formatDate(draft.updatedAt)}',
                ),
                trailing: _postingDraftId == draft.id
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.cloud_upload_outlined),
                            tooltip: 'โพสต์ขายจริง',
                            // ระหว่างมีร่างอื่นกำลังโพสต์อยู่ ปิดปุ่มไว้ก่อน
                            onPressed: _postingDraftId != null
                                ? null
                                : () => _postForReal(draft),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: _postingDraftId != null
                                ? null
                                : () => _delete(draft),
                          ),
                        ],
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
