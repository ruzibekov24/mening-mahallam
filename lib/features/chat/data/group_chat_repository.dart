import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/data/notification_repository.dart';

/// Guruh chati hujjati — `groupChats/{id}` yuqori darajadagi kolleksiya.
///
/// Mavjud 1:1 `Conversation`dan farqli o'laroq `participantUids` istalgan
/// sondagi (2+) foydalanuvchini o'z ichiga olishi mumkin va hujjat ID'si
/// avtomatik (Firestore tomonidan) generatsiya qilinadi — ikkita
/// ishtirokchining tartiblangan juftligiga bog'liq emas.
class GroupChat {
  final String id;
  final String name;
  final String mahallaId;
  final List<String> participantUids;
  final String createdBy;
  final DateTime? createdAt;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String? lastSenderUid;

  GroupChat({
    required this.id,
    required this.name,
    required this.mahallaId,
    required this.participantUids,
    required this.createdBy,
    required this.createdAt,
    this.lastMessage = '',
    this.lastMessageAt,
    this.lastSenderUid,
  });

  factory GroupChat.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAtTs = data['createdAt'] as Timestamp?;
    final lastMessageAtTs = data['lastMessageAt'] as Timestamp?;
    return GroupChat(
      id: id,
      name: data['name'] ?? '',
      mahallaId: data['mahallaId'] ?? '',
      participantUids: List<String>.from(data['participantUids'] ?? const []),
      createdBy: data['createdBy'] ?? '',
      createdAt: createdAtTs?.toDate(),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageAt: lastMessageAtTs?.toDate(),
      lastSenderUid: data['lastSenderUid'] as String?,
    );
  }
}

/// Guruh ichidagi bitta xabar — mavjud 1:1 `ChatMessage` bilan bir xil
/// shakl (matn, kim yubordi, qachon), faqat alohida kolleksiyada
/// (`groupChats/{id}/messages`) saqlanadi.
class GroupChatMessage {
  final String id;
  final String senderUid;
  final String text;
  final DateTime createdAt;

  GroupChatMessage({
    required this.id,
    required this.senderUid,
    required this.text,
    required this.createdAt,
  });

  factory GroupChatMessage.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return GroupChatMessage(
      id: id,
      senderUid: data['senderUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

class GroupChatRepository {
  final FirebaseFirestore _firestore;

  // `FirebaseAuth` shart emas — mavjud 1:1 `ChatRepository`dan farqli,
  // bu yerdagi barcha metodlar `uid`ni chaqiruvchidan aniq (explicit)
  // parametr sifatida oladi (masalan `senderUid`, `createdBy`), o'zi
  // ichida joriy foydalanuvchini aniqlashga hojat yo'q.
  GroupChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groupChatsCol =>
      _firestore.collection('groupChats');

  /// Yangi guruh chatini yaratadi. Yaratuvchi avtomatik ravishda
  /// `participantUids` ro'yxatiga qo'shiladi (agar hali yo'q bo'lsa).
  Future<String> createGroup({
    required String mahallaId,
    required String name,
    required List<String> participantUids,
    required String createdBy,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Guruh nomi bo\'sh bo\'lishi mumkin emas');
    }
    final uids = {...participantUids, createdBy}.toList();
    final doc = await _groupChatsCol.add({
      'name': trimmedName,
      'mahallaId': mahallaId,
      'participantUids': uids,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': null,
    });
    return doc.id;
  }

  /// Joriy foydalanuvchi a'zo bo'lgan guruhlarni, so'nggi xabar
  /// vaqti bo'yicha kamayish tartibida kuzatadi.
  Stream<List<GroupChat>> watchMyGroups(String uid) {
    return _groupChatsCol
        .where('participantUids', arrayContains: uid)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupChat.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  Stream<GroupChat?> watchGroup(String groupId) {
    return _groupChatsCol.doc(groupId).snapshots().map(
        (doc) => doc.exists ? GroupChat.fromFirestore(doc.id, doc.data()!) : null);
  }

  Stream<List<GroupChatMessage>> watchGroupMessages(String groupId) {
    return _groupChatsCol
        .doc(groupId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GroupChatMessage.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Guruhga xabar yuboradi va guruh hujjatidagi so'nggi xabar
  /// ma'lumotlarini yangilaydi. Guruhdagi boshqa a'zolarga
  /// bildirishnoma ham yuboriladi.
  Future<void> sendGroupMessage({
    required String groupId,
    required String senderUid,
    required String text,
    String senderFullName = '',
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final groupRef = _groupChatsCol.doc(groupId);

    await groupRef.update({
      'lastMessage': trimmed,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderUid': senderUid,
    });

    await groupRef.collection('messages').add({
      'senderUid': senderUid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final groupDoc = await groupRef.get();
    final data = groupDoc.data();
    if (data == null) return;
    final participantUids = List<String>.from(data['participantUids'] ?? const []);
    final groupName = data['name'] ?? '';
    for (final uid in participantUids) {
      if (uid == senderUid) continue;
      await NotificationRepository().sendToUser(
        uid: uid,
        type: NotificationType.newMessage,
        title: senderFullName.isNotEmpty ? '$senderFullName ($groupName)' : groupName,
        body: trimmed,
        relatedId: groupId,
      );
    }
  }

  /// Guruhga yangi a'zo qo'shadi.
  Future<void> addMember({
    required String groupId,
    required String uid,
  }) async {
    await _groupChatsCol.doc(groupId).update({
      'participantUids': FieldValue.arrayUnion([uid]),
    });
  }

  /// Guruhdan a'zoni chiqaradi.
  Future<void> removeMember({
    required String groupId,
    required String uid,
  }) async {
    await _groupChatsCol.doc(groupId).update({
      'participantUids': FieldValue.arrayRemove([uid]),
    });
  }
}

final groupChatRepositoryProvider = Provider<GroupChatRepository>((ref) {
  return GroupChatRepository();
});

final myGroupChatsProvider = StreamProvider.autoDispose<List<GroupChat>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.watch(groupChatRepositoryProvider).watchMyGroups(uid);
});

final groupChatProvider =
    StreamProvider.autoDispose.family<GroupChat?, String>((ref, groupId) {
  return ref.watch(groupChatRepositoryProvider).watchGroup(groupId);
});

final groupChatMessagesProvider = StreamProvider.autoDispose
    .family<List<GroupChatMessage>, String>((ref, groupId) {
  return ref.watch(groupChatRepositoryProvider).watchGroupMessages(groupId);
});
