import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter/material.dart';

/// Mahalliy xizmat toifasi — rais/xodim tomonidan tasdiqlangan
/// xizmat ko'rsatuvchilar (aholi ularga to'g'ridan-to'g'ri qo'ng'iroq
/// qiladi).
enum ServiceCategory { santexnik, elektrik, duradgor, tozalash, qurilish, boshqa }

extension ServiceCategoryX on ServiceCategory {
  String get firestoreValue {
    switch (this) {
      case ServiceCategory.santexnik:
        return 'santexnik';
      case ServiceCategory.elektrik:
        return 'elektrik';
      case ServiceCategory.duradgor:
        return 'duradgor';
      case ServiceCategory.tozalash:
        return 'tozalash';
      case ServiceCategory.qurilish:
        return 'qurilish';
      case ServiceCategory.boshqa:
        return 'boshqa';
    }
  }

  IconData get icon {
    switch (this) {
      case ServiceCategory.santexnik:
        return PhosphorIconsFill.wrench;
      case ServiceCategory.elektrik:
        return PhosphorIconsFill.lightning;
      case ServiceCategory.duradgor:
        return PhosphorIconsFill.hammer;
      case ServiceCategory.tozalash:
        return PhosphorIconsFill.broom;
      case ServiceCategory.qurilish:
        return PhosphorIconsFill.hardHat;
      case ServiceCategory.boshqa:
        return PhosphorIconsFill.toolbox;
    }
  }

  static ServiceCategory fromString(String value) {
    switch (value) {
      case 'elektrik':
        return ServiceCategory.elektrik;
      case 'duradgor':
        return ServiceCategory.duradgor;
      case 'tozalash':
        return ServiceCategory.tozalash;
      case 'qurilish':
        return ServiceCategory.qurilish;
      case 'boshqa':
        return ServiceCategory.boshqa;
      default:
        return ServiceCategory.santexnik;
    }
  }
}

class LocalService {
  final String id;
  final String name;
  final ServiceCategory category;
  final String phone;
  final String description;
  final String authorUid;
  final DateTime createdAt;

  /// Xizmat ko'rsatuvchining joylashuvi — ixtiyoriy (masalan uyiga
  /// chaqiriladigan santexnik uchun shart emas, lekin do'kon/ustaxona
  /// kabi doimiy manzili bor xizmatlar uchun xaritada ko'rsatiladi).
  /// `MahallaRequest` bilan bir xil naqsh: alohida `GeoPoint` emas,
  /// oddiy `latitude`/`longitude` maydonlari.
  final double? latitude;
  final double? longitude;

  /// uid -> tanlagan yulduz bahosi (1-5). `Announcement.reactedUids`
  /// bilan bir xil naqsh: subcollection emas, to'g'ridan-to'g'ri
  /// hujjat maydonida saqlanadi va targeted field-path yozuv orqali
  /// yangilanadi.
  final Map<String, int> ratings;

  /// Xizmat ko'rsatuvchi hozir buyurtma qabul qilishga tayyormi —
  /// staff/rais o'zi belgilaydi (mavjud tahrirlash huquqi bilan bir
  /// xil: `canManage`, faqat asl yaratuvchiga cheklanmagan). Standart
  /// holat — `true` (mavjud).
  final bool isAvailable;

  LocalService({
    required this.id,
    required this.name,
    required this.category,
    required this.phone,
    required this.description,
    required this.authorUid,
    required this.createdAt,
    this.latitude,
    this.longitude,
    this.ratings = const {},
    this.isAvailable = true,
  });

  bool get hasLocation => latitude != null && longitude != null;

  /// O'rtacha baho (0 dan 5 gacha). Hali baho bo'lmasa 0.
  double get averageRating {
    if (ratings.isEmpty) return 0;
    final sum = ratings.values.fold<int>(0, (acc, v) => acc + v);
    return sum / ratings.length;
  }

  /// Nechta odam baho berganini bildiradi.
  int get ratingCount => ratings.length;

  factory LocalService.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    final rawRatings = data['ratings'] as Map<String, dynamic>?;
    return LocalService(
      id: id,
      name: data['name'] ?? '',
      category: ServiceCategoryX.fromString(data['category'] ?? 'santexnik'),
      phone: data['phone'] ?? '',
      description: data['description'] ?? '',
      authorUid: data['authorUid'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      ratings: rawRatings == null
          ? const {}
          : rawRatings.map((uid, value) => MapEntry(uid, (value as num).toInt())),
      isAvailable: data['isAvailable'] != false,
    );
  }
}

class ServiceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ServiceRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<LocalService>> watchServices(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocalService.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi xizmat ko'rsatuvchi qo'shadi — faqat xodim/rais chaqirishi
  /// kerak (UI darajasida tekshiriladi, Firestore Rules bilan
  /// mustahkamlangan).
  Future<void> createService({
    required String mahallaId,
    required String name,
    required ServiceCategory category,
    required String phone,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .add({
      'name': name,
      'category': category.firestoreValue,
      'phone': phone,
      'description': description,
      'authorUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  Future<void> updateService({
    required String mahallaId,
    required String serviceId,
    required String name,
    required ServiceCategory category,
    required String phone,
    required String description,
    double? latitude,
    double? longitude,
    bool isAvailable = true,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .update({
      'name': name,
      'category': category.firestoreValue,
      'phone': phone,
      'description': description,
      // `null` yozib "location'ni tozalash" ni ham qo'llab-quvvatlaymiz:
      // FieldValue.delete() maydonni butunlay olib tashlaydi, `hasLocation`
      // esa buni yo'q joylashuv sifatida to'g'ri o'qiydi.
      'latitude': latitude ?? FieldValue.delete(),
      'longitude': longitude ?? FieldValue.delete(),
      'isAvailable': isAvailable,
    });
  }

  /// Xizmat mavjudlik holatini tezkor almashtiradi — kartadagi
  /// badge'ni bosib, to'liq tahrirlash formasini ochmasdan.
  Future<void> setServiceAvailability({
    required String mahallaId,
    required String serviceId,
    required bool isAvailable,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .update({'isAvailable': isAvailable});
  }

  Future<void> deleteService({
    required String mahallaId,
    required String serviceId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .delete();
  }

  /// Foydalanuvchining yulduz bahosini yozadi yoki ustidan yozadi
  /// (1-5). `Announcement.toggleReaction` bilan bir xil naqsh —
  /// targeted field-path yozuv, butun hujjatni qayta yozmaydi.
  Future<void> rateService({
    required String mahallaId,
    required String serviceId,
    required String uid,
    required int stars,
  }) async {
    if (stars < 1 || stars > 5) {
      throw ArgumentError.value(stars, 'stars', 'Baho 1 dan 5 gacha bo\'lishi kerak');
    }
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('services')
        .doc(serviceId)
        .update({'ratings.$uid': stars});
  }
}
