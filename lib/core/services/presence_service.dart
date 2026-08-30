import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Foydalanuvchining online/offline holatini ishonchli kuzatadi.
///
/// Oddiy "ilova fonga tushdi = offline" mantig'i ilova to'satdan
/// yopilganda (crash, majburiy o'chirish, quvvat tugashi) ishlamay
/// qoladi — foydalanuvchi abadiy "online" bo'lib qolaveradi.
///
/// Buning o'rniga Firebase Realtime Database'ning `onDisconnect()`
/// funksiyasidan foydalanamiz: bu SERVER tomonida ishlaydi — ilova
/// internetdan qanday uzilishidan qat'iy nazar (hatto qurilma
/// o'chib qolsa ham), RTDB avtomatik ravishda holatni "offline"ga
/// o'zgartiradi. Shu bilan bir vaqtda Firestore'dagi `users/{uid}`
/// hujjatidagi `isOnline`/`lastSeenAt` maydonlari ham RTDB bilan
/// sinxronlanadi, chunki Qo'shnilar ekrani Firestore'dan o'qiydi.
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://mahallam-d4a93-default-rtdb.firebaseio.com/',
  );
  StreamSubscription<DatabaseEvent>? _connectionSub;
  Timer? _heartbeatTimer;

  /// Foydalanuvchi tizimga kirgach chaqiriladi. RTDB `.info/connected`
  /// signalini kuzatib, ulanish tiklangan har safar `onDisconnect()`ni
  /// qayta o'rnatadi (RTDB ulanish uzilib-qaytganda oldingi
  /// onDisconnect buyrug'i bekor bo'lishi mumkin, shuning uchun
  /// qayta o'rnatish shart).
  void start() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final statusRef = _rtdb.ref('status/$uid');
    final connectedRef = _rtdb.ref('.info/connected');

    _connectionSub?.cancel();
    _connectionSub = connectedRef.onValue.listen((event) async {
      final connected = event.snapshot.value == true;
      if (!connected) return;

      // Ulanish uzilganda (yoki ilova to'satdan yopilganda) RTDB
      // server o'zi shu qiymatni yozadi — bizning kodimiz ishtirok
      // etmasa ham ishlaydi.
      await statusRef.onDisconnect().set({
        'online': false,
        'lastSeenAt': ServerValue.timestamp,
      });

      // Hozir ulanganimiz uchun online deb belgilaymiz.
      await statusRef.set({
        'online': true,
        'lastSeenAt': ServerValue.timestamp,
      });
    });

    // RTDB'dagi holatni Firestore'ga sinxronlab turamiz — Qo'shnilar
    // ekrani hamon Firestore'dan o'qiydi, kod boshqa joyda
    // o'zgarmaydi.
    statusRef.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data is! Map) return;
      final isOnline = data['online'] == true;
      _syncToFirestore(uid, isOnline);
    });

    // Ehtiyot chorasi: har 2 daqiqada "lastSeenAt"ni yangilab turamiz
    // — ilova old planda turgan holatda ham vaqt yangi bo'lib tursin
    // (masalan, RTDB signali biror sababdan kechiksa).
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      statusRef.update({'lastSeenAt': ServerValue.timestamp});
    });
  }

  Future<void> _syncToFirestore(String uid, bool isOnline) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isOnline': isOnline,
        'lastSeenAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Foydalanuvchi hujjati hali yaratilmagan yoki tarmoq yo'q
      // bo'lishi mumkin — jiddiy xato emas.
    }
  }

  /// Foydalanuvchi tizimdan chiqqanda chaqiriladi — darhol offline
  /// deb belgilaydi va kuzatuvni to'xtatadi.
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _connectionSub?.cancel();
    _connectionSub = null;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await _rtdb.ref('status/$uid').set({
        'online': false,
        'lastSeenAt': ServerValue.timestamp,
      });
      await _syncToFirestore(uid, false);
    } catch (_) {
      // Tarmoq yo'q bo'lishi mumkin — muhim emas, onDisconnect
      // baribir offline qilib qo'yadi.
    }
  }
}
