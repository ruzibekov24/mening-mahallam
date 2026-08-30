import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/supabase_config.dart';

/// Bildirishnoma turi — bosilganda qaysi ekranga o'tish kerakligini
/// aniqlash uchun ishlatiladi.
enum NotificationType {
  requestStatusChanged,
  newAnnouncement,
  newEvent,
  newPoll,
  newMessage,
  // Premium bilan bog'liq: birinchisi super adminga (kimdir to'ladi,
  // tasdiqlash kerak), qolgan ikkitasi foydalanuvchiga (admin qarori).
  premiumPaymentSubmitted,
  premiumApproved,
  premiumRejected,
  // Super adminga: kimdir hisobini o'chirishni so'radi (qo'lda
  // bajariladi, chunki qaytarib bo'lmaydigan amal).
  accountDeletionRequested,
}

extension NotificationTypeX on NotificationType {
  static NotificationType fromString(String? value) {
    switch (value) {
      case 'newAnnouncement':
        return NotificationType.newAnnouncement;
      case 'newEvent':
        return NotificationType.newEvent;
      case 'newPoll':
        return NotificationType.newPoll;
      case 'newMessage':
        return NotificationType.newMessage;
      case 'premiumPaymentSubmitted':
        return NotificationType.premiumPaymentSubmitted;
      case 'premiumApproved':
        return NotificationType.premiumApproved;
      case 'premiumRejected':
        return NotificationType.premiumRejected;
      case 'accountDeletionRequested':
        return NotificationType.accountDeletionRequested;
      default:
        return NotificationType.requestStatusChanged;
    }
  }

  String get storageValue {
    switch (this) {
      case NotificationType.requestStatusChanged:
        return 'requestStatusChanged';
      case NotificationType.newAnnouncement:
        return 'newAnnouncement';
      case NotificationType.newEvent:
        return 'newEvent';
      case NotificationType.newPoll:
        return 'newPoll';
      case NotificationType.newMessage:
        return 'newMessage';
      case NotificationType.premiumPaymentSubmitted:
        return 'premiumPaymentSubmitted';
      case NotificationType.premiumApproved:
        return 'premiumApproved';
      case NotificationType.premiumRejected:
        return 'premiumRejected';
      case NotificationType.accountDeletionRequested:
        return 'accountDeletionRequested';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    this.relatedId,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return AppNotification(
      id: id,
      type: NotificationTypeX.fromString(data['type'] as String?),
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] == true,
      relatedId: data['relatedId'] as String?,
    );
  }
}

/// Ilova ichidagi bildirishnomalarni boshqaradi — har foydalanuvchi
/// o'zining `users/{uid}/notifications` sub-kolleksiyasiga ega.
///
/// Firestore yozuvidan tashqari, agar qabul qiluvchining FCM tokeni
/// bo'lsa, haqiqiy push ham yuboriladi — Firebase Cloud Functions
/// orqali EMAS (bu Blaze/pullik plan talab qiladi), balki Supabase
/// Edge Function (`send-push`) orqali, bu bepul. Push yuborish
/// muvaffaqiyatsiz bo'lsa ham (masalan tarmoq xatosi) Firestore
/// yozuvi baribir saqlanadi — ilova ichidagi bildirishnomalar
/// ro'yxati push'ga bog'liq emas.
class NotificationRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    http.Client? httpClient,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  /// Berilgan tokenlarga haqiqiy push yuboradi. Xato bo'lsa jimgina
  /// yutiladi — push ilovaning asosiy funksionalligi emas, muvaffaqiyatsiz
  /// urinish boshqa hech narsani buzmasligi kerak.
  Future<void> _sendPush({
    required List<String> tokens,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedId,
  }) async {
    if (tokens.isEmpty) return;
    try {
      await _httpClient.post(
        Uri.parse(SupabaseConfig.functionUrl('send-push')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
        },
        body: jsonEncode({
          'tokens': tokens,
          'title': title,
          'body': body,
          // `type` bildirishnoma bosilganda to'g'ri ekranga o'tish uchun
          // kerak (PushNotificationService._handleTap) — avval faqat
          // `relatedId` yuborilardi, u yolg'iz holda qaysi ekranga
          // borishni aniqlay olmasdi.
          'data': {
            'type': type.storageValue,
            if (relatedId != null) 'relatedId': relatedId,
          },
        }),
      );
    } catch (_) {
      // Push yetkazilmasa ham ilova ichidagi bildirishnoma allaqachon
      // Firestore'ga yozilgan — foydalanuvchi ilovani ochganda ko'radi.
    }
  }

  /// Joriy foydalanuvchining bildirishnomalarini eng yangisidan
  /// boshlab kuzatadi.
  Stream<List<AppNotification>> watchMyNotifications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AppNotification.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// O'qilmagan bildirishnomalar sonini kuzatadi (Home ekranidagi
  /// badge uchun).
  Stream<int> watchUnreadCount() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(0);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Berilgan foydalanuvchiga (odatda boshqa kishi — murojaat egasi
  /// yoki mahalla a'zosi) bitta bildirishnoma yozadi.
  Future<void> sendToUser({
    required String uid,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .add({
      'type': type.storageValue,
      'title': title,
      'body': body,
      'relatedId': relatedId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final token = userDoc.data()?['fcmToken'] as String?;
    if (token != null) {
      await _sendPush(
        tokens: [token],
        title: title,
        body: body,
        type: type,
        relatedId: relatedId,
      );
    }
  }

  /// Berilgan mahalladagi BARCHA a'zolarga bitta bildirishnoma yozadi
  /// (masalan yangi e'lon/tadbir e'lon qilinganda). Firestore'da
  /// "broadcast" tushunchasi yo'q, shuning uchun har bir a'zo uchun
  /// alohida yozuv yaratiladi — kichik mahalla hajmida (odatda bir
  /// necha o'nlab-yuzlab kishi) bu maqbul yechim.
  ///
  /// A'zolar ro'yxati `users` kolleksiyasini `where('mahallaId', ...)`
  /// bilan so'rash o'rniga `mahallas/{mahallaId}/members` marker
  /// kolleksiyasidan olinadi — sababi `home_repository.dart`dagi
  /// `watchMahallaMembers` izohida tushuntirilgan: `get()`ga bog'liq
  /// qoida bilan `users`ni "list" so'rovi doim rad etilardi.
  Future<void> sendToMahalla({
    required String mahallaId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
    String? excludeUid,
  }) async {
    final membersSnapshot = await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('members')
        .get();
    final memberUids =
        membersSnapshot.docs.map((d) => d.id).where((id) => id != excludeUid);

    final batch = _firestore.batch();
    for (final uid in memberUids) {
      final notifRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc();
      batch.set(notifRef, {
        'type': type.storageValue,
        'title': title,
        'body': body,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    // Push uchun tokenlarni yig'amiz — har bir a'zo hujjati alohida
    // o'qiladi (`watchMahallaMembers`dagi kabi, "list" so'rov
    // cheklovidan mustasno bo'lish uchun).
    final userDocs = await Future.wait(
      memberUids.map((uid) => _firestore.collection('users').doc(uid).get()),
    );
    final tokens = userDocs
        .map((doc) => doc.data()?['fcmToken'] as String?)
        .whereType<String>()
        .toList();
    await _sendPush(
      tokens: tokens,
      title: title,
      body: body,
      type: type,
      relatedId: relatedId,
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final unread = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final myNotificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).watchMyNotifications();
});

final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.watch(notificationRepositoryProvider).watchUnreadCount();
});
