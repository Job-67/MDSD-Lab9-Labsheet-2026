import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleReady = false;

  // สมัครสมาชิกใหม่ด้วย Email/Password
  Future<void> signUp({required String email, required String password}) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // เข้าสู่ระบบด้วย Email/Password
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  Future<void> _ensureGoogleReady() async {
    if (_googleReady) return;
    // initialize() ต้องเรียกครั้งเดียวก่อนใช้งานเมธอดอื่นของ GoogleSignIn เสมอ
    await _googleSignIn.initialize();
    _googleReady = true;
  }

  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleReady();

      // authenticate() เปิดหน้าต่างให้ผู้ใช้เลือกบัญชี Google (แทนที่ signIn() ในเวอร์ชันเก่า)
      final googleUser = await _googleSignIn.authenticate();

      // idToken ได้แบบ synchronous จาก authentication ของบัญชีที่ล็อกอินแล้ว
      final idToken = googleUser.authentication.idToken;

      // accessToken ต้องขอเพิ่มผ่าน authorizationClient แยกต่างหาก
      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(['email']);

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
      );

      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_translateErrorCode(e.code));
    }
  }

  // แปล code ของ FirebaseAuthException เป็นข้อความภาษาไทย ไม่ให้ Error ดิบหลุดไปถึงผู้ใช้
  String _translateErrorCode(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'อีเมลนี้ถูกใช้สมัครสมาชิกไปแล้ว กรุณาเข้าสู่ระบบหรือใช้อีเมลอื่น';
      case 'weak-password':
        return 'รหัสผ่านสั้นเกินไป กรุณาตั้งรหัสผ่านอย่างน้อย 6 ตัวอักษร';
      case 'invalid-email':
        return 'รูปแบบอีเมลไม่ถูกต้อง';
      case 'invalid-credential':
        return 'อีเมลหรือรหัสผ่านไม่ถูกต้อง หรือข้อมูลยืนยันตัวตนหมดอายุ กรุณาลองเข้าสู่ระบบใหม่';
      case 'user-not-found':
        return 'ไม่พบบัญชีผู้ใช้นี้ กรุณาสมัครสมาชิกก่อน';
      case 'wrong-password':
        return 'รหัสผ่านไม่ถูกต้อง';
      case 'user-disabled':
        return 'บัญชีนี้ถูกระงับการใช้งาน';
      case 'too-many-requests':
        return 'ลองผิดหลายครั้งเกินไป กรุณารอสักครู่แล้วลองใหม่';
      case 'operation-not-allowed':
        return 'วิธีเข้าสู่ระบบนี้ยังไม่ได้เปิดใช้งานใน Firebase Console';
      case 'network-request-failed':
        return 'เชื่อมต่อเครือข่ายไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';
      default:
        return 'เกิดข้อผิดพลาด ($code) กรุณาลองใหม่อีกครั้ง';
    }
  }
}
