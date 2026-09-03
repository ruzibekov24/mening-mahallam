import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

/// `imageUrls`da saqlangan havola video ekanini aniqlaydi (kengaytma
/// bo'yicha) — post/repost preview'da rasm o'rniga video pleer
/// ko'rsatish kerakligini bilish uchun. Alohida `mediaType` maydoni
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
/// Repost qilinganda original postdan denormalize qilingan qisqa
/// ko'rinish — repost kartasi original postni qayta o'qimasdan
/// ko'rsatishi uchun (bitta qo'shimcha Firestore o'qishdan qochish).
class RepostSnapshot {
  final String authorName;
  final String textPreview;
  final String? imageUrl;

  RepostSnapshot({
    required this.authorName,
    required this.textPreview,
    required this.imageUrl,
  });

  factory RepostSnapshot.fromMap(Map<String, dynamic> data) {
    return RepostSnapshot(
      authorName: data['authorName'] ?? '',
      textPreview: data['textPreview'] ?? '',
      imageUrl: data['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'authorName': authorName,
        'textPreview': textPreview,
        'imageUrl': imageUrl,
      };
}

class Post {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final List<String> imageUrls;
  final DateTime createdAt;

  /// uid -> tanlagan emoji. Announcements'dagi bilan bir xil pattern —
  /// to'g'ridan-to'g'ri hujjat maydonida, subcollection emas.
  final Map<String, String> reactedUids;

  /// Repost bo'lsa — original post id. `null` bo'lsa oddiy post.
  final String? repostOfPostId;
  final RepostSnapshot? repostSnapshot;

  /// uid -> shu foydalanuvchi yaratgan repost post'ining id'si.
  /// `reactedUids`dagi bilan bir xil naqsh — har bir a'zo bitta postni
  /// faqat BIR MARTA repost qila oladi (qayta bossa bekor qiladi),
  /// cheksiz takroriy repost bilan lentani to'ldirib yubormaslik uchun.
  final Map<String, String> repostedByUids;

  int get repostCount => repostedByUids.length;

  Post({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.imageUrls,
    required this.createdAt,
    this.reactedUids = const {},
    this.repostOfPostId,
    this.repostSnapshot,
    this.repostedByUids = const {},
  });

  bool get isRepost => repostOfPostId != null;

  int reactionCount(String emoji) =>
      reactedUids.values.where((e) => e == emoji).length;

  factory Post.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    final snapshotData = data['repostSnapshot'] as Map<String, dynamic>?;
    return Post(
      id: id,
      authorUid: data['authorUid'] ?? '',
      authorName: data['authorName'] ?? '',
      authorPhotoUrl: data['authorPhotoUrl'] as String?,
      text: data['text'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? const []),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      reactedUids: Map<String, String>.from(data['reactedUids'] ?? const {}),
      repostOfPostId: data['repostOfPostId'] as String?,
      repostSnapshot:
          snapshotData == null ? null : RepostSnapshot.fromMap(snapshotData),
      repostedByUids:
          Map<String, String>.from(data['repostedByUids'] ?? const {}),
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

  /// Postni o'z lentasiga repost qiladi/bekor qiladi — reaksiyalar
  /// bilan bir xil "toggle" mantiq: bir foydalanuvchi bitta postni
  /// faqat bir marta repost qila oladi (qayta bossa, o'zining repost
  /// postini bekor qiladi). Buning oldida cheksiz repost lentani
  /// bitta post bilan to'ldirib yuborishi mumkin edi. Original post
  /// ustiga qayta repost qilish (repostning reposti) UI darajasida
  /// cheklangan — zanjir chuqurlashib ketmasligi uchun.
  Future<void> toggleRepost({
    required String mahallaId,
    required Post original,
    required String authorName,
    String? authorPhotoUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final originalRef = _postsRef(mahallaId).doc(original.id);
    final existingRepostId = original.repostedByUids[uid];

    if (existingRepostId != null) {
      // Repostni bekor qilish — o'z repost post'ini soft-delete
      // qilish (mavjud `deletePost` bilan bir xil naqsh) va
      // original postdagi belgini olib tashlash.
      final repostRef = _postsRef(mahallaId).doc(existingRepostId);
      await _firestore.runTransaction((transaction) async {
        transaction.update(repostRef, {'deleted': true});
        transaction.update(originalRef, {
          'repostedByUids.$uid': FieldValue.delete(),
        });
      });
      return;
    }

    final preview = original.text.length > 140
        ? '${original.text.substring(0, 140)}…'
        : original.text;
    final newRepostRef = _postsRef(mahallaId).doc();

    await _firestore.runTransaction((transaction) async {
      transaction.set(newRepostRef, {
        'authorUid': uid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'text': '',
        'imageUrls': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'reactedUids': <String, String>{},
        'deleted': false,
        'repostOfPostId': original.id,
        'repostSnapshot': RepostSnapshot(
          authorName: original.authorName,
          textPreview: preview,
          imageUrl:
              original.imageUrls.isNotEmpty ? original.imageUrls.first : null,
        ).toMap(),
      });
      transaction.update(originalRef, {
        'repostedByUids.$uid': newRepostRef.id,
      });
    });
  }

  /// Post matnini tahrirlaydi — faqat muallif chaqirishi kerak (UI
  /// darajasida tekshiriladi, Firestore Rules bilan mustahkamlangan).
  /// Repostlar tahrirlanmaydi (`repostSnapshot` allaqachon original
  /// postning holatini aks ettiradi).
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
  /// hali reaksiya bildirmagan bo'lsa qo'shadi, xuddi shu emojini
  /// qayta bossa olib tashlaydi, boshqasini bossa almashtiradi.
  Future<void> toggleReaction({
    required String mahallaId,
    required String postId,
    required String uid,
    required String emoji,
    required String? currentEmoji,
  }) async {
    final docRef = _postsRef(mahallaId).doc(postId);
    if (currentEmoji == emoji) {
      await docRef.update({'reactedUids.$uid': FieldValue.delete()});
    } else {
      await docRef.update({'reactedUids.$uid': emoji});
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
