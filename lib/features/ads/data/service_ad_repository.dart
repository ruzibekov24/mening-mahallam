import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';

/// Mahalla ichidagi kichik xizmat reklamasi (usta, yetkazib berish,
/// repetitor va h.k.).
///
/// Ataylab KICHIK va KAM ko'rinadigan qilib ishlangan: bir vaqtning
/// o'zida faqat bitta reklama, ro'yxatning ma'lum joyida bir marta.
/// Maqsad — foydalanuvchini bezovta qilmasdan, mahalla ustalariga
/// arzon ko'rinish berish.
class ServiceAd {
  final String id;
  final String title;
  final String description;
  final String phone;
  final String ownerName;
  final DateTime activeUntil;
  final DateTime createdAt;

  ServiceAd({
    required this.id,
    required this.title,
    required this.description,
    required this.phone,
    required this.ownerName,
    required this.activeUntil,
    required this.createdAt,
  });

  bool get isActive => activeUntil.isAfter(DateTime.now());

  factory ServiceAd.fromFirestore(String id, Map<String, dynamic> data) {
    final until = data['activeUntil'] as Timestamp?;
    final created = data['createdAt'] as Timestamp?;
    return ServiceAd(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      phone: data['phone'] ?? '',
      ownerName: data['ownerName'] ?? '',
      activeUntil: until?.toDate() ?? DateTime.now(),
      createdAt: created?.toDate() ?? DateTime.now(),
    );
  }
}

class ServiceAdRepository {
  final FirebaseFirestore _firestore;

  ServiceAdRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reklama narxi (7 kunga) — ataylab arzon.
  static const int weeklyPrice = 4900;
  static const Duration defaultDuration = Duration(days: 7);

  /// Premium obunachilar uchun chegirma ulushi.
  static const double premiumDiscount = 0.5;

  /// Foydalanuvchiga tegishli reklama narxi.
  ///
  /// Premium obunachi xizmatini ikki barobar arzon reklama qila
  /// oladi — bu obunaning e'lon qilingan imkoniyatlaridan biri
  /// (`premiumBenefitAdDiscount`).
  static int priceFor({required bool isPremium}) =>
      isPremium ? (weeklyPrice * (1 - premiumDiscount)).round() : weeklyPrice;

  CollectionReference<Map<String, dynamic>> _col(String mahallaId) =>
      _firestore.collection('mahallas').doc(mahallaId).collection('serviceAds');

  /// Muddati tugamagan reklamalar.
  Stream<List<ServiceAd>> watchActiveAds(String mahallaId) {
    return _col(mahallaId)
        .where('activeUntil', isGreaterThan: Timestamp.now())
        .orderBy('activeUntil')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ServiceAd.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Super admin uchun — muddati tugaganlari bilan birga hammasi.
  Stream<List<ServiceAd>> watchAllAds(String mahallaId) {
    return _col(mahallaId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ServiceAd.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> createAd({
    required String mahallaId,
    required String title,
    required String description,
    required String phone,
    required String ownerName,
    Duration duration = defaultDuration,
  }) async {
    await _col(mahallaId).add({
      'title': title,
      'description': description,
      'phone': phone,
      'ownerName': ownerName,
      'createdAt': FieldValue.serverTimestamp(),
      'activeUntil': Timestamp.fromDate(DateTime.now().add(duration)),
    });
  }

  Future<void> deleteAd(String mahallaId, String adId) async {
    await _col(mahallaId).doc(adId).delete();
  }

  /// Muddatni uzaytiradi (to'lov qayta qilinganda).
  Future<void> extendAd(
    String mahallaId,
    String adId, {
    Duration duration = defaultDuration,
  }) async {
    final doc = await _col(mahallaId).doc(adId).get();
    final current = (doc.data()?['activeUntil'] as Timestamp?)?.toDate();
    final now = DateTime.now();
    final base = (current != null && current.isAfter(now)) ? current : now;
    await _col(mahallaId).doc(adId).update({
      'activeUntil': Timestamp.fromDate(base.add(duration)),
    });
  }
}

final serviceAdRepositoryProvider = Provider<ServiceAdRepository>((ref) {
  return ServiceAdRepository();
});

/// Ko'rsatiladigan reklama.
///
/// Premium foydalanuvchilarda HAR DOIM `null` qaytaradi — reklamalar
/// ular uchun umuman mavjud emas. Bir nechta faol reklama bo'lsa,
/// kun bo'yicha navbat bilan almashadi: shunda bitta reklama doim
/// birinchi o'rinni egallab olmaydi, lekin ekran ham "sakrab"
/// turmaydi (bir kun ichida bir xil reklama ko'rinadi).
final currentServiceAdProvider = Provider<ServiceAd?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).valueOrNull;
  if (profile == null || profile.isPremiumActive) return null;

  final mahallaId = profile.mahallaId;
  if (mahallaId == null) return null;

  final ads = ref.watch(activeServiceAdsProvider(mahallaId)).valueOrNull;
  if (ads == null || ads.isEmpty) return null;

  final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
  return ads[dayIndex % ads.length];
});

final activeServiceAdsProvider =
    StreamProvider.family<List<ServiceAd>, String>((ref, mahallaId) {
  return ref.watch(serviceAdRepositoryProvider).watchActiveAds(mahallaId);
});

final allServiceAdsProvider =
    StreamProvider.autoDispose.family<List<ServiceAd>, String>((ref, mahallaId) {
  return ref.watch(serviceAdRepositoryProvider).watchAllAds(mahallaId);
});
