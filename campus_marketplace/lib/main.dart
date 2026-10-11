import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/cart_model.dart';
import 'repositories/item_repository_api.dart';
import 'repositories/item_repository_firestore.dart';
import 'database/app_database.dart';
import 'repositories/favorites_repository_drift.dart';
import 'repositories/listing_draft_repository_drift.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

Future<void> main() async {
  // ต้องเริ่มต้น Firebase ให้เสร็จก่อน runApp() เสมอ
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // สร้าง AppDatabase ครั้งเดียว แล้วส่งต่อผ่าน Constructor (Dependency Injection)
  final db = AppDatabase();

  runApp(
    // สร้าง CartModel ให้ทุก Widget ใต้ MyApp เข้าถึงได้ (รายการโปรดย้ายไปเก็บใน Drift แล้ว)
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartModel()),
      ],
      child: MyApp(db: db),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AppDatabase db;
  const MyApp({super.key, required this.db});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Campus Marketplace',
      debugShowCheckedModeBanner: false, // ปิดริบบิ้น DEBUG มุมขวาบน ไม่ให้บังไอคอนหัวใจใน AppBar
      home: AuthGate(
        itemRepositories: [ItemRepositoryApi(), ItemRepositoryFirestore()],
        favoritesRepository: FavoritesRepositoryDrift(db),
        draftRepository: ListingDraftRepositoryDrift(db),
      ),
    );
  }
}
