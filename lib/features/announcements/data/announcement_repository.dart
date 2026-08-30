import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import '../../notifications/data/notification_repository.dart';

/// E'lon kategoriyasi — mockupdagi badge turlariga mos.
enum AnnouncementCategory { kommunal, xavfsizlik, umumiy }

extension AnnouncementCategoryX on AnnouncementCategory {
  String get label {
    switch (this) {
      case AnnouncementCategory.kommunal:
        return 'Kommunal';
      case AnnouncementCategory.xavfsizlik:
        return 'Xavfsizlik';
      case AnnouncementCategory.umumiy:
        return 'Umumiy';
    }
  }

  String get firestoreValue {
    switch (this) {
      case AnnouncementCategory.kommunal:
        return 'kommunal';
      case AnnouncementCategory.xavfsizlik:
        return 'xavfsizlik';
      case AnnouncementCategory.umumiy:
        return 'umumiy';
    }
  }

  static AnnouncementCategory fromString(String value) {
    switch (value) {
      case 'xavfsizlik':
        return AnnouncementCategory.xavfsizlik;
      case 'umumiy':
        return AnnouncementCategory.umumiy;
      default:
        return AnnouncementCategory.kommunal;
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementCategory category;
  final DateTime createdAt;
  final String? imageUrl;
  final String authorUid;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.createdAt,
    required this.imageUrl,
    required this.authorUid,
  });

  /// [body] endi Quill Delta JSON saqlaydi (rich text). Ro'yxat
  /// ko'rinishidagi qisqa preview uchun formatlashsiz oddiy matnga
  /// aylantiradi. Eski (Delta bo'lmagan) yozuvlar uchun o'zini
  /// o'zgarishsiz qaytaradi.
  String get plainTextPreview {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! List) return body;
      final doc = quill.Document.fromJson(decoded);
      return doc.toPlainText().trim();
    } catch (_) {
      return body;
    }
  }

  factory Announcement.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return Announcement(
      id: id,
      title: data['title'] ?? '',
      body: data['body'] ?? '',
      category:
          AnnouncementCategoryX.fromString(data['category'] ?? 'kommunal'),
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
      authorUid: data['authorUid'] ?? '',
    );
  }
}

class AnnouncementRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AnnouncementRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<Announcement>> watchAnnouncements(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi e'lon yaratadi — faqat tasdiqlangan (verifiedBadge) foydalanuvchi
  /// chaqirishi kerak (UI darajasida tekshiriladi).
  Future<void> createAnnouncement({
    required String mahallaId,
    required String title,
    required String body,
    required AnnouncementCategory category,
    String? imageUrl,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final docRef = await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('announcements')
        .add({
      'title': title,
      'body': body,
      'category': category.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'authorUid': uid,
    });

    // Mahalladagi barcha a'zolarga (o'zidan tashqari) yangi e'lon
    // haqida xabar beriladi.
    await NotificationRepository().sendToMahalla(
      mahallaId: mahallaId,
      type: NotificationType.newAnnouncement,
      title: "Yangi e'lon",
      body: title,
      relatedId: docRef.id,
      excludeUid: uid,
    );
  }

  /// E'lonni tahrirlaydi — faqat muallif yoki xodim/rais chaqirishi
  /// kerak (UI darajasida tekshiriladi, Firestore Rules bilan
  /// mustahkamlangan).
  Future<void> updateAnnouncement({
    required String mahallaId,
    required String announcementId,
    required String title,
    required String body,
    required AnnouncementCategory category,
    String? imageUrl,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('announcements')
        .doc(announcementId)
        .update({
      'title': title,
      'body': body,
      'category': category.firestoreValue,
      'imageUrl': imageUrl,
    });
  }

  /// E'lonni o'chiradi — faqat xodim/rais chaqirishi kerak (UI darajasida
  /// tekshiriladi, Firestore Rules bilan mustahkamlangan).
  Future<void> deleteAnnouncement({
    required String mahallaId,
    required String announcementId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('announcements')
        .doc(announcementId)
        .delete();
  }
}