import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Foydalanuvchi ilova haqida qoldirgan fikr — 1-5 yulduz baho +
/// ixtiyoriy matn. Mahallaga bog'lanmagan (butun ilova haqida),
/// faqat super admin ko'radi.
class AppFeedback {
  final String id;
  final String authorUid;
  final String authorName;
  final int rating;
  final String message;
  final DateTime createdAt;

  /// Fikr yuborilgan paytda muallif premium obunachi bo'lganmi.
  ///
  /// Yuborish paytida yozib qo'yiladi (keyin o'zgarmaydi) — shunda
  /// obuna tugagach eski fikrlar ro'yxatda o'rnini o'zgartirmaydi.
  final bool authorWasPremium;

  /// `true` — bu yozuv "Baho qoldirish" emas, balki "Savol/Murojaat"
  /// rejimida yuborilgan (yulduzcha bahosiz, superadminga to'g'ridan-
  /// to'g'ri savol/murojaat sifatida). Admin ro'yxatida buni alohida
  /// belgi bilan ajratib ko'rsatish uchun ishlatiladi.
  final bool isQuestion;

  AppFeedback({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.rating,
    required this.message,
    required this.createdAt,
    this.authorWasPremium = false,
    this.isQuestion = false,
  });

  factory AppFeedback.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return AppFeedback(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      rating: (data['rating'] ?? 0) as int,
      message: data['message'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      authorWasPremium: data['authorWasPremium'] == true,
      isQuestion: data['isQuestion'] == true,
    );
  }
}

class FeedbackRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedbackRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<void> submitFeedback({
    required int rating,
    required String message,
    required String authorName,
    bool isPremium = false,
    bool isQuestion = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore.collection('appFeedback').add({
      'authorUid': uid,
      'authorName': authorName,
      'rating': rating,
      'message': message,
      'authorWasPremium': isPremium,
      'isQuestion': isQuestion,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Faqat super admin chaqirishi kerak — Firestore Rules ham shuni
  /// mustahkamlaydi.
  Stream<List<AppFeedback>> watchAllFeedback() {
    return _firestore
        .collection('appFeedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => AppFeedback.fromFirestore(doc.id, doc.data()))
          .toList();
      // Ustuvor qo'llab-quvvatlash (`premiumBenefitSupport`): premium
      // obunachilarning fikrlari ro'yxat boshida turadi, ular ichida
      // esa yangi kelgani birinchi. Saralash MIJOZ tomonida — shu
      // tufayli qo'shimcha Firestore indeksi kerak bo'lmaydi va
      // sahifalash mantig'i o'zgarmaydi.
      items.sort((a, b) {
        if (a.authorWasPremium != b.authorWasPremium) {
          return a.authorWasPremium ? -1 : 1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return items;
    });
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepository();
});

final allFeedbackProvider = StreamProvider.autoDispose<List<AppFeedback>>((ref) {
  return ref.watch(feedbackRepositoryProvider).watchAllFeedback();
});
