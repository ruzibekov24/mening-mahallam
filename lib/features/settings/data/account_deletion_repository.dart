import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

/// Hisobni o'chirish so'rovlari.
///
/// Ilgari Sozlamalardagi qizil "O'chirish" tugmasi tasdiqlash oynasini
/// ko'rsatar, keyin esa "tez orada" degan xabar chiqarardi — hech
/// narsa sodir bo'lmasdi. Ayni paytda Maxfiylik siyosati foydalanuvchiga
/// ma'lumotlari o'chirilishini va'da qiladi. Bu to'g'ridan-to'g'ri
/// yolg'on edi.
///
/// Endi tugma haqiqiy so'rov yaratadi: Firestore'ga yozuv tushadi va
/// super adminga bildirishnoma boradi (premium to'lovlari bilan bir xil
/// naqsh). O'chirish qo'lda bajariladi — bu qaytarib bo'lmaydigan
/// amal bo'lgani uchun ataylab avtomatlashtirilmagan.
class AccountDeletionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AccountDeletionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('deletionRequests');

  /// Foydalanuvchining kutilayotgan so'rovi bormi?
  ///
  /// Bor bo'lsa, takroriy so'rov yaratilmaydi — aks holda bitta
  /// foydalanuvchi tugmani bir necha marta bosib, adminga o'nlab bir
  /// xil bildirishnoma yuborishi mumkin edi.
  Future<bool> hasPendingRequest() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    // Faqat hujjat identifikatori bo'yicha o'qish — indeks talab
    // qilinmaydi (har bir foydalanuvchida bittadan ortiq so'rov
    // bo'lishi mumkin emas).
    final doc = await _col.doc(uid).get();
    return doc.exists && doc.data()?['status'] == 'kutilmoqda';
  }

  /// O'chirish so'rovini yaratadi va super adminlarga xabar beradi.
  Future<void> submitRequest({String? reason}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Hisobni o\'chirish uchun tizimga kirgan bo\'lish kerak');
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data() ?? const <String, dynamic>{};
    final fullName = [
      data['firstName'] as String? ?? '',
      data['lastName'] as String? ?? '',
    ].where((p) => p.isNotEmpty).join(' ');

    // Hujjat identifikatori = uid. Shu tufayli takroriy so'rov
    // yangi hujjat yaratmaydi, balki mavjudini yangilaydi.
    await _col.doc(user.uid).set({
      'uid': user.uid,
      'fullName': fullName,
      'email': user.email,
      'phone': data['phone'],
      'mahallaId': data['mahallaId'],
      'reason': reason,
      'status': 'kutilmoqda',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final admins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'superAdmin')
        .get();
    final notifications = NotificationRepository();
    for (final admin in admins.docs) {
      await notifications.sendToUser(
        uid: admin.id,
        type: NotificationType.accountDeletionRequested,
        title: 'Hisobni o\'chirish so\'rovi',
        body: fullName.isEmpty
            ? 'Foydalanuvchi hisobini o\'chirishni so\'radi'
            : '$fullName hisobini o\'chirishni so\'radi',
        relatedId: user.uid,
      );
    }
  }
}
