import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shikoyat qilingan narsaning turi.
enum ReportTargetType {
  chatMessage,
  announcement,
  serviceAd,
  user,
  post,
  comment,
  story,
}

extension ReportTargetTypeX on ReportTargetType {
  static ReportTargetType fromString(String value) {
    switch (value) {
      case 'announcement':
        return ReportTargetType.announcement;
      case 'serviceAd':
        return ReportTargetType.serviceAd;
      case 'user':
        return ReportTargetType.user;
      case 'post':
        return ReportTargetType.post;
      case 'comment':
        return ReportTargetType.comment;
      case 'story':
        return ReportTargetType.story;
      default:
        return ReportTargetType.chatMessage;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ReportTargetType.chatMessage:
        return 'chatMessage';
      case ReportTargetType.announcement:
        return 'announcement';
      case ReportTargetType.serviceAd:
        return 'serviceAd';
      case ReportTargetType.user:
        return 'user';
      case ReportTargetType.post:
        return 'post';
      case ReportTargetType.comment:
        return 'comment';
      case ReportTargetType.story:
        return 'story';
    }
  }
}

/// Shikoyat sababi — tez tanlash uchun eng ko'p uchraydigan sabablar,
/// qolganlari uchun [ReportReason.boshqa] + erkin matn ([Report.details]).
enum ReportReason { spam, haqoratOmuhandaslik, aldash, nomunosib, boshqa }

extension ReportReasonX on ReportReason {
  static ReportReason fromString(String value) {
    switch (value) {
      case 'spam':
        return ReportReason.spam;
      case 'haqoratOmuhandaslik':
        return ReportReason.haqoratOmuhandaslik;
      case 'aldash':
        return ReportReason.aldash;
      case 'nomunosib':
        return ReportReason.nomunosib;
      default:
        return ReportReason.boshqa;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.haqoratOmuhandaslik:
        return 'haqoratOmuhandaslik';
      case ReportReason.aldash:
        return 'aldash';
      case ReportReason.nomunosib:
        return 'nomunosib';
      case ReportReason.boshqa:
        return 'boshqa';
    }
  }
}

/// Shikoyatning admin tomonidan ko'rib chiqilish holati.
enum ReportStatus { pending, reviewed, dismissed }

extension ReportStatusX on ReportStatus {
  static ReportStatus fromString(String value) {
    switch (value) {
      case 'reviewed':
        return ReportStatus.reviewed;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  String get firestoreValue {
    switch (this) {
      case ReportStatus.pending:
        return 'pending';
      case ReportStatus.reviewed:
        return 'reviewed';
      case ReportStatus.dismissed:
        return 'dismissed';
    }
  }
}

/// Bitta shikoyat hujjati — yuqori darajadagi (mahallaga bog'lanmagan)
/// `reports` kolleksiyasida saqlanadi, shunda kelajakdagi admin paneli
/// hamma mahallalar bo'ylab birgalikda so'rov qila oladi.
///
/// DIQQAT: shikoyat qilish bloklashdan (`HomeRepository.blockUser`) FARQ
/// qiladi — u shikoyatchidan hech narsani avtomatik yashirmaydi, faqat
/// admin ko'rib chiqishi uchun navbatga qo'yadi.
class Report {
  final String id;
  final String reporterUid;
  final ReportTargetType targetType;
  final String targetId;

  /// Ko'rib chiquvchiga kontekst berish uchun qisqa matn/parcha —
  /// masalan xabar matni, e'lon sarlavhasi yoki foydalanuvchi ismi.
  final String targetSnippet;

  /// Shikoyat qaysi mahalladan kelgani — kelajakdagi admin panelida
  /// mahalla bo'yicha filtrlash uchun. Har doim ham ma'lum bo'lavermaydi
  /// (masalan foydalanuvchi hali mahallaga qo'shilmagan bo'lishi mumkin).
  final String? mahallaId;

  final ReportReason reason;

  /// Ixtiyoriy qo'shimcha izoh (erkin matn).
  final String details;

  final ReportStatus status;
  final DateTime createdAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  Report({
    required this.id,
    required this.reporterUid,
    required this.targetType,
    required this.targetId,
    required this.targetSnippet,
    required this.mahallaId,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory Report.fromFirestore(String id, Map<String, dynamic> data) {
    final createdTimestamp = data['createdAt'] as Timestamp?;
    final reviewedTimestamp = data['reviewedAt'] as Timestamp?;
    return Report(
      id: id,
      reporterUid: data['reporterUid'] ?? '',
      targetType:
          ReportTargetTypeX.fromString(data['targetType'] ?? 'chatMessage'),
      targetId: data['targetId'] ?? '',
      targetSnippet: data['targetSnippet'] ?? '',
      mahallaId: data['mahallaId'] as String?,
      reason: ReportReasonX.fromString(data['reason'] ?? 'boshqa'),
      details: data['details'] ?? '',
      status: ReportStatusX.fromString(data['status'] ?? 'pending'),
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: reviewedTimestamp?.toDate(),
    );
  }
}

class ReportRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReportRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Yangi shikoyat yaratadi — holati avtomatik "pending" bo'ladi.
  /// Faqat yaratish uchun ishlatiladi: mobil ilovada shikoyatlarni
  /// ko'rib chiqish/o'zgartirish yo'q (bu alohida admin panelida).
  Future<void> createReport({
    required ReportTargetType targetType,
    required String targetId,
    required String targetSnippet,
    required ReportReason reason,
    String? mahallaId,
    String details = '',
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    await _firestore.collection('reports').add({
      'reporterUid': uid,
      'targetType': targetType.firestoreValue,
      'targetId': targetId,
      'targetSnippet': targetSnippet,
      if (mahallaId != null) 'mahallaId': mahallaId,
      'reason': reason.firestoreValue,
      'details': details,
      'status': ReportStatus.pending.firestoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});
