import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/image_upload_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../home/data/home_repository.dart';

/// Firebase "telefon + parol" bilan ishlamaydi (faqat email+parol yoki
/// telefon+SMS kod). Shuning uchun telefon raqamni ichki tarzda
/// soxta email'ga aylantirib, Firebase'ning email+parol tizimidan
/// foydalanamiz. Foydalanuvchi buni sezmaydi.
String _phoneToPseudoEmail(String rawPhone) {
  final digitsOnly = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
  return '$digitsOnly@mahallam.uz';
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Telefon raqam va parol bilan kirish.
  Future<void> signIn({
    required String phone,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Telegram orqali TASDIQLANGAN telefon raqam bilan yangi akkaunt
  /// yaratadi. Telefon tasdig'i endi Firebase orqali emas,
  /// PhoneVerificationRepository (Telegram bot + Supabase Edge
  /// Function) orqali amalga oshiriladi — bu yerga chaqirilganda
  /// tasdiqlash allaqachon bajarilgan bo'ladi, shuning uchun
  /// to'g'ridan-to'g'ri email+parol bilan akkaunt yaratiladi.
  Future<void> registerWithVerifiedPhone({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _phoneToPseudoEmail(phone),
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw AuthException("Foydalanuvchi yaratishda xatolik yuz berdi");
      }

      await _firestore.collection('users').doc(uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'phoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'mahallaId': null, // QR skanerlashdan keyin to'ldiriladi
      });
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await PushNotificationService.instance.clearToken(uid);
    }
    await _auth.signOut();
  }

  /// Amaldagi parolni tasdiqlab, sessiyani "yangilaydi" — Firebase
  /// parol/email (bizda — pseudo-email orqali telefon) kabi nozik
  /// amallardan oldin buni talab qiladi (`requires-recent-login`).
  Future<void> reauthenticate(String currentPassword) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: currentPassword),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Joriy foydalanuvchining parolini yangilaydi. Chaqirishdan oldin
  /// [reauthenticate] orqali sessiya yangilangan bo'lishi kerak,
  /// aks holda Firebase `requires-recent-login` xatosini beradi.
  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    try {
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  /// Telegram orqali tasdiqlangan yangi telefon raqamga o'tkazadi.
  /// Chaqirishdan oldin [reauthenticate] bilan sessiya yangilangan
  /// va [newPhone] `TelegramVerifyScreen` orqali tasdiqlangan bo'lishi
  /// shart (bu funksiya o'zi tasdiqlamaydi).
  ///
  /// `verifyBeforeUpdateEmail` emas, `updateEmail` ishlatiladi —
  /// chunki bizdagi "email" haqiqiy emas (`_phoneToPseudoEmail`),
  /// hech kim unga yuborilgan tasdiqlash havolasini bosolmaydi.
  Future<void> changePhoneNumber(String newPhone) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    try {
      // ignore: deprecated_member_use
      await user.updateEmail(_phoneToPseudoEmail(newPhone));
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
    await _firestore.collection('users').doc(user.uid).update({
      'phone': newPhone,
    });
  }

  /// Joriy foydalanuvchining profil ma'lumotlarini Firestore'da yangilaydi.
  /// Har bir maydon ixtiyoriy — faqat berilganlari yozib qo'yiladi.
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? street,
    String? houseNumber,
    DateTime? birthDate,
    UserGender? gender,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      if (street != null) 'street': street,
      if (houseNumber != null) 'houseNumber': houseNumber,
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate),
      if (gender != null) 'gender': gender.storageValue,
    });
  }

  /// Profil rasmini Firebase Storage'ga yuklaydi va Firestore'dagi
  /// `photoUrl` maydonini yangilaydi. Yangilangan URL'ni qaytaradi.
  Future<String> updateProfilePhoto(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    // Fayl nomi HAR SAFAR yangi bo'ladi.
    //
    // Ilgari yo'l `users/<uid>/profile.jpg` — o'zgarmas edi. Bu ikkita
    // muammo tug'dirardi: (1) rasmni almashtirishda Supabase mavjud
    // fayl ustiga yozishdan bosh tortardi, (2) yozilgan taqdirda ham
    // URL o'zgarmagani uchun telefon va CDN eski rasmni keshdan
    // ko'rsatishda davom etardi — foydalanuvchi "o'zgarmadi" deb
    // o'ylardi.
    final extension = _imageExtension(imageFile.path);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final url = await ImageUploadService().uploadImage(
      file: imageFile,
      storagePath: 'users/$uid/profile_$stamp.$extension',
    );
    await _firestore.collection('users').doc(uid).update({
      'photoUrl': url,
    });
    return url;
  }

  /// Profil rasmi uchun fayl kengaytmasi.
  ///
  /// Noma'lum yoki kengaytmasiz yo'l uchun `jpg` qaytariladi —
  /// `image_picker` galereyadan olingan rasmni qayta kodlagach
  /// odatda JPEG beradi, shuning uchun bu xavfsiz zaxira.
  static String _imageExtension(String path) {
    const allowed = {'jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4'};
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    return allowed.contains(ext) ? ext : 'jpg';
  }

  /// Profil banner tanlovini Firestore'da saqlaydi.
  Future<void> updateProfileBanner(String bannerId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore.collection('users').doc(uid).update({
      'profileBannerId': bannerId,
    });
  }

  /// Premium `PremiumBadge` uslubi tanlovini Firestore'da saqlaydi
  /// (`premium_badge_styles.dart`dagi katalogdan bitta `id`).
  Future<void> updateProfileBadgeStyle(String badgeStyleId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw AuthException('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore.collection('users').doc(uid).update({
      'badgeStyleId': badgeStyleId,
    });
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'invalid-credential':
      case 'wrong-password':
        return "Telefon raqam yoki parol noto'g'ri";
      case 'email-already-in-use':
        return 'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan';
      case 'weak-password':
        return "Parol juda oddiy, kamida 6 ta belgi bo'lishi kerak";
      case 'invalid-email':
        return "Telefon raqam formati noto'g'ri";
      case 'network-request-failed':
        return "Internet aloqasini tekshiring";
      case 'requires-recent-login':
        return "Xavfsizlik uchun qaytadan kirish talab qilinadi";
      case 'email-already-exists':
        return 'Bu telefon raqam allaqachon ro\'yxatdan o\'tgan';
      default:
        return 'Xatolik yuz berdi: $code';
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});