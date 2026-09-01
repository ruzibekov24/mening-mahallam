import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../../premium/data/premium_repository.dart';

/// Murojaat holati — mockupdagi 3 ta tab bilan mos.
enum RequestStatus { yangi, jarayonda, yakunlandi }

extension RequestStatusX on RequestStatus {
  String get label {
    switch (this) {
      case RequestStatus.yangi:
        return 'Yangi';
      case RequestStatus.jarayonda:
        return 'Jarayonda';
      case RequestStatus.yakunlandi:
        return 'Yakunlandi';
    }
  }

  static RequestStatus fromString(String value) {
    switch (value) {
      case 'jarayonda':
        return RequestStatus.jarayonda;
      case 'yakunlandi':
        return RequestStatus.yakunlandi;
      default:
        return RequestStatus.yangi;
    }
  }

  String get firestoreValue {
    switch (this) {
      case RequestStatus.yangi:
        return 'yangi';
      case RequestStatus.jarayonda:
        return 'jarayonda';
      case RequestStatus.yakunlandi:
        return 'yakunlandi';
    }
  }
}

/// Murojaat turi — maxfiy (faqat egasi va rais ko'radi) yoki
/// ommaviy (mahalladagi hamma ko'radi va qo'shilishi mumkin).
enum RequestType { maxfiy, ommaviy }

extension RequestTypeX on RequestType {
  String get label {
    switch (this) {
      case RequestType.maxfiy:
        return 'Maxfiy';
      case RequestType.ommaviy:
        return 'Ommaviy';
    }
  }

  String get description {
    switch (this) {
      case RequestType.maxfiy:
        return 'Faqat siz va mahalla raisi ko\'radi';
      case RequestType.ommaviy:
        return 'Mahalladagi hamma ko\'radi va qo\'shilishi mumkin';
    }
  }

  static RequestType fromString(String value) {
    return value == 'ommaviy' ? RequestType.ommaviy : RequestType.maxfiy;
  }

  String get firestoreValue => this == RequestType.ommaviy ? 'ommaviy' : 'maxfiy';
}

/// Muhimlik darajasi.
enum RequestPriority { past, ortacha, yuqori }

extension RequestPriorityX on RequestPriority {
  String get label {
    switch (this) {
      case RequestPriority.past:
        return 'Past';
      case RequestPriority.ortacha:
        return 'O\'rtacha';
      case RequestPriority.yuqori:
        return 'Yuqori';
    }
  }

  static RequestPriority fromString(String value) {
    switch (value) {
      case 'yuqori':
        return RequestPriority.yuqori;
      case 'past':
        return RequestPriority.past;
      default:
        return RequestPriority.ortacha;
    }
  }

  String get firestoreValue {
    switch (this) {
      case RequestPriority.past:
        return 'past';
      case RequestPriority.ortacha:
        return 'ortacha';
      case RequestPriority.yuqori:
        return 'yuqori';
    }
  }
}

/// Bitta murojaat hujjati.
class MahallaRequest {
  final String id;
  final String title;
  final String description;
  final RequestStatus status;
  final RequestType type;
  final RequestPriority priority;
  final int joinedCount;
  final List<String> joinedUids;
  final DateTime createdAt;
  final String authorUid;
  final List<String> imageUrls;
  final double? latitude;
  final double? longitude;

  /// Murojaat YARATILGAN paytda muallif premium bo'lganmi.
  ///
  /// Ataylab murojaatning o'ziga yozib qo'yiladi (muallif profilidan
  /// har safar o'qilmaydi): obuna keyin tugasa ham, o'sha paytda
  /// to'langan ustuvorlik saqlanib qoladi va ro'yxat tartibi
  /// kutilmaganda o'zgarib ketmaydi.
  final bool authorWasPremium;

  /// Murojaat biriktirilgan xodim/rais'ning uid'i — `null` bo'lsa hech
  /// kimga biriktirilmagan.
  final String? assignedToUid;

  /// Murojaatni bajarish muddati (SLA) — faqat xodim/rais belgilaydi,
  /// ixtiyoriy.
  final DateTime? dueAt;

  /// "Muddati o'tdi" bildirishnomasi allaqachon yuborilgan bo'lsa,
  /// qachon yuborilgani — har safar ekran ochilganda qayta
  /// yubormaslik uchun.
  final DateTime? overdueNotifiedAt;

  MahallaRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.type,
    required this.priority,
    required this.joinedCount,
    required this.joinedUids,
    required this.createdAt,
    required this.authorUid,
    required this.imageUrls,
    this.latitude,
    this.longitude,
    this.authorWasPremium = false,
    this.assignedToUid,
    this.dueAt,
    this.overdueNotifiedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;

  /// Muddat o'tib ketgan va murojaat hali yakunlanmaganmi — vizual
  /// "overdue" signal va bildirishnoma trigger'i uchun.
  bool get isOverdue =>
      dueAt != null &&
      status != RequestStatus.yakunlandi &&
      dueAt!.isBefore(DateTime.now());

  /// [description] endi Quill Delta JSON saqlaydi (rich text).
  /// Ro'yxat ko'rinishidagi qisqa preview uchun formatlashsiz
  /// oddiy matnga aylantiradi. Eski (Delta bo'lmagan) yozuvlar
  /// uchun o'zini o'zgarishsiz qaytaradi.
  String get plainTextDescription {
    try {
      final decoded = jsonDecode(description);
      if (decoded is! List) return description;
      final doc = quill.Document.fromJson(decoded);
      return doc.toPlainText().trim();
    } catch (_) {
      return description;
    }
  }

  factory MahallaRequest.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return MahallaRequest(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: RequestStatusX.fromString(data['status'] ?? 'yangi'),
      type: RequestTypeX.fromString(data['type'] ?? 'maxfiy'),
      priority: RequestPriorityX.fromString(data['priority'] ?? 'ortacha'),
      joinedCount: (data['joinedCount'] ?? 0) as int,
      joinedUids: (data['joinedUids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: timestamp?.toDate() ?? DateTime.now(),
      authorUid: data['authorUid'] ?? '',
      imageUrls: (data['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      authorWasPremium: data['authorWasPremium'] == true,
      assignedToUid: data['assignedToUid'] as String?,
      dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
      overdueNotifiedAt: (data['overdueNotifiedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Bitta murojaat komentariyasi — `mahallas/{mahallaId}/requests/{requestId}/comments`
/// sub-kolleksiyasida saqlanadi.
class RequestComment {
  final String id;
  final String authorUid;
  final String text;
  final DateTime createdAt;

  RequestComment({
    required this.id,
    required this.authorUid,
    required this.text,
    required this.createdAt,
  });

  factory RequestComment.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['createdAt'] as Timestamp?;
    return RequestComment(
      id: id,
      authorUid: data['authorUid'] ?? '',
      text: data['text'] ?? '',
      createdAt: timestamp?.toDate() ?? DateTime.now(),
    );
  }
}

class RequestsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final PremiumRepository _premium;

  RequestsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    PremiumRepository? premium,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _premium = premium ?? PremiumRepository();

  /// Berilgan mahalladagi BARCHA murojaatlarni (maxfiy va ommaviy,
  /// eng yangisidan eng eskisiga qarab) real vaqtda kuzatadi.
  ///
  /// **Faqat xodim/rais chaqirishi kerak.** Oddiy fuqaro uchun bu
  /// so'rov Firestore Security Rules tomonidan rad etiladi — chunki
  /// bu yerda `.where()` filtri yo'q, qoida esa har bir hujjat uchun
  /// (masalan `type == 'ommaviy'`) shart qo'yadi, va Firestore "list"
  /// so'rovlarini faqat mos filtr bilan isbotlay oladi (`isMemberOf`
  /// singari faqat `get()`ga bog'liq, resurs-mustaqil shartlar bundan
  /// mustasno — ular butun so'rov uchun bir marta hisoblanadi). Oddiy
  /// fuqaro uchun `watchVisibleRequests`dan foydalaning.
  Stream<List<MahallaRequest>> watchRequests(String mahallaId) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => sortWithPremiumFirst(snapshot.docs
            .map((doc) => MahallaRequest.fromFirestore(doc.id, doc.data()))
            .toList()));
  }

  /// Premium mualliflarning murojaatlarini ro'yxat boshiga chiqaradi,
  /// har bir guruh ichida esa yangilikdan eskiga tartib saqlanadi.
  ///
  /// Saralash Firestore'da emas, klient tomonida qilinadi: `orderBy`
  /// bo'yicha ikkita maydonga tartiblash uchun Firestore kompozit
  /// indeks talab qiladi, bu esa faqat ko'rinish tartibi uchun ortiqcha
  /// murakkablik bo'lardi (bitta mahalladagi murojaatlar soni kichik).
  static List<MahallaRequest> sortWithPremiumFirst(
      List<MahallaRequest> items) {
    final sorted = [...items];
    sorted.sort((a, b) {
      if (a.authorWasPremium != b.authorWasPremium) {
        return a.authorWasPremium ? -1 : 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return sorted;
  }

  /// Oddiy fuqaro ko'rishi mumkin bo'lgan murojaatlar: ommaviy
  /// (`type == 'ommaviy'`) yoki o'zi yozgan (maxfiy bo'lsa ham).
  ///
  /// Bu ikkita alohida, xavfsizlik qoidasiga **aynan mos** so'rovni
  /// (bittasi `type`, bittasi `authorUid` bo'yicha) birlashtirib real
  /// vaqtda kuzatadi — yagona `.where()`siz so'rov (`watchRequests`)
  /// oddiy fuqaro uchun har doim "Missing or insufficient permissions"
  /// bilan rad etilardi, garchi u faqat o'ziga ruxsat berilgan
  /// hujjatlarni ko'rmoqchi bo'lsa ham (batafsili: `firestore.rules`
  /// dagi `requests` bo'limi).
  Stream<List<MahallaRequest>> watchVisibleRequests(
    String mahallaId,
    String myUid,
  ) {
    final requestsCol =
        _firestore.collection('mahallas').doc(mahallaId).collection('requests');

    late final StreamController<List<MahallaRequest>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? publicSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? mineSub;
    var publicList = <MahallaRequest>[];
    var mineList = <MahallaRequest>[];

    void emit() {
      if (controller.isClosed) return;
      final merged = <String, MahallaRequest>{};
      for (final r in publicList) {
        merged[r.id] = r;
      }
      for (final r in mineList) {
        merged[r.id] = r;
      }
      controller.add(sortWithPremiumFirst(merged.values.toList()));
    }

    controller = StreamController<List<MahallaRequest>>.broadcast(
      onListen: () {
        publicSub = requestsCol
            .where('type', isEqualTo: 'ommaviy')
            .snapshots()
            .listen(
          (snapshot) {
            publicList = snapshot.docs
                .map((doc) => MahallaRequest.fromFirestore(doc.id, doc.data()))
                .toList();
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
        );
        mineSub = requestsCol
            .where('authorUid', isEqualTo: myUid)
            .snapshots()
            .listen(
          (snapshot) {
            mineList = snapshot.docs
                .map((doc) => MahallaRequest.fromFirestore(doc.id, doc.data()))
                .toList();
            emit();
          },
          onError: (Object error, StackTrace stackTrace) {
            if (!controller.isClosed) controller.addError(error, stackTrace);
          },
        );
      },
      onCancel: () async {
        await publicSub?.cancel();
        await mineSub?.cancel();
      },
    );

    return controller.stream;
  }

  /// Yangi murojaat yaratadi, holati avtomatik "yangi" bo'ladi.
  Future<void> createRequest({
    required String mahallaId,
    required String title,
    required String description,
    required RequestType type,
    required RequestPriority priority,
    List<String> imageUrls = const [],
    double? latitude,
    double? longitude,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }

    // Bepul foydalanuvchilar uchun kunlik murojaat limiti — premium
    // foydalanuvchilarda cheklov yo'q. `users/{uid}`ni to'g'ridan-to'g'ri
    // o'qiymiz (UserProfile'ning to'liq stream'ini kutish o'rniga),
    // chunki bu yerda faqat bitta maydon kerak.
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final premiumTimestamp = userDoc.data()?['premiumUntil'] as Timestamp?;
    final isPremiumActive =
        premiumTimestamp != null && premiumTimestamp.toDate().isAfter(DateTime.now());
    if (!isPremiumActive) {
      final todayCount = await _premium.countRequestsCreatedToday(
        mahallaId: mahallaId,
        uid: uid,
      );
      if (todayCount >= PremiumRepository.freeDailyRequestLimit) {
        throw const DailyRequestLimitReachedException(
          PremiumRepository.freeDailyRequestLimit,
        );
      }
    }

    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .add({
      'title': title,
      'description': description,
      'status': RequestStatus.yangi.firestoreValue,
      'type': type.firestoreValue,
      'priority': priority.firestoreValue,
      'joinedCount': 0,
      'joinedUids': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'authorUid': uid,
      'imageUrls': imageUrls,
      'authorWasPremium': isPremiumActive,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    });
  }

  /// Murojaat holatini o'zgartiradi (faqat xodim/rais uchun —
  /// UI darajasida tekshiriladi, Firestore Rules bilan mustahkamlanadi).
  /// [authorUid] va [requestTitle] berilsa, murojaat egasiga holat
  /// o'zgargani haqida bildirishnoma yuboriladi.
  Future<void> updateRequestStatus({
    required String mahallaId,
    required String requestId,
    required RequestStatus newStatus,
    String? authorUid,
    String? requestTitle,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .update({'status': newStatus.firestoreValue});

    final myUid = _auth.currentUser?.uid;
    if (authorUid != null && authorUid != myUid) {
      await NotificationRepository().sendToUser(
        uid: authorUid,
        type: NotificationType.requestStatusChanged,
        title: 'Murojaat holati yangilandi',
        body: requestTitle != null
            ? '"$requestTitle" — ${newStatus.label}'
            : 'Sizning murojaatingiz holati "${newStatus.label}" ga o\'zgardi',
        relatedId: requestId,
      );
    }
  }

  /// Murojaatni o'chiradi — muallif yoki xodim/rais chaqirishi mumkin
  /// (UI darajasida tekshiriladi, Firestore Rules bilan mustahkamlangan).
  Future<void> deleteRequest({
    required String mahallaId,
    required String requestId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .delete();
  }

  /// Murojaatni xodim/rais'ga biriktiradi (yoki [staffUid] `null` bo'lsa
  /// biriktirishni bekor qiladi). Faqat xodim/rais/super admin
  /// chaqirishi kerak (UI darajasida tekshiriladi, Firestore Rules
  /// bilan mustahkamlanadi).
  Future<void> assignRequest({
    required String mahallaId,
    required String requestId,
    required String? staffUid,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .update({'assignedToUid': staffUid});
  }

  /// Murojaatning bajarish muddatini (SLA) belgilaydi yoki [dueAt]
  /// `null` bo'lsa bekor qiladi. Faqat xodim/rais/super admin
  /// chaqirishi kerak.
  Future<void> setRequestDueDate({
    required String mahallaId,
    required String requestId,
    required DateTime? dueAt,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .update({
      'dueAt': dueAt == null ? FieldValue.delete() : Timestamp.fromDate(dueAt),
    });
  }

  /// Muddati o'tgani haqida bildirishnoma yuborilgani belgilanadi —
  /// har safar ekran ochilganda qayta yuborilmasligi uchun. Bir vaqtda
  /// bir nechta ekran shu tekshiruvni bajarishi mumkin bo'lgani uchun
  /// bu yerda tranzaksiya ishlatilmaydi: eng yomon holatda bir nechta
  /// bildirishnoma yuborilishi mumkin, bu qabul qilinadigan xavf.
  Future<void> markOverdueNotified({
    required String mahallaId,
    required String requestId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .update({'overdueNotifiedAt': FieldValue.serverTimestamp()});
  }

  /// Muddati o'tgan, hali yakunlanmagan va biriktirilgan murojaatni
  /// tekshiradi — agar hali bildirishnoma yuborilmagan bo'lsa,
  /// biriktirilgan xodimga "muddati o'tdi" bildirishnomasini yuboradi
  /// va [overdueNotifiedAt]ni belgilaydi. Ekran ochilganda
  /// (`request_detail_screen.dart` / `requests_management_screen.dart`)
  /// imkoniyat sifatida chaqiriladi — alohida fon/cron jarayoni yo'q.
  Future<void> checkAndNotifyOverdue(
    String mahallaId,
    MahallaRequest request,
  ) async {
    if (!request.isOverdue) return;
    if (request.assignedToUid == null) return;
    if (request.overdueNotifiedAt != null) return;

    await markOverdueNotified(mahallaId: mahallaId, requestId: request.id);
    await NotificationRepository().sendToUser(
      uid: request.assignedToUid!,
      type: NotificationType.requestOverdue,
      title: 'Murojaat muddati o\'tdi',
      body: '"${request.title}" — bajarish muddati o\'tib ketdi',
      relatedId: request.id,
    );
  }

  /// Bitta murojaatni ID bo'yicha real vaqtda kuzatadi — tafsilotlar
  /// ekranida holat/qo'shilganlar soni jonli yangilanib turishi uchun.
  Stream<MahallaRequest?> watchRequestById({
    required String mahallaId,
    required String requestId,
  }) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return MahallaRequest.fromFirestore(doc.id, doc.data()!);
    });
  }

  /// Ommaviy murojaatga "qo'shilish" — foydalanuvchi shu muammoni
  /// o'zi ham boshdan kechirayotganini bildiradi.
  Future<void> joinRequest({
    required String mahallaId,
    required String requestId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId);
    await ref.update({
      'joinedUids': FieldValue.arrayUnion([uid]),
      'joinedCount': FieldValue.increment(1),
    });
  }

  /// Qo'shilishni bekor qiladi.
  Future<void> leaveRequest({
    required String mahallaId,
    required String requestId,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final ref = _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId);
    await ref.update({
      'joinedUids': FieldValue.arrayRemove([uid]),
      'joinedCount': FieldValue.increment(-1),
    });
  }

  /// Murojaat ostidagi komentariyalarni eng eskisidan boshlab kuzatadi.
  /// Ko'rish huquqi — murojaatning o'zini ko'ra oladigan har kim
  /// (maxfiy/ommaviy qoidasi bilan bir xil, Firestore Rules'da
  /// mustahkamlangan).
  Stream<List<RequestComment>> watchComments({
    required String mahallaId,
    required String requestId,
  }) {
    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RequestComment.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Yangi komentariya qo'shadi — muallif doim joriy foydalanuvchi.
  Future<void> addComment({
    required String mahallaId,
    required String requestId,
    required String text,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Foydalanuvchi tizimga kirmagan');
    }
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .collection('comments')
        .add({
      'authorUid': uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// O'z komentariyasini o'chiradi — faqat muallifning o'zi chaqirishi
  /// mumkin (Firestore Rules bilan mustahkamlangan: `resource.data.
  /// authorUid == myUid()`).
  Future<void> deleteComment({
    required String mahallaId,
    required String requestId,
    required String commentId,
  }) async {
    await _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('requests')
        .doc(requestId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }

  /// Berilgan murojaatga o'xshash — bir xil mahalla va turdagi (`type`)
  /// boshqa murojaatlarni bir martalik so'rov bilan oladi (tafsilotlar
  /// ekranida ko'rsatish uchun, real vaqtda kuzatish shart emas).
  /// Joriy murojaatning o'zi natijadan chiqarib tashlanadi.
  ///
  /// `maxfiy` turi uchun qo'shimcha `authorUid == myUid()` filtri
  /// qo'shiladi — aks holda Firestore Rules butun so'rovni rad etardi
  /// (oddiy a'zo faqat o'zi yozgan maxfiy murojaatlarni ko'ra oladi,
  /// batafsili: `firestore.rules`dagi `requests` bo'limi va
  /// `watchVisibleRequests`dagi izoh). Xodim/rais uchun bu cheklov
  /// qo'llanilmaydi — ularning ruxsati resursdan mustaqil.
  Future<List<MahallaRequest>> fetchSimilarRequests({
    required String mahallaId,
    required String requestId,
    required RequestType type,
    int limit = 5,
  }) async {
    final requestsCol =
        _firestore.collection('mahallas').doc(mahallaId).collection('requests');
    final myUid = _auth.currentUser?.uid;

    Query<Map<String, dynamic>> query =
        requestsCol.where('type', isEqualTo: type.firestoreValue);
    if (type == RequestType.maxfiy && myUid != null) {
      query = query.where('authorUid', isEqualTo: myUid);
    }

    final snapshot = await query.get();
    final items = snapshot.docs
        .map((doc) => MahallaRequest.fromFirestore(doc.id, doc.data()))
        .where((r) => r.id != requestId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }
}

final requestsRepositoryProvider = Provider<RequestsRepository>((ref) {
  return RequestsRepository();
});

/// Joriy foydalanuvchining mahallaId'siga bog'liq holda
/// murojaatlar ro'yxatini kuzatadi.
final requestsProvider =
    StreamProvider.autoDispose.family<List<MahallaRequest>, String>(
  (ref, mahallaId) {
    return ref.watch(requestsRepositoryProvider).watchRequests(mahallaId);
  },
);

/// Joriy foydalanuvchi ko'rishi kerak bo'lgan murojaatlar:
/// - Oddiy fuqaro uchun: FAQAT o'zi yozgan (maxfiy+ommaviy) va boshqalarning
///   OMMAVIY murojaatlari (boshqalarning maxfiylari ko'rinmaydi) —
///   `watchVisibleRequests` orqali, bu server (Firestore Rules) darajasida
///   ham mustahkamlangan.
/// - Xodim/rais uchun: mahalladagi BARCHA murojaatlar (Boshqaruv panelida
///   allRequestsForManagementProvider orqali alohida ko'riladi, lekin
///   bu yerda ham cheklovsiz ko'rsatiladi — chunki ular ko'rishga haqli).
final myRequestsProvider =
    StreamProvider.autoDispose<List<MahallaRequest>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final canSeeAll = profile?.role.canManageRequests == true;
      final repo = ref.watch(requestsRepositoryProvider);

      if (canSeeAll) return repo.watchRequests(mahallaId);
      if (currentUid == null) return Stream.value([]);
      return repo.watchVisibleRequests(mahallaId, currentUid);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Boshqaruv paneli uchun — mahalladagi BARCHA murojaatlarni (maxfiy va
/// ommaviy, hamma foydalanuvchilardan) cheklovsiz kuzatadi. Faqat
/// xodim/rais ekranidan chaqirilishi kerak.
final allRequestsForManagementProvider =
    StreamProvider.autoDispose<List<MahallaRequest>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null || mahallaId.isEmpty) return Stream.value([]);
      return ref.watch(requestsRepositoryProvider).watchRequests(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Bitta murojaat ostidagi komentariyalarni kuzatadi. Parametr —
/// `mahallaId:requestId` shaklidagi birlashtirilgan kalit (Riverpod
/// family bitta primitiv qiymat talab qiladi, record ishlatmaslik
/// uchun oddiyroq yechim — bu kodda boshqa joyda ham shu naqsh
/// ishlatiladi).
final requestCommentsProvider =
    StreamProvider.autoDispose.family<List<RequestComment>, String>(
  (ref, compositeKey) {
    final parts = compositeKey.split(':');
    final mahallaId = parts.first;
    final requestId = parts.length > 1 ? parts.sublist(1).join(':') : '';
    return ref
        .watch(requestsRepositoryProvider)
        .watchComments(mahallaId: mahallaId, requestId: requestId);
  },
);

/// Bitta murojaatga o'xshash boshqa murojaatlarni oladi. Parametr —
/// `mahallaId:requestId:type` shaklidagi birlashtirilgan kalit (boshqa
/// `family` providerlar bilan bir xil naqsh — record o'rniga oddiy
/// string, chunki mahallaId/requestId Firestore doc ID'lari ':' belgisini
/// o'z ichiga olmaydi).
final similarRequestsProvider =
    FutureProvider.autoDispose.family<List<MahallaRequest>, String>(
  (ref, compositeKey) {
    final parts = compositeKey.split(':');
    final mahallaId = parts[0];
    final requestId = parts[1];
    final type = RequestTypeX.fromString(parts[2]);
    return ref.watch(requestsRepositoryProvider).fetchSimilarRequests(
          mahallaId: mahallaId,
          requestId: requestId,
          type: type,
        );
  },
);