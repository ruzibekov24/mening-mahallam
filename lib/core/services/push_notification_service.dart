import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/presentation/chat_screen.dart';
import '../../features/home/data/home_repository.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../router/app_router.dart';
import '../widgets/main_shell.dart';

/// Fon rejimida (ilova yopiq/background) kelgan xabarlarni qayta
/// ishlaydi. Top-level va `@pragma('vm:entry-point')` bo'lishi SHART —
/// Flutter bu funksiyani alohida izolyatsiyada chaqiradi.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Fon holatida FCM/tizim xabarni o'zi ko'rsatadi (Android/iOS native
  // push tray) — bu yerda faqat kerak bo'lsa qo'shimcha ma'lumot bilan
  // ishlash mumkin (masalan mahalliy bazaga yozish). Hozircha kerak
  // emas, lekin handler ro'yxatdan o'tgan bo'lishi shart, aks holda
  // ba'zi platformalarda fon xabarlari umuman kelmaydi.
}

/// Push bildirishnomalarni boshqaradi: ruxsat so'raydi, FCM token
/// oladi va uni Firestore'dagi foydalanuvchi hujjatiga saqlaydi (server
/// tomoni — Supabase Edge Function — shu token orqali xabar yuboradi),
/// va ilova ochiq turganda kelgan xabarlarni mahalliy bildirishnoma
/// sifatida ko'rsatadi (FCM ilova old planda bo'lsa avtomatik
/// ko'rsatmaydi — buni qo'lda qilish SHART).
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _androidChannel = AndroidNotificationChannel(
    'default_channel',
    'Bildirishnomalar',
    description: "Mahalla e'lonlari, tadbirlar va murojaatlar haqida",
    importance: Importance.high,
  );

  /// Ilova ishga tushganda BIR MARTA chaqiriladi (`main.dart`). Ruxsat
  /// so'ramaydi — faqat ko'rsatish infratuzilmasini tayyorlaydi.
  /// Ruxsat so'rash va token saqlash [registerToken] orqali, foydalanuvchi
  /// tizimga kirgandan keyin amalga oshadi.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await _initInternal();
    } catch (_) {
      // Google Play xizmatlari to'liq bo'lmagan qurilmalarda (ba'zi
      // emulyatorlar, sertifikatsiz telefonlar) FCM sozlash xato
      // berishi mumkin — bunda ilova push'siz, lekin to'liq
      // ishlashda davom etishi kerak.
    }
  }

  Future<void> _initInternal() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      // Ilova OLD PLANDA (foreground) turganda ko'rsatilgan mahalliy
      // bildirishnoma bosilganda ham xuddi shu ekranga o'tish mantig'i
      // ishlashi uchun — bu holatda RemoteMessage emas, faqat `payload`
      // (biz jsonEncode qilib saqlagan data map) qaytadi.
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          _handleTap(data);
        } catch (_) {
          // Payload buzilgan bo'lsa — jimgina e'tiborsiz qoldiramiz,
          // ilova ochilib turibdi, bu yetarli.
        }
      },
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // Ilova OLD PLANDA turganda FCM xabarni o'zi ko'rsatmaydi — buni
    // qo'lda mahalliy bildirishnoma sifatida chiqarish kerak, aks
    // holda foydalanuvchi ilovani ochib turganda hech narsa ko'rmaydi.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // Ilova FONDA turib, bildirishnoma tepasidagi tizim xabarini
    // bosib ochilgan holat.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleTap(message.data);
    });

    // Ilova BUTUNLAY YOPIQ holatda, push bosilib ochilgan holat.
    //
    // MUHIM: `await` QILINMAYDI. Ba'zi qurilmalarda (Google Play
    // xizmatlari to'liq bo'lmagan telefonlar, emulyatorlar)
    // `getInitialMessage()` javob qaytarmasligi mumkin — agar uni
    // kutsak, `init()` tugamaydi va ilova ishga tushmay qoladi.
    // Navigatsiyaning o'zi [_handleTap] ichida navigator tayyor
    // bo'lguncha kutadi, shuning uchun kechikish muammo emas.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) _handleTap(message.data);
    }).catchError((_) {
      // Push mavjud bo'lmasa ilovaning qolgan qismi baribir ishlaydi.
    });
  }

  /// Bildirishnoma bosilganda `data['type']` va `data['relatedId']`ga
  /// qarab tegishli tab/ekranga o'tadi. Bu joyda `BuildContext` yo'q
  /// (FCM callback'i widget daraxtidan tashqarida chaqiriladi), shuning
  /// uchun [rootNavigatorKey] orqali ildiz Navigator'iga murojaat
  /// qilinadi.
  Future<void> _handleTap(Map<String, dynamic> data) async {
    final type = NotificationTypeX.fromString(data['type'] as String?);
    final relatedId = data['relatedId'] as String?;

    // Sovuq start (getInitialMessage) holatida ildiz Navigator hali
    // tayyor bo'lmasligi mumkin — bir necha soniya kutamiz.
    NavigatorState? navState = rootNavigatorKey.currentState;
    for (var i = 0; i < 50 && navState == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      navState = rootNavigatorKey.currentState;
    }
    final context = navState?.context;
    if (navState == null || context == null || !context.mounted) return;

    final container = ProviderScope.containerOf(context, listen: false);

    switch (type) {
      case NotificationType.newAnnouncement:
      case NotificationType.newEvent:
      case NotificationType.newPoll:
        // Bitta e'lon/tadbir uchun alohida tafsilot ekrani yo'q —
        // ro'yxat E'lonlar tabida to'g'ridan-to'g'ri ko'rsatiladi.
        container.read(mainTabIndexProvider.notifier).state = 1;
        break;

      case NotificationType.requestStatusChanged:
        container.read(mainTabIndexProvider.notifier).state = 2;
        if (relatedId == null) break;
        try {
          final profile =
              await container.read(currentUserProfileProvider.future);
          final mahallaId = profile?.mahallaId;
          if (mahallaId == null || !context.mounted) break;
          navState.push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(
                mahallaId: mahallaId,
                requestId: relatedId,
              ),
            ),
          );
        } catch (_) {
          // Murojaat topilmasa yoki mahallaId aniqlanmasa — tab
          // almashtirilgani yetarli, xato ko'rsatilmaydi.
        }
        break;

      case NotificationType.premiumPaymentSubmitted:
      case NotificationType.premiumApproved:
      case NotificationType.premiumRejected:
      case NotificationType.accountDeletionRequested:
        // Premium bildirishnomalari uchun alohida ekranga o'tmaymiz —
        // ilova ochilishining o'zi yetarli, tafsilotlar Sozlamalar >
        // Premium bo'limida turadi.
        break;

      case NotificationType.newMessage:
        if (relatedId == null) break;
        final myUid = FirebaseAuth.instance.currentUser?.uid;
        if (myUid == null) break;
        // conversationId har doim ikkita uid'ning tartiblangan
        // birlashmasi (`${sorted[0]}_${sorted[1]}`, ChatRepository
        // .conversationIdFor) — shundan o'zimizniki bo'lmagan uid'ni
        // ajratib olamiz.
        final parts = relatedId.split('_');
        if (parts.length != 2) break;
        final otherUid = parts.first == myUid ? parts.last : parts.first;
        navState.push(
          MaterialPageRoute(builder: (_) => ChatScreen(otherUid: otherUid)),
        );
        break;
    }
  }

  /// Foydalanuvchi tizimga kirgach chaqiriladi: bildirishnoma ruxsatini
  /// so'raydi (iOS/Android 13+da shart) va FCM tokenni Firestore'ga
  /// yozadi. Token yangilanganda ham (`onTokenRefresh`) avtomatik
  /// qayta yoziladi.
  Future<void> registerToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // iOS'da APNs tokeni tayyor bo'lishini biroz kutish kerak
      // bo'lishi mumkin — token null qaytsa, xatosiz shunchaki
      // chiqib ketamiz (keyingi ochilishda qayta urinib ko'riladi).
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveToken(uid, token);
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveToken(uid, newToken);
      });
    } catch (_) {
      // Ruxsat rad etilishi yoki emulyatorda Google Play xizmati
      // yo'qligi kabi holatlar — ilovaning qolgan qismi push'siz ham
      // ishlashda davom etishi kerak.
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'fcmPlatform': Platform.isIOS ? 'ios' : 'android',
      },
      SetOptions(merge: true),
    );
  }

  /// Chiqishda tokenni Firestore'dan olib tashlaydi — boshqa hisobga
  /// eski qurilmaga push ketmasligi uchun.
  Future<void> clearToken(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': FieldValue.delete(),
      });
    } catch (_) {
      // Hisob allaqachon o'chirilgan yoki ruxsat yo'q bo'lishi mumkin —
      // chiqish jarayonini to'xtatmaymiz.
    }
  }
}
