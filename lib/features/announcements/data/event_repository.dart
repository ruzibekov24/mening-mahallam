import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../notifications/data/notification_repository.dart';

class MahallaEvent {
  final String id;
  final String title;

  /// To'liq tavsif (oddiy matn) — ixtiyoriy, tafsilot ekranida
  /// ko'rsatiladi. Eski yozuvlarda bo'lmasligi mumkin.
  final String description;
  final DateTime dateTime;
  final String location;
  final int participantsCount;

  /// Qatnashish belgisi ("Boraman" tugmasi) shu tadbirda yoqilganmi.
  ///
  /// Standart holatda o'chiq: har bir tadbirda majburiy emas — rais
  /// tadbir yaratayotganda (`new_event_screen.dart`) alohida yoqadi.
  /// Kichik e'lonlarda (masalan "hovli tozalash kuni") kerak emas,
  /// katta yig'inlarda foydali.
  final bool rsvpEnabled;

  /// Qatnashishni belgilagan foydalanuvchilar — faqat `rsvpEnabled`
  /// bo'lganda ma'noli, lekin har doim o'qiladi (masalan rais keyin
  /// belgini o'chirsa ham, oldingi ro'yxat yo'qolmaydi).
  final List<String> attendeeUids;

  MahallaEvent({
    required this.id,
    required this.title,
    this.description = '',
    required this.dateTime,
    required this.location,
    required this.participantsCount,
    this.rsvpEnabled = false,
    this.attendeeUids = const [],
  });

  bool isAttendingBy(String uid) => attendeeUids.contains(uid);

  factory MahallaEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['dateTime'] as Timestamp?;
    return MahallaEvent(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] as String? ?? '',
      dateTime: timestamp?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      participantsCount: (data['participantsCount'] ?? 0) as int,
      rsvpEnabled: data['rsvpEnabled'] == true,
      attendeeUids: (data['attendeeUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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
    String description = '',
    required DateTime dateTime,
    required String location,
    bool rsvpEnabled = false,
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
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'participantsCount': 0,
      'rsvpEnabled': rsvpEnabled,
      'attendeeUids': <String>[],
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
    String description = '',
    required DateTime dateTime,
    required String location,
    required bool rsvpEnabled,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .update({
      'title': title,
      'description': description,
      'dateTime': Timestamp.fromDate(dateTime),
      'location': location,
      'rsvpEnabled': rsvpEnabled,
    });
  }

  /// "Boraman" — joriy foydalanuvchini qatnashuvchilar ro'yxatiga
  /// qo'shadi. `requests_repository.dart`dagi `joinRequest` bilan bir
  /// xil naqsh: ro'yxat va hisoblagich bitta yozuvda birga yangilanadi.
  Future<void> joinEvent({
    required String mahallaId,
    required String eventId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .update({
      'attendeeUids': FieldValue.arrayUnion([uid]),
      'participantsCount': FieldValue.increment(1),
    });
  }

  /// Qatnashishni bekor qiladi.
  Future<void> leaveEvent({
    required String mahallaId,
    required String eventId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .update({
      'attendeeUids': FieldValue.arrayRemove([uid]),
      'participantsCount': FieldValue.increment(-1),
    });
  }

  Stream<MahallaEvent?> watchEventById({
    required String mahallaId,
    required String eventId,
  }) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .doc(eventId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return MahallaEvent.fromFirestore(doc.id, doc.data()!);
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