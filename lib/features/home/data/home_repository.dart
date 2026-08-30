import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Foydalanuvchi roli — MVP bosqichida qo'lda (Firestore Console orqali)
/// belgilanadi. Kelajakda so'rov yuborish/tasdiqlash oqimi bilan
/// avtomatlashtiriladi.
/// `superAdmin` — ilova egasi/platforma darajasidagi rol. Har qanday
/// mahallada boshqaruv huquqiga ega va barcha mahallalarga bir vaqtda
/// e'lon/tadbir yubora oladi. Faqat Firebase Console orqali qo'lda
/// beriladi — ilova ichida hech qanday UI orqali bu rolga
/// ko'tarilib bo'lmaydi (`members_management_screen.dart`dagi rol
/// tanlash ro'yxati va Firestore Rules ikkalasi ham buni cheklaydi).
enum UserRole { citizen, staff, rais, superAdmin }

extension UserRoleX on UserRole {
  static UserRole fromString(String? value) {
    switch (value) {
      case 'staff':
        return UserRole.staff;
      case 'rais':
        return UserRole.rais;
      case 'superAdmin':
        return UserRole.superAdmin;
      default:
        return UserRole.citizen;
    }
  }

  /// Xodim, rais yoki super admin — ya'ni murojaatlarni boshqarish
  /// huquqiga ega.
  bool get canManageRequests =>
      this == UserRole.staff || this == UserRole.rais || this == UserRole.superAdmin;

  /// Xodim, rais yoki super admin — e'lon/tadbir joylashtirish huquqiga ega.
  bool get canPost =>
      this == UserRole.staff || this == UserRole.rais || this == UserRole.superAdmin;

  /// Rais yoki super admin — boshqa foydalanuvchilar rolini o'zgartira oladi.
  bool get canManageMembers => this == UserRole.rais || this == UserRole.superAdmin;

  /// Faqat super admin — istalgan mahallaga o'tish va barcha
  /// mahallalarga birdaniga e'lon/tadbir yuborish huquqiga ega.
  bool get isSuperAdmin => this == UserRole.superAdmin;

  String get storageValue {
    switch (this) {
      case UserRole.staff:
        return 'staff';
      case UserRole.rais:
        return 'rais';
      case UserRole.citizen:
        return 'citizen';
      case UserRole.superAdmin:
        return 'superAdmin';
    }
  }

  String get label {
    switch (this) {
      case UserRole.citizen:
        return "Fuqaro";
      case UserRole.staff:
        return 'Xodim';
      case UserRole.rais:
        return 'Rais';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }
}

/// Foydalanuvchi jinsi — ixtiyoriy, profilda ko'rsatish uchun.
enum UserGender { male, female }

extension UserGenderX on UserGender {
  static UserGender? fromString(String? value) {
    switch (value) {
      case 'male':
        return UserGender.male;
      case 'female':
        return UserGender.female;
      default:
        return null;
    }
  }

  String get storageValue => name;
}

/// Foydalanuvchi profilining qisqacha ko'rinishi (Home va Profil ekranlari uchun).
class UserProfile {
  final String firstName;
  final String lastName;
  final String phone;
  final String? mahallaId;
  final UserRole role;
  final String? staffTitle;
  final bool verifiedBadge;
  final String? photoUrl;
  final DateTime? birthDate;
  final String? address;
  final String? street;
  final String? houseNumber;
  final UserGender? gender;
  final bool phoneVisible;
  final bool lastSeenVisible;
  final List<String> blockedUids;

  /// Profil ekranidagi ism/rasm orqasida ko'rsatiladigan banner —
  /// `profile_banners.dart`dagi katalogdan bitta `id`.
  final String? profileBannerId;

  /// Premium holati shu muddatgacha amal qiladi. Hozircha haqiqiy
  /// to'lov ulanmagan — bu maydon faqat qo'lda (admin/Firestore
  /// konsoli, [PremiumRepository.grantManually]) o'rnatiladi.
  /// `null` — premium emas. Muddat tugagach avtomatik "premium emas"
  /// holatiga qaytadi — hech qanday qo'shimcha yozuv/tozalash shart
  /// emas, chunki tekshiruv har doim [isPremiumActive] orqali amalga
  /// oshadi.
  final DateTime? premiumUntil;

  bool get isPremiumActive =>
      premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  UserProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.mahallaId,
    required this.role,
    required this.staffTitle,
    required this.verifiedBadge,
    this.photoUrl,
    this.birthDate,
    this.address,
    this.street,
    this.houseNumber,
    this.gender,
    this.phoneVisible = false,
    this.lastSeenVisible = true,
    this.blockedUids = const [],
    this.profileBannerId,
    this.premiumUntil,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final birthTimestamp = data['birthDate'] as Timestamp?;
    final premiumTimestamp = data['premiumUntil'] as Timestamp?;
    return UserProfile(
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      mahallaId: data['mahallaId'],
      role: UserRoleX.fromString(data['role'] as String?),
      staffTitle: data['staffTitle'] as String?,
      verifiedBadge: data['verifiedBadge'] == true,
      photoUrl: data['photoUrl'] as String?,
      birthDate: birthTimestamp?.toDate(),
      address: data['address'] as String?,
      street: data['street'] as String?,
      houseNumber: data['houseNumber'] as String?,
      gender: UserGenderX.fromString(data['gender'] as String?),
      phoneVisible: data['phoneVisible'] == true,
      lastSeenVisible: data['lastSeenVisible'] != false,
      blockedUids: List<String>.from(data['blockedUids'] ?? const []),
      profileBannerId: data['profileBannerId'] as String?,
      premiumUntil: premiumTimestamp?.toDate(),
    );
  }

  /// Ko'cha va uy raqamini birlashtirib ko'rsatish uchun ("Bog'bon
  /// ko'chasi, 15"). Eski ma'lumotlar uchun (faqat `address` bo'lib,
  /// `street`/`houseNumber` bo'sh bo'lsa) eski maydonga tushadi.
  String? get displayAddress {
    final parts = [street, houseNumber]
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(', ');
    return address;
  }

  /// Faqat `mahallaId`ni almashtirilgan nusxasini qaytaradi — super
  /// admin `activeMahallaIdProvider` orqali boshqa mahallani "ko'rib
  /// chiqish" rejimiga o'tganda ishlatiladi. Butun ilova `profile.
  /// mahallaId`ni to'g'ridan-to'g'ri o'qiydi, shuning uchun bu yerda
  /// almashtirilishi ilovaning qolgan qismini o'zgartirmasdan barcha
  /// mahalla-ga bog'liq ekranlarni yangi mahallaga "shaffof" ravishda
  /// yo'naltiradi.
  UserProfile withMahallaId(String? mahallaId) {
    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      mahallaId: mahallaId,
      role: role,
      staffTitle: staffTitle,
      verifiedBadge: verifiedBadge,
      photoUrl: photoUrl,
      birthDate: birthDate,
      address: address,
      street: street,
      houseNumber: houseNumber,
      gender: gender,
      phoneVisible: phoneVisible,
      lastSeenVisible: lastSeenVisible,
      blockedUids: blockedUids,
      profileBannerId: profileBannerId,
      premiumUntil: premiumUntil,
    );
  }
}

/// Home ekranidagi "Yaqin tadbirlar" ro'yxati uchun qisqa model.
class UpcomingEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String location;

  UpcomingEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.location,
  });

  factory UpcomingEvent.fromFirestore(String id, Map<String, dynamic> data) {
    final timestamp = data['dateTime'] as Timestamp?;
    return UpcomingEvent(
      id: id,
      title: data['title'] ?? '',
      dateTime: timestamp?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
    );
  }
}

/// A'zolarni boshqarish ekranida ko'rsatiladigan qisqa profil —
/// UserProfile'dan farqli, uid'ni ham o'z ichiga oladi (chunki
/// ro'yxatdagi har bir a'zoni alohida tanib, rolini o'zgartirish
/// kerak bo'ladi).
class MahallaMember {
  final String uid;
  final String firstName;
  final String lastName;
  final String phone;
  final UserRole role;
  final String? photoUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final bool phoneVisible;
  final String? staffTitle;
  final String? street;

  /// Profil banneri tanlovi (`profile_banners.dart` katalogidagi id) —
  /// boshqa foydalanuvchi profilini ko'rganda ham egasining tanlagan
  /// banneri ko'rinishi uchun.
  final String? profileBannerId;

  /// [UserProfile.premiumUntil] bilan bir xil ma'noda — boshqa
  /// foydalanuvchi profilida ham premium nishoni ko'rinishi uchun.
  final DateTime? premiumUntil;

  bool get isPremiumActive =>
      premiumUntil != null && premiumUntil!.isAfter(DateTime.now());

  MahallaMember({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    this.photoUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.phoneVisible = false,
    this.staffTitle,
    this.street,
    this.profileBannerId,
    this.premiumUntil,
  });

  factory MahallaMember.fromFirestore(String uid, Map<String, dynamic> data) {
    final lastSeenTimestamp = data['lastSeenAt'] as Timestamp?;
    final premiumTimestamp = data['premiumUntil'] as Timestamp?;
    return MahallaMember(
      uid: uid,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRoleX.fromString(data['role'] as String?),
      staffTitle: data['staffTitle'] as String?,
      photoUrl: data['photoUrl'] as String?,
      isOnline: data['isOnline'] == true,
      lastSeenAt: lastSeenTimestamp?.toDate(),
      phoneVisible: data['phoneVisible'] == true,
      street: data['street'] as String?,
      profileBannerId: data['profileBannerId'] as String?,
      premiumUntil: premiumTimestamp?.toDate(),
    );
  }
}

class HomeRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Joriy sessiyada allaqachon "ta'minlangan" (marker mavjudligi
  /// tekshirilgan/yozilgan) `uid:mahallaId` juftliklari — har bir
  /// profil yangilanishida qayta yozib yubormaslik uchun.
  final Set<String> _ensuredMembershipMarkers = {};

  HomeRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Joriy foydalanuvchi profilini real vaqtda kuzatadi.
  ///
  /// Yo'l-yo'lakay `mahallas/{mahallaId}/members/{uid}` marker
  /// hujjatini ham "ta'minlaydi" (mavjud bo'lmasa yozadi) — bu ilova
  /// yangilanishidan oldin mahallaga qo'shilgan hisoblar uchun orqaga
  /// moslashtiruvchi (backfill) chora: marker mexanizmi joriy
  /// bo'lishidan oldin `attachUserToMahalla` marker yozmagan edi.
  Stream<UserProfile?> watchCurrentUserProfile() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      final profile = UserProfile.fromFirestore(doc.data()!);
      final mahallaId = profile.mahallaId;
      if (mahallaId != null) {
        unawaited(_ensureMembershipMarker(uid, mahallaId));
      }
      return profile;
    });
  }

  Future<void> _ensureMembershipMarker(String uid, String mahallaId) async {
    final key = '$uid:$mahallaId';
    if (_ensuredMembershipMarkers.contains(key)) return;
    _ensuredMembershipMarkers.add(key);
    try {
      await _firestore
          .collection('mahallas')
          .doc(mahallaId)
          .collection('members')
          .doc(uid)
          .set({'uid': uid}, SetOptions(merge: true));
    } catch (_) {
      // Muvaffaqiyatsiz bo'lsa keyingi profil yangilanishida qayta
      // urinib ko'rilsin deb, keshdan olib tashlaymiz.
      _ensuredMembershipMarkers.remove(key);
    }
  }

  /// Berilgan mahalladagi eng yaqin 3 ta tadbirni kuzatadi
  /// (bugungi va kelajakdagi sanalar bo'yicha, xronologik tartibda).
  Stream<List<UpcomingEvent>> watchUpcomingEvents(String mahallaId) {
    final now = Timestamp.fromDate(DateTime.now());

    return _firestore
        .collection('mahallas')
        .doc(mahallaId)
        .collection('events')
        .where('dateTime', isGreaterThanOrEqualTo: now)
        .orderBy('dateTime')
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UpcomingEvent.fromFirestore(doc.id, doc.data()))
            .toList());
  }

  /// Mahalla nomini bir martalik o'qiydi (Home ekranida ko'rsatish uchun).
  Future<String?> fetchMahallaName(String mahallaId) async {
    final doc = await _firestore.collection('mahallas').doc(mahallaId).get();
    return doc.data()?['name'] as String?;
  }

  /// Berilgan mahalladagi barcha a'zolarni real vaqtda kuzatadi —
  /// "Qo'shnilar", "A'zolarni boshqarish" va Asosiy sahifadagi xodimlar
  /// bo'limi uchun (bloklashdan mustasno — rais hammani ko'rishi kerak,
  /// bloklash filtri `watchNeighbors`da qo'llanadi).
  ///
  /// Nega to'g'ridan-to'g'ri `users` kolleksiyasini `where('mahallaId',
  /// ...)` bilan so'ramaymiz: Firestore "list" so'rovlari uchun
  /// qoidani natijalar to'plamining HAMMASI uchun oldindan isbotlashi
  /// kerak, va bu isbot `get()` orqali boshqa hujjatdan (bu yerda —
  /// so'rovchining o'z profilidan) olingan qiymatni ishlata olmaydi.
  /// Shuning uchun bunday so'rov har doim "Missing or insufficient
  /// permissions" bilan rad etilardi — hatto ma'lumot to'g'ri bo'lsa
  /// ham. Batafsili izoh: `firestore.rules`dagi `members` bo'limi.
  ///
  /// Yechim: avval `mahallas/{mahallaId}/members` marker kolleksiyasini
  /// (yo'lga asoslangan, xavfsiz "list" so'rovi) kuzatib UID'larni
  /// olamiz, so'ng har bir UID uchun **alohida** hujjat tinglovchisi
  /// ochamiz — yakka hujjat o'qishlari "list" cheklovidan mustasno va
  /// haqiqiy ma'lumot bilan tekshiriladi. Bu real vaqtli yangilanishni
  /// (masalan onlayn holat) saqlab qoladi.
  Stream<List<MahallaMember>> watchMahallaMembers(String mahallaId) {
    final membersCol =
        _firestore.collection('mahallas').doc(mahallaId).collection('members');

    late final StreamController<List<MahallaMember>> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? markerSub;
    final userSubs =
        <String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>{};
    final latest = <String, MahallaMember>{};

    void emit() {
      if (!controller.isClosed) controller.add(latest.values.toList());
    }

    void listenToUser(String uid) {
      userSubs[uid] = _firestore.collection('users').doc(uid).snapshots().listen(
        (doc) {
          final member =
              doc.exists ? MahallaMember.fromFirestore(doc.id, doc.data()!) : null;
          // Super admin — texnik hisob, mahalla a'zosi emas. U hech bir
          // ro'yxatda (Qo'shnilar, Mahalla xodimlari, A'zolarni
          // boshqarish) ko'rinmasligi kerak. Filtr aynan shu yerda
          // turibdi, chunki sanab o'tilgan barcha ro'yxatlar oxir-oqibat
          // shu oqimdan oziqlanadi.
          if (member == null || member.role.isSuperAdmin) {
            latest.remove(uid);
          } else {
            latest[uid] = member;
          }
          emit();
        },
      );
    }

    controller = StreamController<List<MahallaMember>>.broadcast(
      onListen: () {
        markerSub = membersCol.snapshots().listen((snapshot) {
          final uids = snapshot.docs.map((d) => d.id).toSet();

          for (final uid in userSubs.keys.toList()) {
            if (!uids.contains(uid)) {
              userSubs.remove(uid)?.cancel();
              latest.remove(uid);
            }
          }
          for (final uid in uids) {
            if (!userSubs.containsKey(uid)) listenToUser(uid);
          }
          emit();
        });
      },
      onCancel: () async {
        await markerSub?.cancel();
        for (final sub in userSubs.values) {
          await sub.cancel();
        }
        userSubs.clear();
        latest.clear();
      },
    );

    return controller.stream;
  }

  /// Qo'shnilar ro'yxati uchun — joriy foydalanuvchining o'zini va
  /// u bloklagan foydalanuvchilarni chiqarib tashlaydi.
  Stream<List<MahallaMember>> watchNeighbors(String mahallaId) {
    final myUid = _auth.currentUser?.uid;
    return watchCurrentUserProfile().asyncExpand((profile) {
      final blocked = profile?.blockedUids.toSet() ?? {};
      return watchMahallaMembers(mahallaId).map((members) => members
          .where((m) => m.uid != myUid && !blocked.contains(m.uid))
          .toList());
    });
  }

  /// Bir a'zoning rolini o'zgartiradi (faqat rais chaqirishi kerak —
  /// UI darajasida tekshiriladi, Firestore Rules bilan
  /// mustahkamlanishi SHART).
  Future<void> updateMemberRole({
    required String uid,
    required UserRole role,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'role': role.storageValue,
    });
  }

  /// Joriy foydalanuvchi telefon raqamini boshqa qo'shnilarga
  /// ko'rsatish/yashirish sozlamasini o'zgartiradi.
  Future<void> setPhoneVisible(bool visible) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'phoneVisible': visible,
    });
  }

  /// Joriy foydalanuvchining "oxirgi marta ko'rilgan/onlayn" holatini
  /// boshqalarga ko'rsatish/yashirish sozlamasi.
  Future<void> setLastSeenVisible(bool visible) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'lastSeenVisible': visible,
    });
  }

  /// Berilgan foydalanuvchini bloklaydi — bloklangan foydalanuvchi
  /// Qo'shnilar ro'yxatida ko'rinmaydi va (kelajakda) sizga xabar
  /// yoza olmaydi.
  Future<void> blockUser(String uidToBlock) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'blockedUids': FieldValue.arrayUnion([uidToBlock]),
    });
  }

  /// Bloklashni bekor qiladi.
  Future<void> unblockUser(String uidToUnblock) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).update({
      'blockedUids': FieldValue.arrayRemove([uidToUnblock]),
    });
  }

  /// Bloklangan foydalanuvchilarning to'liq profillarini (ism, rasm
  /// ko'rsatish uchun) bir martalik o'qiydi.
  /// Berilgan UID'lar ro'yxati bo'yicha foydalanuvchi hujjatlarini
  /// o'qiydi (bloklangan foydalanuvchilar ekrani uchun).
  ///
  /// `.where(FieldPath.documentId, whereIn: uids)` — bu ham "list"
  /// so'rovi, va `users`dagi o'qish qoidasi (`get()`ga bog'liq)
  /// buni butun to'plam uchun isbotlay olmaydi (xuddi
  /// `watchMahallaMembers`dagi kabi — izoh o'sha yerda). Shuning
  /// uchun har bir UID uchun **alohida** hujjat o'qiladi — yakka
  /// o'qishlar bu cheklovdan mustasno.
  Future<List<MahallaMember>> fetchMembersByUids(List<String> uids) async {
    if (uids.isEmpty) return [];
    final docs = await Future.wait(
      uids.map((uid) => _firestore.collection('users').doc(uid).get()),
    );
    return docs
        .where((doc) => doc.exists)
        .map((doc) => MahallaMember.fromFirestore(doc.id, doc.data()!))
        .toList();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository();
});

/// Firebase Auth holatini kuzatadi — `currentUserProfileProvider`
/// shu providerni "watch" qilib, foydalanuvchi almashganda (chiqish +
/// boshqa akkauntga kirish, bitta ilova sessiyasi ichida) profilni
/// qaytadan yuklashini ta'minlaydi.
///
/// MUHIM: `HomeRepository.watchCurrentUserProfile()` ichida
/// `_auth.currentUser?.uid` faqat funksiya CHAQIRILGAN paytda bir
/// marta o'qiladi — agar `currentUserProfileProvider` faqat shu
/// funksiyaning natijasini kuzatsa (auth holatini emas), birinchi
/// akkaunt bilan yaratilgan Stream keyingi akkauntlar uchun HECH
/// QACHON qayta yaratilmaydi (Riverpod providerlari auth holatidan
/// mustaqil, faqat o'zlari watch qilgan narsalar o'zgarganda qayta
/// quriladi). Natijada: boshqa akkauntga kirilganda profil ekrani
/// "Ma'lumotlarni yuklashda xatolik" bilan qolib ketardi — chunki
/// eski uid bo'yicha Firestore tinglovchisi yangi foydalanuvchi
/// uchun ruxsatsiz (PERMISSION_DENIED) bo'lib qolgan, lekin hech
/// qachon yangilanmagan edi.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Super admin qaysi mahallani "ko'rib chiqish/boshqarish" rejimida
/// ekanini saqlaydi (`null` — hech qaysi mahalla tanlanmagan, o'zining
/// haqiqiy mahallasi — odatda `null`da qoladi — ko'rsatiladi). Faqat
/// `UserRole.superAdmin` uchun mantiqiy; boshqa foydalanuvchilar uchun
/// hech qanday ta'sir qilmaydi.
final activeMahallaOverrideProvider = StateProvider<String?>((ref) => null);

/// Ilovaning qolgan qismi ishlatadigan asosiy profil provideri.
/// Super admin uchun `activeMahallaOverrideProvider` o'rnatilgan
/// bo'lsa, profil shu mahallaga "ko'rsatilgan" holatda qaytariladi —
/// shu orqali mavjud barcha mahalla-ga bog'liq ekranlar (E'lonlar,
/// Murojaatlar, Qo'shnilar va h.k.) hech qanday o'zgarishsiz to'g'ri
/// mahallani ko'rsatadi, super admin har safar tizimga qayta
/// kirmasdan. Hali ham haqiqiy `StreamProvider` — `.future`/`.stream`
/// orqali foydalanadigan joylar buzilmaydi.
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  // Faqat qayta qurilishga majburlash uchun — natijasi ishlatilmaydi,
  // lekin `ref.watch` shu providerga obuna bo'lib, u o'zgarganda
  // (login/logout/akkaunt almashish) butun bu providerni qayta
  // ishga tushiradi.
  ref.watch(authStateProvider);
  final override = ref.watch(activeMahallaOverrideProvider);
  return ref
      .watch(homeRepositoryProvider)
      .watchCurrentUserProfile()
      .map((profile) {
    if (profile == null || override == null || !profile.role.isSuperAdmin) {
      return profile;
    }
    return profile.withMahallaId(override);
  });
});

/// mahallaId aniq bo'lgandagina tadbirlarni kuzatadi;
/// aks holda bo'sh ro'yxat qaytaradi.
final upcomingEventsProvider =
    StreamProvider.autoDispose<List<UpcomingEvent>>((ref) {
  final profileAsync = ref.watch(currentUserProfileProvider);

  return profileAsync.when(
    data: (profile) {
      final mahallaId = profile?.mahallaId;
      if (mahallaId == null) return Stream.value([]);
      return ref.watch(homeRepositoryProvider).watchUpcomingEvents(mahallaId);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Joriy foydalanuvchining mahalla nomini qaytaradi (Home ekranida
/// "Assalomu alaykum" ostida ko'rsatish uchun).
final currentMahallaNameProvider =
    FutureProvider.autoDispose<String?>((ref) async {
  final profile = await ref.watch(currentUserProfileProvider.future);
  final mahallaId = profile?.mahallaId;
  if (mahallaId == null || mahallaId.isEmpty) return null;
  return ref.watch(homeRepositoryProvider).fetchMahallaName(mahallaId);
});

final mahallaMembersProvider =
    StreamProvider.autoDispose.family<List<MahallaMember>, String>(
        (ref, mahallaId) {
  return ref.watch(homeRepositoryProvider).watchMahallaMembers(mahallaId);
});

/// Qo'shnilar ekrani uchun — o'zini va bloklaganlarni chiqarib
/// tashlagan holda.
final neighborsProvider =
    StreamProvider.autoDispose.family<List<MahallaMember>, String>(
        (ref, mahallaId) {
  return ref.watch(homeRepositoryProvider).watchNeighbors(mahallaId);
});

/// Home ekranida ko'rsatiladigan mahalla xodimlari (staff/rais) —
/// statistika kartochkalari o'rniga, aholi kim bilan bog'lanishi
/// mumkinligini bevosita ko'rsatish uchun.
final staffMembersProvider =
    StreamProvider.autoDispose.family<List<MahallaMember>, String>(
        (ref, mahallaId) {
  return ref
      .watch(homeRepositoryProvider)
      .watchMahallaMembers(mahallaId)
      .map((members) =>
          members.where((m) => m.role != UserRole.citizen).toList());
});

/// Home ekranidagi "So'nggi faoliyat" ro'yxati uchun bitta umumiy tur —
/// e'lon, murojaat va tadbirlarni bitta xronologik ro'yxatga birlashtirish
/// uchun ishlatiladi.
enum ActivityKind { announcement, request, event }

class ActivityItem {
  final ActivityKind kind;
  final String title;
  final DateTime createdAt;

  ActivityItem({
    required this.kind,
    required this.title,
    required this.createdAt,
  });
}