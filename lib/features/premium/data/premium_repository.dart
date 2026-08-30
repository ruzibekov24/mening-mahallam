import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/data/notification_repository.dart';

/// Bepul foydalanuvchi kunlik murojaat limitiga yetganda tashlanadi.
class DailyRequestLimitReachedException implements Exception {
  final int limit;
  const DailyRequestLimitReachedException(this.limit);

  @override
  String toString() => 'DailyRequestLimitReachedException(limit: $limit)';
}

/// To'lov so'rovining holati.
///
/// Oqim: `kutilmoqda` (foydalanuvchi so'rov yaratdi, hali to'lamagan)
///   -> `tolandi` (foydalanuvchi "To'ladim" tugmasini bosdi, admin
///      tasdiqlashini kutmoqda)
///   -> `tasdiqlandi` yoki `rad_etildi`.
/// Agar belgilangan vaqt ichida "To'ladim" bosilmasa — `muddati_tugadi`.
enum PremiumRequestStatus { kutilmoqda, tolandi, tasdiqlandi, radEtildi, muddatiTugadi }

extension PremiumRequestStatusX on PremiumRequestStatus {
  String get storageValue {
    switch (this) {
      case PremiumRequestStatus.kutilmoqda:
        return 'kutilmoqda';
      case PremiumRequestStatus.tolandi:
        return 'tolandi';
      case PremiumRequestStatus.tasdiqlandi:
        return 'tasdiqlandi';
      case PremiumRequestStatus.radEtildi:
        return 'radEtildi';
      case PremiumRequestStatus.muddatiTugadi:
        return 'muddatiTugadi';
    }
  }

  static PremiumRequestStatus fromString(String? value) {
    switch (value) {
      case 'tolandi':
        return PremiumRequestStatus.tolandi;
      case 'tasdiqlandi':
        return PremiumRequestStatus.tasdiqlandi;
      case 'radEtildi':
        return PremiumRequestStatus.radEtildi;
      case 'muddatiTugadi':
        return PremiumRequestStatus.muddatiTugadi;
      default:
        return PremiumRequestStatus.kutilmoqda;
    }
  }
}

/// Bitta premium to'lov so'rovi.
class PremiumRequest {
  final String id;
  final String uid;
  final String fullName;
  final String phone;
  final int amount;
  final int months;
  final PremiumRequestStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  PremiumRequest({
    required this.id,
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.amount,
    required this.months,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Foydalanuvchi hali to'lash imkoniyatiga ega — vaqt tugamagan va
  /// hali "To'ladim" bosilmagan.
  bool get isAwaitingPayment =>
      status == PremiumRequestStatus.kutilmoqda &&
      expiresAt.isAfter(DateTime.now());

  /// Admin qaroriga qadar kutilayotgan holat.
  bool get isAwaitingApproval => status == PremiumRequestStatus.tolandi;

  /// So'rov endi hech qanday harakat talab qilmaydi.
  bool get isClosed =>
      status == PremiumRequestStatus.tasdiqlandi ||
      status == PremiumRequestStatus.radEtildi ||
      status == PremiumRequestStatus.muddatiTugadi ||
      (status == PremiumRequestStatus.kutilmoqda &&
          !expiresAt.isAfter(DateTime.now()));

  factory PremiumRequest.fromFirestore(String id, Map<String, dynamic> data) {
    final created = data['createdAt'] as Timestamp?;
    final expires = data['expiresAt'] as Timestamp?;
    return PremiumRequest(
      id: id,
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      months: (data['months'] as num?)?.toInt() ?? 1,
      status: PremiumRequestStatusX.fromString(data['status'] as String?),
      createdAt: created?.toDate() ?? DateTime.now(),
      expiresAt: expires?.toDate() ?? DateTime.now(),
    );
  }
}

/// Premium narxi va to'lov rekvizitlari.
///
/// Firestore'dagi `appConfig/premium` hujjatidan o'qiladi — shunda
/// karta raqami yoki narxni o'zgartirish uchun ilovani qayta yig'ish
/// SHART EMAS. Hujjat bo'lmasa quyidagi boshlang'ich qiymatlar
/// ishlatiladi.
class PremiumConfig {
  final String cardNumber;
  final String cardHolder;
  final int monthlyPrice;
  final String adminTelegram;

  const PremiumConfig({
    required this.cardNumber,
    required this.cardHolder,
    required this.monthlyPrice,
    required this.adminTelegram,
  });

  static const fallback = PremiumConfig(
    cardNumber: '4108590112580256',
    cardHolder: 'Ilyos Ruzibekov',
    monthlyPrice: 9900,
    adminTelegram: 'Ilyos_Ruzibekov',
  );

  factory PremiumConfig.fromFirestore(Map<String, dynamic> data) {
    return PremiumConfig(
      cardNumber: data['cardNumber'] as String? ?? fallback.cardNumber,
      cardHolder: data['cardHolder'] as String? ?? fallback.cardHolder,
      monthlyPrice:
          (data['monthlyPrice'] as num?)?.toInt() ?? fallback.monthlyPrice,
      adminTelegram:
          data['adminTelegram'] as String? ?? fallback.adminTelegram,
    );
  }

  /// "4108 5901 1258 0256" ko'rinishida — o'qishga qulay.
  String get formattedCard {
    final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
    final parts = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      parts.add(digits.substring(i, (i + 4).clamp(0, digits.length)));
    }
    return parts.join(' ');
  }
}

/// Obuna muddati varianti.
///
/// Narx har doim [PremiumConfig.monthlyPrice]dan hisoblanadi — ya'ni
/// super admin oylik narxni o'zgartirsa, uzoq muddatli tariflar ham
/// avtomatik qayta hisoblanadi va ularni alohida yangilash kerak
/// bo'lmaydi.
class PremiumPlan {
  final int months;

  /// Chegirma ulushi (0.0–1.0). Uzoqroq muddat — arzonroq oyiga.
  final double discount;

  const PremiumPlan({required this.months, required this.discount});

  /// Barcha mavjud tariflar.
  static const all = [
    PremiumPlan(months: 1, discount: 0.00),
    PremiumPlan(months: 3, discount: 0.10),
    PremiumPlan(months: 6, discount: 0.15),
    PremiumPlan(months: 12, discount: 0.25),
  ];

  /// Chegirmasiz to'liq narx — chegirmani ko'rsatish uchun.
  int fullPrice(int monthlyPrice) => monthlyPrice * months;

  /// Haqiqiy to'lanadigan summa, eng yaqin 100 so'mgacha yaxlitlangan
  /// (kartaga o'tkazishda "26 730" kabi son noqulay).
  int price(int monthlyPrice) {
    final raw = monthlyPrice * months * (1 - discount);
    return (raw / 100).round() * 100;
  }

  /// Oyiga tushadigan narx — taqqoslash uchun.
  int pricePerMonth(int monthlyPrice) =>
      (price(monthlyPrice) / months).round();

  /// Ko'rsatiladigan chegirma foizi (butun son).
  int get discountPercent => (discount * 100).round();
}

/// Premium holatini va to'lov so'rovlarini boshqaradi.
///
/// Haqiqiy avtomatik to'lov (Google Play Billing yoki Click/Payme)
/// hozircha ULANMAGAN. Oqim qo'lda: foydalanuvchi kartaga o'tkazadi,
/// "To'ladim" tugmasini bosadi, super adminga bildirishnoma boradi va
/// u tasdiqlaydi. Kelajakda avtomatik to'lov ulanganda faqat
/// [approveRequest] chaqiruvi avtomatlashtiriladi — qolgan butun tizim
/// (limitlar, bannerlar, nishon) o'zgarishsiz qolaveradi, chunki ular
/// faqat `users/{uid}.premiumUntil` maydonini o'qiydi.
class PremiumRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PremiumRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Bepul foydalanuvchi kuniga eng ko'pi bilan shuncha murojaat
  /// ochishi mumkin.
  static const int freeDailyRequestLimit = 3;

  /// Bepul / premium foydalanuvchi bitta murojaatga qo'sha oladigan
  /// rasm soni.
  static const int freeImageLimit = 5;
  static const int premiumImageLimit = 10;

  /// To'lov uchun beriladigan vaqt — shu muddat ichida "To'ladim"
  /// bosilmasa, so'rov o'z-o'zidan kuchini yo'qotadi.
  static const Duration paymentWindow = Duration(minutes: 20);

  /// Bir marta to'lovda beriladigan muddat.
  static const Duration subscriptionPeriod = Duration(days: 30);

  // ---------------------------------------------------------------
  // Sozlamalar
  // ---------------------------------------------------------------

  /// Sozlamalarni bir martalik o'qish (tahrirlash formasini
  /// to'ldirish uchun).
  Future<PremiumConfig> fetchConfig() async {
    try {
      final doc =
          await _firestore.collection('appConfig').doc('premium').get();
      if (!doc.exists || doc.data() == null) return PremiumConfig.fallback;
      return PremiumConfig.fromFirestore(doc.data()!);
    } catch (_) {
      return PremiumConfig.fallback;
    }
  }

  /// To'lov rekvizitlarini saqlaydi (faqat super admin — qolganini
  /// Firestore qoidalari to'sadi).
  ///
  /// Bu shuning uchun kerakki, aks holda karta raqami faqat APK
  /// ichidagi zaxira qiymatda bo'lardi va uni o'zgartirish uchun har
  /// safar yangi reliz chiqarish kerak bo'lardi.
  Future<void> saveConfig(PremiumConfig config) async {
    await _firestore.collection('appConfig').doc('premium').set({
      'cardNumber': config.cardNumber,
      'cardHolder': config.cardHolder,
      'monthlyPrice': config.monthlyPrice,
      'adminTelegram': config.adminTelegram,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<PremiumConfig> watchConfig() {
    return _firestore.collection('appConfig').doc('premium').snapshots().map(
      (doc) {
        if (!doc.exists || doc.data() == null) return PremiumConfig.fallback;
        return PremiumConfig.fromFirestore(doc.data()!);
      },
    ).handleError((_) => PremiumConfig.fallback);
  }

  // ---------------------------------------------------------------
  // Kunlik limit
  // ---------------------------------------------------------------

  /// Berilgan foydalanuvchi bugun (mahalliy sana bo'yicha) shu
  /// mahallada nechta murojaat yaratganini sanaydi.
  Future<int> countRequestsCreatedToday({
    required String mahallaId,
    required String uid,
  }) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final snapshot = await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .where('authorUid', isEqualTo: uid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // ---------------------------------------------------------------
  // Foydalanuvchi tomoni
  // ---------------------------------------------------------------

  /// Joriy foydalanuvchining oxirgi to'lov so'rovini kuzatadi.
  Stream<PremiumRequest?> watchMyLatestRequest() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _firestore
        .collection('premiumRequests')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty
            ? null
            : PremiumRequest.fromFirestore(s.docs.first.id, s.docs.first.data()));
  }

  /// Yangi to'lov so'rovi ochadi va uning ID'sini qaytaradi.
  Future<String> createRequest({
    required String fullName,
    required String phone,
    required int amount,
    int months = 1,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('Foydalanuvchi tizimga kirmagan');

    final now = DateTime.now();
    final doc = await _firestore.collection('premiumRequests').add({
      'uid': uid,
      'fullName': fullName,
      'phone': phone,
      'amount': amount,
      'months': months,
      'status': PremiumRequestStatus.kutilmoqda.storageValue,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(paymentWindow)),
    });
    return doc.id;
  }

  /// Foydalanuvchi "To'ladim" tugmasini bosdi — super adminga
  /// bildirishnoma yuboriladi.
  Future<void> markAsPaid(String requestId) async {
    await _firestore.collection('premiumRequests').doc(requestId).update({
      'status': PremiumRequestStatus.tolandi.storageValue,
      'paidAt': FieldValue.serverTimestamp(),
    });

    final doc =
        await _firestore.collection('premiumRequests').doc(requestId).get();
    final data = doc.data();
    if (data == null) return;

    await _notifySuperAdmins(
      title: 'Premium to\'lov',
      body: '${data['fullName']} — ${data['amount']} so\'m to\'ladi, tasdiqlash kerak',
      relatedId: requestId,
    );
  }

  /// Foydalanuvchi so'rovni bekor qildi.
  Future<void> cancelRequest(String requestId) async {
    await _firestore.collection('premiumRequests').doc(requestId).update({
      'status': PremiumRequestStatus.muddatiTugadi.storageValue,
    });
  }

  // ---------------------------------------------------------------
  // Super admin tomoni
  // ---------------------------------------------------------------

  /// Tasdiqlashni kutayotgan so'rovlar.
  Stream<List<PremiumRequest>> watchPendingRequests() {
    return _firestore
        .collection('premiumRequests')
        .where('status', isEqualTo: PremiumRequestStatus.tolandi.storageValue)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PremiumRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// So'rovni tasdiqlaydi va foydalanuvchiga premium beradi.
  Future<void> approveRequest(PremiumRequest request) async {
    await grantPremium(request.uid, months: request.months);
    await _firestore.collection('premiumRequests').doc(request.id).update({
      'status': PremiumRequestStatus.tasdiqlandi.storageValue,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': _auth.currentUser?.uid,
    });

    await NotificationRepository().sendToUser(
      uid: request.uid,
      type: NotificationType.premiumApproved,
      title: 'Premium faollashtirildi',
      body: '${request.months} oylik premium obunangiz ochildi. Rahmat!',
    );
  }

  /// So'rovni rad etadi.
  Future<void> rejectRequest(PremiumRequest request, {String? reason}) async {
    await _firestore.collection('premiumRequests').doc(request.id).update({
      'status': PremiumRequestStatus.radEtildi.storageValue,
      'decidedAt': FieldValue.serverTimestamp(),
      'decidedBy': _auth.currentUser?.uid,
      if (reason != null) 'rejectReason': reason,
    });

    await NotificationRepository().sendToUser(
      uid: request.uid,
      type: NotificationType.premiumRejected,
      title: 'Premium so\'rovi rad etildi',
      body: reason ?? 'To\'lov tasdiqlanmadi. Admin bilan bog\'laning.',
    );
  }

  /// Premium muddatini beradi/uzaytiradi.
  ///
  /// Amaldagi obuna hali tugamagan bo'lsa — uning ustiga qo'shiladi,
  /// aks holda hozirdan boshlanadi.
  Future<void> grantPremium(String uid, {int months = 1}) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final current = (userDoc.data()?['premiumUntil'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final base = (current != null && current.isAfter(now)) ? current : now;
    final until = base.add(subscriptionPeriod * months);

    await _firestore.collection('users').doc(uid).set(
      {'premiumUntil': Timestamp.fromDate(until)},
      SetOptions(merge: true),
    );
  }

  /// Premium holatini muddatidan oldin bekor qiladi.
  Future<void> revokePremium(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'premiumUntil': FieldValue.delete(),
    });
  }

  /// Barcha super adminlarga bildirishnoma yuboradi.
  Future<void> _notifySuperAdmins({
    required String title,
    required String body,
    String? relatedId,
  }) async {
    final admins = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'superAdmin')
        .get();
    final repo = NotificationRepository();
    for (final doc in admins.docs) {
      await repo.sendToUser(
        uid: doc.id,
        type: NotificationType.premiumPaymentSubmitted,
        title: title,
        body: body,
        relatedId: relatedId,
      );
    }
  }
}

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return PremiumRepository();
});

final premiumConfigProvider = StreamProvider<PremiumConfig>((ref) {
  return ref.watch(premiumRepositoryProvider).watchConfig();
});

final myPremiumRequestProvider =
    StreamProvider.autoDispose<PremiumRequest?>((ref) {
  return ref.watch(premiumRepositoryProvider).watchMyLatestRequest();
});

final pendingPremiumRequestsProvider =
    StreamProvider.autoDispose<List<PremiumRequest>>((ref) {
  return ref.watch(premiumRepositoryProvider).watchPendingRequests();
});
