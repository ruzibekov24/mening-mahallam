import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

/// Ikki tomonlama bloklash tekshiruvi natijasida xabar yuborish rad
/// etilganda otiladi — men uni bloklaganman yoki u meni bloklagan.
/// Ikkala holat ham foydalanuvchiga bir xil ko'rinishda ko'rsatiladi
/// (`chat_screen.dart`), shuning uchun aynan qaysi tomon ekanini
/// bildirish shart emas.
class UserBlockedException implements Exception {}

/// Ikkita foydalanuvchi orasidagi suhbat — sarlavha ma'lumotlari
/// (oxirgi xabar, kim yubordi) tezkor ro'yxat uchun bu yerda saqlanadi,
/// haqiqiy xabarlar `messages` sub-kolleksiyasida.
class Conversation {
  final String id;
  final List<String> participantUids;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderUid;

  /// uid -> shu foydalanuvchi hali o'qimagan xabarlar soni.
  final Map<String, int> unreadCounts;

  /// uid -> shu foydalanuvchi suhbatni oxirgi marta qachon o'qigani.
  /// O'qish belgisi (bitta/ikkita tik) shu vaqt bilan xabar vaqtini
  /// solishtirib hisoblanadi — har bir xabar uchun alohida holat
  /// saqlanmaydi.
  final Map<String, DateTime> lastReadAt;

  /// uid -> shu foydalanuvchi hozir yozayotganini bildiruvchi vaqt
  /// belgisi. Foydalanuvchi yozishni to'xtatganda (yoki ~5 soniya
  /// harakatsizlikdan keyin) bu maydon o'chiriladi.
  final Map<String, DateTime> typing;

  Conversation({
    required this.id,
    required this.participantUids,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderUid,
    required this.unreadCounts,
    this.lastReadAt = const {},
    this.typing = const {},
  });

  /// Ikki ishtirokchidan `myUid` bo'lmagani — suhbat oynasida
  /// "kim bilan gaplashyapman" degan savolga javob.
  String otherUid(String myUid) =>
      participantUids.firstWhere((uid) => uid != myUid, orElse: () => '');

  static Map<String, DateTime> _timestampMap(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map((key, value) => MapEntry(
          key as String,
          (value as Timestamp).toDate(),
        ));
  }

  factory Conversation.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['lastMessageAt'] as Timestamp?;
    return Conversation(
      id: id,
      participantUids: List<String>.from(data['participantUids'] ?? const []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: timestamp?.toDate(),
      lastSenderUid: data['lastSenderUid'] as String?,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? const {}),
      lastReadAt: _timestampMap(data['lastReadAt']),
      typing: _timestampMap(data['typing']),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  /// Rasm xabarlari uchun yuklangan rasm URL'i — berilgan bo'lsa,
  /// [text] ixtiyoriy izoh (caption) sifatida ko'rsatiladi.
  final String? imageUrl;

  /// uid -> shu foydalanuvchi qo'ygan emoji reaksiya. Har bir
  /// foydalanuvchi bitta xabarga faqat bitta reaksiya qo'yishi mumkin.
  final Map<String, String> reactions;

  /// Xabar tahrirlangan bo'lsa, oxirgi tahrirlash vaqti — bubble'da
  /// "(tahrirlangan)" belgisi uchun.
  final DateTime? editedAt;

  /// Yumshoq o'chirish (soft-delete) — `true` bo'lsa [text] bo'sh
  /// bo'ladi, bubble o'rniga "Xabar o'chirildi" ko'rsatiladi. Hard
  /// delete emas: shu tufayli suhbatdagi boshqa tomon o'chirilgan
  /// xabar borligini biladi (Telegram uslubi bilan bir xil).
  final bool deleted;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
    this.imageUrl,
    this.reactions = const {},
    this.editedAt,
    this.deleted = false,
  });

  bool get isImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    final editedTimestamp = data['editedAt'] as Timestamp?;
    return ChatMessage(
      id: id,
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      reactions: Map<String, String>.from(data['reactions'] ?? const {}),
      editedAt: editedTimestamp?.toDate(),
      deleted: data['deleted'] == true,
    );
  }
}

class ChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Ikki uid'dan bir xil (tartiblangan) suhbat ID'sini hosil qiladi —
  /// shu orqali bitta juftlik uchun har doim bitta hujjat bo'ladi va
  /// "avval mavjudmi" so'rovsiz to'g'ridan-to'g'ri doc ID orqali
  /// murojaat qilish mumkin.
  String conversationIdFor(String uidA, String uidB) {
    final sorted = [uidA, uidB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Joriy foydalanuvchining barcha suhbatlarini, so'nggi xabar
  /// vaqti bo'yicha kamayish tartibida kuzatadi.
  Stream<List<Conversation>> watchMyConversations() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('conversations')
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Conversation.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Bitta suhbat hujjatini (o'qilgan/yozayotgan holatlar bilan)
  /// kuzatadi — suhbat ekranida o'qish belgisi va "yozmoqda..."
  /// ko'rsatkichi uchun ishlatiladi.
  Stream<Conversation?> watchConversation(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Conversation.fromFirestore(doc.id, doc.data()!);
    });
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Xabar yuboradi — suhbat hujjati mavjud bo'lmasa, shu bilan birga
  /// yaratadi (`set(merge: true)`). Qabul qiluvchiga push/ilova-ichi
  /// bildirishnoma ham yuboriladi.
  Future<void> sendMessage({
    required String otherUid,
    required String text,
    required String senderFullName,
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    final trimmed = text.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;
    if (trimmed.isEmpty && !hasImage) return;

    // Bloklash tekshiruvi — `HomeRepository.blockUser` ilgari faqat
    // qo'shnilar ro'yxatidan yashirardi, yozishni to'sib qo'ymasdi.
    // Ikkala yo'nalish ham tekshiriladi: men uni bloklagan bo'lsam
    // (o'z hujjatim — qo'shimcha o'qishsiz allaqachon ma'lum bo'lishi
    // mumkin edi, lekin izchillik uchun shu yerda ham tekshiramiz) yoki
    // u meni bloklagan bo'lsa.
    final myDoc = await _firestore.collection('users').doc(uid).get();
    final myBlockedUids =
        List<String>.from(myDoc.data()?['blockedUids'] ?? const []);
    if (myBlockedUids.contains(otherUid)) {
      throw UserBlockedException();
    }
    final otherDoc = await _firestore.collection('users').doc(otherUid).get();
    final otherBlockedUids =
        List<String>.from(otherDoc.data()?['blockedUids'] ?? const []);
    if (otherBlockedUids.contains(uid)) {
      throw UserBlockedException();
    }

    final conversationId = conversationIdFor(uid, otherUid);
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);

    // Suhbatlar ro'yxatida ko'rsatiladigan qisqa matn — rasm-faqat
    // xabar bo'lsa, matn o'rniga shu belgi ishlatiladi.
    final previewText = trimmed.isNotEmpty ? trimmed : "📷 Rasm";

    await conversationRef.set({
      'participantUids': [uid, otherUid]..sort(),
      'lastMessage': previewText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': uid,
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'unreadCounts.$uid': 0,
      // Yangi xabar yuborilganda o'zimizning "yozmoqda" belgimiz
      // tozalanadi — matn yuborilgach ko'rsatkich osilib qolmasligi
      // uchun.
      'typing.$uid': FieldValue.delete(),
    }, SetOptions(merge: true));

    await conversationRef.collection('messages').add({
      'senderUid': uid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
      if (hasImage) 'imageUrl': imageUrl,
    });

    // O'ziga o'zi xabar yozgan holatda bildirishnoma yubormaymiz —
    // `users/{uid}/notifications` yozish qoidasi qabul qiluvchi
    // yozuvchining o'zi bo'lishini taqiqlaydi (`uid != myUid()`),
    // shuning uchun bu chaqiruv shu holatda har doim rad etiladi.
    if (otherUid != uid) {
      await NotificationRepository().sendToUser(
        uid: otherUid,
        type: NotificationType.newMessage,
        title: senderFullName,
        body: previewText,
        relatedId: conversationId,
      );
    }
  }

  /// Xabar ostiga emoji reaksiya qo'yadi/olib tashlaydi (bir
  /// foydalanuvchi — bitta xabarga bitta reaksiya, e'lonlardagi
  /// naqsh bilan bir xil).
  Future<void> toggleMessageReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    required String? currentEmoji,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    if (currentEmoji == emoji) {
      await messageRef.update({'reactions.$uid': FieldValue.delete()});
    } else {
      await messageRef.update({'reactions.$uid': emoji});
    }
  }

  /// O'z xabarini tahrirlaydi — faqat yuboruvchining o'zi chaqirishi
  /// mumkin (Firestore Rules bilan mustahkamlangan). Agar bu suhbatdagi
  /// eng oxirgi xabar bo'lsa, `conversations/{id}.lastMessage` ham
  /// yangilanadi.
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newText,
  }) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': trimmed,
      'editedAt': FieldValue.serverTimestamp(),
    });
    await _refreshLastMessageIfNeeded(conversationId, messageId, trimmed);
  }

  /// O'z xabarini o'chiradi (yumshoq o'chirish — matn bo'shatiladi,
  /// hujjatning o'zi qolib, `deleted: true` belgilanadi). Faqat
  /// yuboruvchining o'zi chaqirishi mumkin.
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'text': '',
      'deleted': true,
      'editedAt': FieldValue.delete(),
    });
    await _refreshLastMessageIfNeeded(conversationId, messageId, null);
  }

  /// Tahrirlangan/o'chirilgan xabar shu suhbatdagi eng oxirgi xabar
  /// bo'lsa, `lastMessage` preview'ini yangilaydi — aks holda hech
  /// narsa qilmaydi (eski xabarlar preview'ga ta'sir qilmasligi kerak).
  Future<void> _refreshLastMessageIfNeeded(
    String conversationId,
    String editedMessageId,
    String? newPreviewIfLatest,
  ) async {
    final latestSnapshot = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (latestSnapshot.docs.isEmpty) return;
    final latest = latestSnapshot.docs.first;
    if (latest.id != editedMessageId) return;

    final preview = newPreviewIfLatest == null || newPreviewIfLatest.isEmpty
        ? (latest.data()['imageUrl'] != null ? '📷 Rasm' : '')
        : newPreviewIfLatest;
    await _firestore.collection('conversations').doc(conversationId).update({
      'lastMessage': preview,
    });
  }

  /// Joriy foydalanuvchi yozayotganini (yoki to'xtaganini) boshqa
  /// ishtirokchiga bildiradi. Chaqiruvchi tomonidan debounce
  /// qilinishi kutiladi — har harf kiritilganda emas.
  Future<void> setTyping(String conversationId, {required bool isTyping}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _firestore.collection('conversations').doc(conversationId).set({
        'typing.$uid': isTyping ? FieldValue.serverTimestamp() : FieldValue.delete(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Hujjat hali mavjud emas (ikkala tomon ham hali xabar
      // yubormagan) — bu holatda "yozmoqda" belgisi ko'rsatishga
      // hojat yo'q, xato jim yutiladi.
    }
  }

  /// Shu suhbatdagi joriy foydalanuvchining o'qilmagan xabarlar
  /// hisoblagichini nolga tushiradi (suhbat ekrani ochilganda).
  Future<void> markConversationRead(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    // Hujjat hali mavjud bo'lmasa (boshqa ishtirokchi hali birorta
    // xabar yubormagan bo'lsa) yozish shart emas — jim o'tkazib
    // yuboriladi.
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'unreadCounts.$uid': 0,
        'lastReadAt.$uid': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Hujjat mavjud emas — o'qiladigan narsa yo'q.
    }
  }

  /// Joriy foydalanuvchining barcha suhbatlaridagi o'qilmagan xabarlar
  /// yig'indisi — Profil menyusidagi "Xabarlar" belgisi uchun.
  Stream<int> watchTotalUnreadCount() {
    return watchMyConversations().map((conversations) {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return 0;
      return conversations.fold<int>(
          0, (total, c) => total + (c.unreadCounts[uid] ?? 0));
    });
  }
}
