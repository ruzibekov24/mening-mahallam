import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 24 soatlik vaqtinchalik hikoya — `mahallas/{mahallaId}/stories/{id}`
/// hujjatida saqlanadi. Muddati (`expiresAt`) yaratilish paytida
/// CLIENT tomonida hisoblanadi (createdAt + 24soat) va so'rov shu
/// maydon bo'yicha filtrlanadi — Firebase Cloud Functions/Blaze plan
/// yo'qligi sababli (ilova bo'ylab boshqa joylarda ham shu sabab bilan
/// qochilgan — `image_upload_service.dart`, `notification_repository.
/// dart`ga qarang), muddati tugagan hujjatlarni serverda avtomatik
/// o'chirish uchun cron ishlatilmaydi. Amaliy natija: foydalanuvchi
/// uchun hikoya darhol "yo'qoladi" (so'rov uni qaytarmay qo'yadi),
/// lekin hujjat/media Storage'da qolib ketadi — bu qabul qilingan
/// cheklov, kelajakda Supabase Edge Function + pg_cron bilan
/// tozalanishi mumkin.
class Story {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String mediaUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// uid -> true — kim ko'rganini belgilaydi (reaksiyalardagi
  /// `Map<uid, ...>` pattern bilan bir xil, faqat o'z kalitini
  /// o'zgartirishga ruxsat beriladi).
  final Map<String, bool> viewedUids;

  Story({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.mediaUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewedUids = const {},
  });

  bool isViewedBy(String uid) => viewedUids[uid] == true;

  factory Story.fromFirestore(String id, Map<String, dynamic> data) {
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final expiresTimestamp = data['expiresAt'] as Timestamp?;
    return Story(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      mediaUrl: data['mediaUrl'] ?? '',
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      expiresAt: expiresTimestamp?.toDate() ??
          DateTime.now().add(const Duration(hours: 24)),
      viewedUids: Map<String, bool>.from(data['viewedUids'] ?? const {}),
    );
  }
}

class StoryRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _storiesRef(String mahallaId) =>
      _firestore.collection('mahallas').doc(mahallaId).collection('stories');

  /// Hali muddati tugamagan hikoyalarni, muddati tugashiga yaqinidan
  /// boshlab kuzatadi. `expiresAt` bo'yicha oraliq filtr borligi
  /// sababli, birinchi `orderBy` ham shu maydon bo'yicha bo'lishi
  /// SHART (Firestore talabi).
  Stream<List<Story>> watchActiveStories(String mahallaId) {
    return _storiesRef(mahallaId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Story.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Future<void> createStory({
    required String mahallaId,
    required String authorName,
    String? authorPhotoUrl,
    required String mediaUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final now = DateTime.now();
    await _storiesRef(mahallaId).add({
      'authorUid': uid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'mediaUrl': mediaUrl,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(hours: 24))),
      'viewedUids': <String, bool>{},
    });
  }

  Future<void> markViewed({
    required String mahallaId,
    required String storyId,
    required String uid,
  }) async {
    await _storiesRef(mahallaId)
        .doc(storyId)
        .update({'viewedUids.$uid': true});
  }

  /// O'z hikoyasini o'chiradi — hikoyalar vaqtinchalik bo'lgani uchun
  /// (izoh/reaksiya kabi bog'liq ma'lumot yo'q) qattiq o'chirish
  /// xavfsiz.
  Future<void> deleteStory({
    required String mahallaId,
    required String storyId,
  }) async {
    await _storiesRef(mahallaId).doc(storyId).delete();
  }
}
