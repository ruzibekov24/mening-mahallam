import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

class MahallaEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;
  final int participantsCount;

  MahallaEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.participantsCount,
  });

  factory MahallaEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['dateTime'] as Timestamp?;
    return MahallaEvent(
      id: id,
      title: data['title'] ?? '',
      dateTime: timestamp?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      participantsCount: (data['participantsCount'] ?? 0) as int,
    );
  }
}

class EventRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  EventRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Barcha tadbirlarni (o'tganlar ham) xronologik tartibda kuzatadi —
  /// bu yerda foydalanuvchi tarixni ham ko'ra oladi, Home ekranidagi
  /// "yaqin tadbirlar" preview'idan farqli.
  Stream<List<MahallaEvent>> watchEvents(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MahallaEvent.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi tadbir yaratadi — faqat xodim/rais chaqirishi kerak
  /// (UI darajasida tekshiriladi, Firestore Rules bilan mustahkamlanishi
  /// SHART, aks holda har qanday foydalanuvchi tadbir qo'sha oladi).
  Future<void> createEvent({
    required String mahallaId,
    required String title,
    required DateTime dateTime,
    required String location,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    final docRef = await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .add({
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'participantsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'authorUid': uid,
    });

    await NotificationRepository().sendToMahalla(
      mahallaId: mahallaId,
      type: NotificationType.newEvent,
      title: 'Yangi tadbir',
      body: title,
      relatedId: docRef.id,
      excludeUid: uid,
    );
  }

  /// Tadbirni tahrirlaydi — faqat muallif yoki xodim/rais chaqirishi
  /// kerak (UI darajasida tekshiriladi, Firestore Rules bilan
  /// mustahkamlangan).
  Future<void> updateEvent({
    required String mahallaId,
    required String eventId,
    required String title,
    required DateTime dateTime,
    required String location,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .update({
      'title': title,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
    });
  }

  /// Tadbirni o'chiradi — faqat xodim/rais chaqirishi kerak (UI
  /// darajasida tekshiriladi, Firestore Rules bilan mustahkamlangan).
  Future<void> deleteEvent({
    required String mahallaId,
    required String eventId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .delete();
  }
}