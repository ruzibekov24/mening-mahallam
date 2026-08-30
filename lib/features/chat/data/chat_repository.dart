import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

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

  Conversation({
    required this.id,
    required this.participantUids,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderUid,
    required this.unreadCounts,
  });

  /// Ikki ishtirokchidan `myUid` bo'lmagani — suhbat oynasida
  /// "kim bilan gaplashyapman" degan savolga javob.
  String otherUid(String myUid) =>
      participantUids.firstWhere((uid) => uid != myUid, orElse: () => '');

  factory Conversation.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['lastMessageAt'] as Timestamp?;
    return Conversation(
      id: id,
      participantUids: List<String>.from(data['participantUids'] ?? const []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: timestamp?.toDate(),
      lastSenderUid: data['lastSenderUid'] as String?,
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? const {}),
    );
  }
}

class ChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return ChatMessage(
      id: id,
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
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
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final conversationId = conversationIdFor(uid, otherUid);
    final conversationRef =
        _firestore.collection('conversations').doc(conversationId);

    await conversationRef.set({
      'participantUids': [uid, otherUid]..sort(),
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': uid,
      'unreadCounts.$otherUid': FieldValue.increment(1),
      'unreadCounts.$uid': 0,
    }, SetOptions(merge: true));

    await conversationRef.collection('messages').add({
      'senderUid': uid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
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
        body: trimmed,
        relatedId: conversationId,
      );
    }
  }

  /// Shu suhbatdagi joriy foydalanuvchining o'qilmagan xabarlar
  /// hisoblagichini nolga tushiradi (suhbat ekrani ochilganda).
  Future<void> markConversationRead(String conversationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('conversations').doc(conversationId).update({
      'unreadCounts.$uid': 0,
    });
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
