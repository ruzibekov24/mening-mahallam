import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// QR kod ichidan o'qilgan mahalla ma'lumoti.
class MahallaInfo {
  final String id;
  final String name;
  final String district;
  final String extra;
  final double? latitude;
  final double? longitude;
  final List<List<double>>? boundary;

  MahallaInfo({
    required this.id,
    required this.name,
    required this.district,
    required this.extra,
    this.latitude,
    this.longitude,
    this.boundary,
  });

  factory MahallaInfo.fromFirestore(String id, Map<String, dynamic> data) {
    // Firestore ichma-ich massivlarni (array-in-array) qo'llab-
    // quvvatlamaydi, shuning uchun chegara nuqtalari har biri
    // {lat: ..., lng: ...} shaklidagi map sifatida saqlanadi.
    final rawBoundary = data['boundary'] as List<dynamic>?;
    return MahallaInfo(
      id: id,
      name: data['name'] ?? "Noma'lum mahalla",
      district: data['district'] ?? '',
      extra: data['extra'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      boundary: rawBoundary?.map((point) {
        final map = point as Map<String, dynamic>;
        return [
          (map['lat'] as num).toDouble(),
          (map['lng'] as num).toDouble(),
        ];
      }).toList(),
    );
  }
}

class MahallaNotFoundException implements Exception {
  final String message;
  MahallaNotFoundException(this.message);
}

class MahallaRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MahallaRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// QR koddagi (yoki qo'lda kiritilgan) 8 belgili qo'shilish kodini
  /// (1 harf + 7 raqam, masalan "Y2345678") `joinCodes/{code}` orqali
  /// haqiqiy mahallaga moslab, mahalla ma'lumotlarini o'qiydi.
  ///
  /// MUHIM: kod to'g'ridan-to'g'ri `mahallas/{id}` hujjat ID'si EMAS.
  /// `mahallas` kolleksiyasini istalgan tizimga kirgan foydalanuvchi
  /// `list` qila oladi (`firestore.rules`), shuning uchun maxfiy kod
  /// alohida `joinCodes` kolleksiyasida saqlanadi — u faqat aniq kodni
  /// bilgan holda `get` qilinadi, `list` esa butunlay taqiqlangan.
  /// Bu tasodifiy taxmin qilib yoki ro'yxatni sanab chiqib boshqa
  /// mahallaga "kirib olish"ning oldini oladi.
  Future<MahallaInfo> lookupByQrCode(String rawQrValue) async {
    final code = _extractJoinCode(rawQrValue);
    if (code == null) {
      throw MahallaNotFoundException('Mahalla topilmadi. QR kodni tekshiring.');
    }

    final joinDoc = await _firestore.collection('joinCodes').doc(code).get();
    final mahallaId = joinDoc.data()?['mahallaId'] as String?;
    if (mahallaId == null || mahallaId.isEmpty) {
      throw MahallaNotFoundException('Mahalla topilmadi. QR kodni tekshiring.');
    }

    final mahalla = await fetchMahallaInfo(mahallaId);
    if (mahalla == null) {
      throw MahallaNotFoundException('Mahalla topilmadi. QR kodni tekshiring.');
    }

    return mahalla;
  }

  /// Kodni qo'lda kiritganda ham xuddi shu tekshiruvdan o'tkazamiz.
  Future<MahallaInfo> lookupByManualCode(String code) => lookupByQrCode(code);

  /// Xom qiymatdan (QR yoki qo'lda kiritilgan matn) harf-raqamlarni
  /// ajratib, katta harfga o'tkazadi — "y234-5678", "Y234 5678",
  /// "mahallam://mahalla/Y2345678" kabi variantlarning barchasi bir
  /// xil 8 belgili kodga keltiriladi. Format mos kelmasa (aynan 8
  /// ta harf/raqam bo'lmasa) `null` qaytaradi.
  String? _extractJoinCode(String rawValue) {
    final normalized =
        rawValue.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (normalized.length != 8) return null;
    return normalized;
  }

  /// Mahalla ID orqali to'liq ma'lumotni (jumladan xarita markazi
  /// uchun koordinatalarni) bir martalik o'qiydi.
  Future<MahallaInfo?> fetchMahallaInfo(String mahallaId) async {
    final doc = await _firestore.collection('mahallas').doc(mahallaId).get();
    if (!doc.exists) return null;
    return MahallaInfo.fromFirestore(doc.id, doc.data()!);
  }

  /// Tasdiqlangan mahallani foydalanuvchi profiliga bog'laydi.
  ///
  /// `users/{uid}.mahallaId`ni yangilash bilan bir vaqtda
  /// `mahallas/{mahallaId}/members/{uid}` marker hujjatini ham yozadi
  /// (eski mahalladan markerni o'chirib). Bu marker — qo'shnilar/a'zolar
  /// ro'yxatini xavfsiz "list" so'rovi bilan olish uchun kerak (batafsili
  /// izoh uchun `firestore.rules`dagi `members` bo'limiga qarang).
  /// Ikkala yozuv bitta batch ichida — biri rad etilsa, ikkalasi ham
  /// bekor bo'ladi.
  Future<void> attachUserToMahalla(String mahallaId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw MahallaNotFoundException('Foydalanuvchi tizimga kirmagan');
    }

    final userRef = _firestore.collection('users').doc(uid);
    final currentDoc = await userRef.get();
    final previousMahallaId = currentDoc.data()?['mahallaId'] as String?;

    final batch = _firestore.batch();
    batch.update(userRef, {'mahallaId': mahallaId});
    batch.set(
      _firestore
          .collection('mahallas')
          .doc(mahallaId)
          .collection('members')
          .doc(uid),
      {'uid': uid},
    );
    if (previousMahallaId != null && previousMahallaId != mahallaId) {
      batch.delete(
        _firestore
            .collection('mahallas')
            .doc(previousMahallaId)
            .collection('members')
            .doc(uid),
      );
    }
    await batch.commit();
  }

  /// Barcha mahallalar ro'yxatini o'qiydi — faqat super admin uchun
  /// mahalla almashtirish ekranida ishlatiladi (`mahallas` kolleksiyasi
  /// o'qish uchun tizimga kirgan har kimga ochiq, lekin bu funksiyani
  /// UI darajasida faqat superAdmin chaqiradi).
  Future<List<MahallaInfo>> fetchAllMahallas() async {
    final snapshot = await _firestore.collection('mahallas').get();
    return snapshot.docs
        .map((doc) => MahallaInfo.fromFirestore(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Mahalla chegarasini (poligon nuqtalari) saqlaydi — faqat rais
  /// chaqirishi kerak (UI darajasida tekshiriladi). Firestore ichma-
  /// ich massivlarni qo'llab-quvvatlamaydi, shuning uchun har bir
  /// nuqta {lat: ..., lng: ...} map sifatida yoziladi.
  Future<void> saveBoundary(String mahallaId, List<List<double>> points) async {
    await _firestore.collection('mahallas').doc(mahallaId).update({
      'boundary': points
          .map((p) => {'lat': p[0], 'lng': p[1]})
          .toList(),
    });
  }

  /// Mahalla xarita markazini saqlaydi.
  ///
  /// Markaz berilmagan bo'lsa, xarita joylashuvi bor birinchi
  /// murojaatga, u ham bo'lmasa umumiy standart nuqtaga tushib
  /// qoladi — ya'ni mahalla butunlay boshqa joyda ko'rinishi mumkin.
  /// Shuning uchun uni belgilash imkoni bo'lishi shart.
  Future<void> saveCenter(String mahallaId, double lat, double lng) async {
    await _firestore.collection('mahallas').doc(mahallaId).update({
      'latitude': lat,
      'longitude': lng,
    });
  }

}

final mahallaRepositoryProvider = Provider<MahallaRepository>((ref) {
  return MahallaRepository();
});