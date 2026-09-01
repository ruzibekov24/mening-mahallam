import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bitta saqlangan AI suhbatining ro'yxatdagi ko'rinishi (sarlavha +
/// oxirgi yangilanish vaqti) — to'liq xabarlar emas, faqat
/// `AssistantSidebar` uchun kerakli maydonlar.
class AssistantChatSummary {
  final String id;
  final String title;
  final DateTime updatedAt;

  const AssistantChatSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory AssistantChatSummary.fromFirestore(
      String id, Map<String, dynamic> data) {
    return AssistantChatSummary(
      id: id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : "Suhbat",
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Firestore'da saqlangan bitta suhbat xabari.
class AssistantChatMessage {
  final String id;
  final String role; // 'user' | 'model'
  final String text;
  final DateTime createdAt;

  const AssistantChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  bool get isUser => role == 'user';

  factory AssistantChatMessage.fromFirestore(
      String id, Map<String, dynamic> data) {
    return AssistantChatMessage(
      id: id,
      role: data['role'] as String? ?? 'user',
      text: data['text'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// AI Yordamchi suhbatlarini `users/{uid}/assistantChats/{chatId}` ostida
/// saqlaydi va o'qiydi — to'liq shaxsiy, faqat egasi ko'radi (`firestore.rules`
/// dagi `assistantChats` bo'limi). Bitta ekranlik, xotirada tutiladigan
/// suhbatdan farqli o'laroq, bu foydalanuvchi ilovani yopib qayta ochsa
/// ham suhbatlarini (va ular orqali AI "eslab qoladigan" kontekstni)
/// yo'qotmasligi uchun.
class AssistantChatRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AssistantChatRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _chatsCol(String uid) =>
      _firestore.collection('users').doc(uid).collection('assistantChats');

  String? get _uid => _auth.currentUser?.uid;

  Stream<List<AssistantChatSummary>> watchChats() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _chatsCol(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  AssistantChatSummary.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<AssistantChatMessage>> watchMessages(String chatId) {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _chatsCol(uid)
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => AssistantChatMessage.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Foydalanuvchining birinchi xabaridan (150 belgigacha) sarlavha
  /// yasab, yangi suhbat hujjatini yaratadi. Chaqiruvchi natijadagi
  /// `chatId`ni keyingi `addMessage` chaqiruvlari uchun saqlab qo'yishi
  /// kerak.
  Future<String> createChat({required String firstUserMessage}) async {
    final uid = _uid;
    if (uid == null) throw StateError('Foydalanuvchi tizimga kirmagan');

    final title = firstUserMessage.trim().length > 60
        ? '${firstUserMessage.trim().substring(0, 60)}…'
        : firstUserMessage.trim();

    final doc = await _chatsCol(uid).add({
      'title': title.isEmpty ? 'Suhbat' : title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> addMessage({
    required String chatId,
    required String role,
    required String text,
  }) async {
    final uid = _uid;
    if (uid == null) throw StateError('Foydalanuvchi tizimga kirmagan');

    final chatRef = _chatsCol(uid).doc(chatId);
    await chatRef.collection('messages').add({
      'role': role,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await chatRef.update({'updatedAt': FieldValue.serverTimestamp()});
  }

  /// AI-generated qisqa sarlavhani (`mahallam-title` bloki, ekran
  /// `_send()`ida ajratib olinadi) saqlaydi — suhbatning har bir yangi
  /// xabaridan emas, faqat SUHBATNING BIRINCHI javobidan keyin
  /// chaqiriladi. `addMessage`dagi kabi jim (fire-and-forget) —
  /// sarlavha ixtiyoriy qulaylik, suhbatning o'zini to'sib qo'ymasligi
  /// kerak.
  Future<void> updateTitle(String chatId, String title) async {
    final uid = _uid;
    if (uid == null) return;
    await _chatsCol(uid).doc(chatId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChat(String chatId) async {
    final uid = _uid;
    if (uid == null) throw StateError('Foydalanuvchi tizimga kirmagan');

    final chatRef = _chatsCol(uid).doc(chatId);
    final messages = await chatRef.collection('messages').get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(chatRef);
    await batch.commit();
  }
}

final assistantChatRepositoryProvider =
    Provider<AssistantChatRepository>((ref) {
  return AssistantChatRepository();
});

final assistantChatsProvider =
    StreamProvider.autoDispose<List<AssistantChatSummary>>((ref) {
  return ref.watch(assistantChatRepositoryProvider).watchChats();
});
