import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

/// `imageUrls`da saqlangan havola video ekanini aniqlaydi (kengaytma
/// bo'yicha) — post preview'da rasm o'rniga video pleer ko'rsatish
/// kerakligini bilish uchun. Alohida `mediaType` maydoni
/// saqlamaslik uchun ataylab shunday — mavjud `imageUrls: List<String>`
/// maydonini o'zgartirmasdan, aralash rasm+video ro'yxatini
/// qo'llab-quvvatlaydi (`MediaPickerGrid`/`uploadMediaFiles`dagi kabi).
bool isVideoUrl(String url) {
  final path = url.split('?').first.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.3gp') ||
      path.endsWith('.webm');
}

/// Lentadagi bitta post — `mahallas/{mahallaId}/posts/{postId}`
/// hujjatida saqlanadi. Muallif ismi/rasmi post yaratilgan paytda
/// denormalize qilinadi (announcements'dagi kabi to'g'ridan-to'g'ri
/// maydon, ro'yxatda har bir post uchun alohida `users/{uid}` o'qishni
/// oldini olish uchun).
class Post {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final List<String> imageUrls;
  final DateTime createdAt;

  /// uid -> tanlagan reaksiya ("like" yoki "dislike"). Announcements'dagi
  /// bilan bir xil pattern — to'g'ridan-to'g'ri hujjat maydonida,
  /// subcollection emas.
  final Map<String, String> reactedUids;

  Post({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.imageUrls,
    required this.createdAt,
    this.reactedUids = const {},
  });

  int reactionCount(String reaction) =>
      reactedUids.values.where((e) => e == reaction).length;

  factory Post.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return Post(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? const []),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      reactedUids: Map<String, String>.from(data['reactedUids'] ?? const {}),
    );
  }
}

/// Bitta post ostidagi izoh — `mahallas/{mahallaId}/posts/{postId}/
/// comments/{commentId}` sub-kolleksiyasida saqlanadi (murojaat
/// izohlari bilan bir xil naqsh — `RequestComment`ga qarang).
class PostComment {
  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  factory PostComment.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return PostComment(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

class FeedRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FeedRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _postsRef(String mahallaId) =>
      _firestore.collection('mahallas').doc(mahallaId).collection('posts');

  /// (O'chirilmagan) postlarni eng yangisidan boshlab, `limit` tagacha
  /// kuzatadi. Mahalla postlari cheksiz o'sishi mumkinligi sababli
  /// (announcements/events'dan farqli — ularni faqat xodim/rais
  /// yaratadi), lenta butun kolleksiyani bir vaqtda o'qimasligi kerak.
  /// `limit` UI tomonidan "yana yuklash" bosilganda oshiriladi
  /// ([feed_providers.dart]dagi `postsLimitProvider`ga qarang).
  Stream<List<Post>> watchPosts(String mahallaId, {int limit = 20}) {
    return _postsRef(mahallaId)
        .where('deleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<Post?> watchPostById({
    required String mahallaId,
    required String postId,
  }) {
    return _postsRef(mahallaId).doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['deleted'] == true) return null;
      return Post.fromFirestore(doc.id, data);
    });
  }

  /// Yangi post yaratadi — mahallaning istalgan a'zosi chaqira oladi
  /// (e'lon/tadbirdan farqli, `role.canPost` bilan cheklanmagan).
  Future<void> createPost({
    required String mahallaId,
    required String authorName,
    String? authorPhotoUrl,
    required String text,
    List<String> imageUrls = const [],
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    await _postsRef(mahallaId).add({
      'authorUid': uid,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'imageUrls': imageUrls,
      'createdAt': FieldValue.serverTimestamp(),
      'reactedUids': <String, String>{},
      'deleted': false,
    });
  }

  /// Post matnini tahrirlaydi — faqat muallif chaqirishi kerak (UI
  /// darajasida tekshiriladi, Firestore Rules bilan mustahkamlangan).
  Future<void> updatePost({
    required String mahallaId,
    required String postId,
    required String text,
  }) async {
    await _postsRef(mahallaId).doc(postId).update({'text': text});
  }

  /// Postni o'chiradi — faqat muallif yoki xodim/rais (UI darajasida
  /// tekshiriladi, Firestore Rules bilan mustahkamlangan). Qattiq
  /// o'chirish emas, `deleted: true` — mavjud izohlar bilan bog'liqlik
  /// buzilmasligi uchun.
  Future<void> deletePost({
    required String mahallaId,
    required String postId,
  }) async {
    await _postsRef(mahallaId).doc(postId).update({'deleted': true});
  }

  /// Announcements'dagi `toggleReaction` bilan aynan bir xil mantiq:
  /// hali reaksiya bildirmagan bo'lsa qo'shadi ("like" yoki "dislike"),
  /// xuddi shuni qayta bossa olib tashlaydi, boshqasini bossa
  /// almashtiradi.
  Future<void> toggleReaction({
    required String mahallaId,
    required String postId,
    required String uid,
    required String reaction,
    required String? currentReaction,
  }) async {
    final docRef = _postsRef(mahallaId).doc(postId);
    if (currentReaction == reaction) {
      await docRef.update({'reactedUids.$uid': FieldValue.delete()});
    } else {
      await docRef.update({'reactedUids.$uid': reaction});
    }
  }

  /// Berilgan uid'lar uchun ismlarni oladi — "kim reaksiya bildirdi"
  /// ro'yxati uchun. `whereIn` bir so'rovda ko'pi bilan 10 ta hujjatni
  /// qo'llab-quvvatlagani uchun 10talik guruhlarga bo'lib so'raladi.
  Future<Map<String, String>> fetchUserNames(List<String> uids) async {
    if (uids.isEmpty) return {};
    final result = <String, String>{};
    for (var i = 0; i < uids.length; i += 10) {
      final chunk = uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10);
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
        result[doc.id] = name.isEmpty ? "Qo'shni" : name;
      }
    }
    return result;
  }

  Stream<List<PostComment>> watchComments({
    required String mahallaId,
    required String postId,
  }) {
    return _postsRef(mahallaId)
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi izoh qo'shadi — muallif doim joriy foydalanuvchi. Post
  /// muallifiga bildirishnoma yuboradi (o'z postiga o'zi izoh
  /// qoldirsa yubormaydi).
  Future<void> addComment({
    required String mahallaId,
    required String postId,
    required String authorName,
    required String text,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final postRef = _postsRef(mahallaId).doc(postId);
    await postRef.collection('comments').add({
      'authorUid': uid,
      'authorName': authorName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    try {
      final postDoc = await postRef.get();
      final postAuthorUid = postDoc.data()?['authorUid'] as String?;
      if (postAuthorUid != null && postAuthorUid != uid) {
        await NotificationRepository().sendToUser(
          uid: postAuthorUid,
          type: NotificationType.newPostComment,
          title: 'Postingizga yangi izoh',
          body: '$authorName postingizga izoh qoldirdi',
          relatedId: postId,
        );
      }
    } catch (_) {
      // Bildirishnoma yuborilmasa ham izohning o'zi allaqachon saqlangan.
    }
  }

  /// Izohni o'chiradi — faqat izoh muallifi (Firestore Rules bilan
  /// mustahkamlangan, `requests`dagi izoh o'chirish bilan bir xil
  /// naqsh: tahrirlash yo'q, faqat o'chirish).
  Future<void> deleteComment({
    required String mahallaId,
    required String postId,
    required String commentId,
  }) async {
    await _postsRef(mahallaId)
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
