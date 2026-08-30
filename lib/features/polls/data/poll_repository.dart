import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final String authorUid;
  final DateTime createdAt;

  /// uid -> tanlangan variant indeksi. Har bir foydalanuvchi faqat bitta
  /// ovozga ega — qayta ovoz bersa, oldingisi almashadi.
  final Map<String, int> votes;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.authorUid,
    required this.createdAt,
    required this.votes,
  });

  /// Har bir variant uchun ovozlar soni.
  List<int> get voteCounts {
    final counts = List<int>.filled(options.length, 0);
    for (final optionIndex in votes.values) {
      if (optionIndex >= 0 && optionIndex < counts.length) {
        counts[optionIndex]++;
      }
    }
    return counts;
  }

  int get totalVotes => votes.length;

  int? myVote(String? uid) => uid == null ? null : votes[uid];

  factory Poll.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return Poll(
      id: id,
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? const []),
      authorUid: data['authorUid'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      votes: Map<String, int>.from(data['votes'] ?? const {}),
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
      'votes': <String, int>{},
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
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .doc(pollId)
        .update({
      'question': question,
      'options': options,
      'votes': <String, int>{},
    });
  }

  /// Ovoz beradi (yoki oldingi ovozini almashtiradi). Firestore Rules
  /// bu yozuvni faqat `votes` maydonini o'zgartirishga cheklaydi —
  /// savol/variantlarni bu yo'l orqali o'zgartirib bo'lmaydi.
  Future<void> vote({
    required String mahallaId,
    required String pollId,
    required int optionIndex,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('polls')
        .doc(pollId)
        .update({'votes.$uid': optionIndex});
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
