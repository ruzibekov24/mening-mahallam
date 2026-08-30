import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

/// So'rovnoma yopilgan bo'lsa (`closesAt` o'tgan bo'lsa) ovoz berishga
/// urinilganda otiladi.
class PollClosedException implements Exception {
  @override
  String toString() => 'PollClosedException: bu so\'rovnoma yopilgan';
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final String authorUid;
  final DateTime createdAt;

  /// Ko'p variant tanlashga ruxsat beradimi (checkbox) yoki yo'q
  /// (radio, faqat bitta variant).
  final bool allowMultiple;

  /// `true` bo'lsa, natijalar UI'da kim nimaga ovoz berganini oddiy
  /// (staff/rais bo'lmagan) foydalanuvchilarga ko'rsatmaydi — faqat
  /// umumiy son/foiz ko'rinadi.
  final bool isAnonymous;

  /// Belgilangan va o'tgan bo'lsa, ovoz berish yopiladi. `null` bo'lsa
  /// so'rovnoma muddatsiz ochiq.
  final DateTime? closesAt;

  /// uid -> tanlangan variant(lar) indekslari ro'yxati. Bitta variantli
  /// so'rovnomada bu ro'yxat har doim bitta elementdan iborat.
  ///
  /// Eski (v1.1 va oldingi) hujjatlarda bu maydon `uid -> int` shaklida
  /// saqlangan (bitta ovoz, indeks sifatida) — `fromFirestore` buni
  /// himoyalangan tarzda `List<int>`ga o'giradi, xato otmaydi.
  final Map<String, List<int>> votes;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.authorUid,
    required this.createdAt,
    required this.votes,
    this.allowMultiple = false,
    this.isAnonymous = false,
    this.closesAt,
  });

  /// Har bir variant uchun ovozlar soni.
  List<int> get voteCounts {
    final counts = List<int>.filled(options.length, 0);
    for (final selected in votes.values) {
      for (final optionIndex in selected) {
        if (optionIndex >= 0 && optionIndex < counts.length) {
          counts[optionIndex]++;
        }
      }
    }
    return counts;
  }

  /// Ovoz bergan (kamida bitta variant tanlagan) foydalanuvchilar soni.
  int get totalVotes => votes.values.where((v) => v.isNotEmpty).length;

  /// Berilgan foydalanuvchi tanlagan variant indekslari (bo'sh ro'yxat —
  /// hali ovoz bermagan).
  List<int> myVotes(String? uid) =>
      uid == null ? const [] : (votes[uid] ?? const []);

  bool get isClosed =>
      closesAt != null && closesAt!.isBefore(DateTime.now());

  static Map<String, List<int>> _parseVotes(dynamic raw) {
    if (raw is! Map) return {};
    final result = <String, List<int>>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      if (value is int) {
        // Eski format: uid -> bitta variant indeksi.
        result[key] = [value];
      } else if (value is List) {
        // Yangi format: uid -> variant indekslari ro'yxati.
        result[key] = value.whereType<num>().map((n) => n.toInt()).toList();
      }
    });
    return result;
  }

  factory Poll.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    final closesAtTimestamp = data['closesAt'] as Timestamp?;
    return Poll(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? const []),
      authorUid: data['authorUid'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      votes: _parseVotes(data['votes']),
      allowMultiple: data['allowMultiple'] == true,
      isAnonymous: data['isAnonymous'] == true,
      closesAt: closesAtTimestamp?.toDate(),
    );
  }
}

class PollRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PollRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Stream<List<Poll>> watchPolls(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Poll.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi so'rovnoma yaratadi — faqat xodim/rais chaqirishi kerak (UI
  /// darajasida tekshiriladi, Firestore Rules bilan mustahkamlangan).
  Future<void> createPoll({
    required String mahallaId,
    required String question,
    required List<String> options,
    bool allowMultiple = false,
    bool isAnonymous = false,
    DateTime? closesAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final docRef = await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .add({
      'question': question,
      'options': options,
      'authorUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'votes': <String, List<int>>{},
      'allowMultiple': allowMultiple,
      'isAnonymous': isAnonymous,
      'closesAt': closesAt != null ? Timestamp.fromDate(closesAt) : null,
    });

    await NotificationRepository().sendToMahalla(
      mahallaId: mahallaId,
      type: NotificationType.newPoll,
      title: "Yangi so'rovnoma",
      body: question,
      relatedId: docRef.id,
      excludeUid: uid,
    );
  }

  /// So'rovnomani tahrirlaydi — faqat xodim/rais chaqirishi kerak.
  /// Variantlar (va ular indekslari) o'zgarishi mumkinligi sababli
  /// mavjud ovozlar tozalanadi (aks holda eski ovozlar noto'g'ri
  /// variantga bog'lanib qolishi mumkin).
  Future<void> updatePoll({
    required String mahallaId,
    required String pollId,
    required String question,
    required List<String> options,
    bool allowMultiple = false,
    bool isAnonymous = false,
    DateTime? closesAt,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .doc(pollId)
        .update({
      'question': question,
      'options': options,
      'votes': <String, List<int>>{},
      'allowMultiple': allowMultiple,
      'isAnonymous': isAnonymous,
      'closesAt': closesAt != null ? Timestamp.fromDate(closesAt) : null,
    });
  }

  /// Ovoz beradi (yoki oldingi ovozini almashtiradi). Firestore Rules
  /// bu yozuvni faqat `votes` maydonini o'zgartirishga cheklaydi —
  /// savol/variantlarni bu yo'l orqali o'zgartirib bo'lmaydi.
  ///
  /// [optionIndexes] — tanlangan variant(lar) indekslari. `allowMultiple`
  /// `false` bo'lsa, faqat birinchi element yoziladi (bitta variant).
  ///
  /// `closesAt` o'tgan bo'lsa [PollClosedException] otiladi — chaqiruvchi
  /// (UI) buni tutib, so'rovnoma yopilganini ko'rsatishi kerak.
  Future<void> vote({
    required String mahallaId,
    required String pollId,
    required List<int> optionIndexes,
    bool allowMultiple = false,
    DateTime? closesAt,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    if (closesAt != null && closesAt.isBefore(DateTime.now())) {
      throw PollClosedException();
    }
    final value = allowMultiple
        ? optionIndexes
        : (optionIndexes.isEmpty ? <int>[] : [optionIndexes.first]);
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .doc(pollId)
        .update({'votes.$uid': value});
  }

  /// So'rovnomani o'chiradi — faqat xodim/rais chaqirishi kerak.
  Future<void> deletePoll({
    required String mahallaId,
    required String pollId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .doc(pollId)
        .delete();
  }
}
