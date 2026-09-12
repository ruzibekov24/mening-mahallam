import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'
    show FlutterQuillLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/services/presence_service.dart';
import 'core/services/push_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/eye_comfort_provider.dart';
import 'core/theme/text_scale_provider.dart';
import 'core/theme/theme_mode_provider.dart';
import 'features/language/data/language_repository.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------
  // QOIDA: `runApp()`gacha bo'lgan hech bir chaqiruv ilovaning ishga
  // tushishini to'sib qo'ymasligi kerak.
  //
  // Ilgari bu yerda bir necha `await` turardi (Crashlytics sozlash,
  // push xizmati). Ulardan bittasi javob qaytarmasa — masalan Google
  // Play xizmatlari to'liq bo'lmagan qurilmada — `runApp()` umuman
  // chaqirilmasdi va ilova tizim splash ekranida muzlab qolardi:
  // foydalanuvchi uchun bu "ilova ochilmayapti"ga o'xshaydi, hech
  // qanday xato ham ko'rinmaydi.
  //
  // Shuning uchun: Firebase (usiz ilova ishlay olmaydi) muddat bilan
  // kutiladi, qolgan hamma narsa birinchi kadrdan KEYIN, fonda.
  // ---------------------------------------------------------------
  // TIZIM PANELLARI ILOVA RANGIGA ERGASHSIN.
  //
  // Ilgari `SystemChrome` umuman chaqirilmasdi: Android o'zining
  // standart pastki navigatsiya paneli fonini (och kulrang) chizardi.
  // Tungi rejimda bu ayniqsa yomon ko'rinardi — qora ilova ostida
  // to'satdan kulrang tasma paydo bo'lardi, ya'ni ilova ekranga
  // to'liq egalik qilmagandek tuyulardi.
  //
  // `edgeToEdge` bilan kontent tizim panellari ostigacha cho'ziladi,
  // panellarning o'z foni esa shaffof bo'ladi. Ikonkalarning rangi
  // (och/to'q) mavzuga qarab pastda, `MeningMahallamApp` ichida
  // beriladi.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final firebaseReady = await _initFirebase();

  // ---------------------------------------------------------------
  // Release'da Flutter'ning standart xato widgeti — MATNSIZ KULRANG
  // TO'RTBURCHAK. Ya'ni ilova ildizida ko'tarilgan har qanday xato
  // foydalanuvchi uchun "oq ekranda muzlab qolgan ilova" bo'lib
  // ko'rinadi: na xabar, na tugma, na sabab.
  //
  // Aynan shu narsa yuz bergan bo'lishi mumkin: `main()` Firebase
  // xatosini ushlab, davom etardi — keyin esa `routerProvider`
  // `FirebaseAuth.instance`ni chaqirib, "No Firebase App '[DEFAULT]'"
  // xatosini tashlardi. Natija — bo'sh oq ekran.
  //
  // Endi hech bo'lmaganda nima bo'lganini o'qish mumkin.
  // ---------------------------------------------------------------
  ErrorWidget.builder = (details) => _FatalErrorScreen(
        message: details.exceptionAsString(),
      );

  // Ushlanmagan xatolar hech bo'lmaganda jurnalga tushsin.
  //
  // MUHIM — Crashlytics ataylab OLIB TASHLANGAN. U qo'shilgandan keyin
  // (v1.0.2) ilovaning ochilgani biror marta ham tasdiqlanmadi.
  // Sabab tasdiqlangach, u ehtiyotkorlik bilan qaytariladi.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Ushlanmagan Flutter xatosi: ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Ushlanmagan xato: $error\n$stack');
    return true;
  };

  // Firebase ishga tushmagan bo'lsa, MaterialApp.router'ni UMUMAN
  // qurmaymiz: `routerProvider` `FirebaseAuth.instance`ni chaqiradi
  // va u shu holatda xato tashlaydi. Uning o'rniga sababi
  // tushuntirilgan, qayta urinish tugmasi bor ekran ko'rsatiladi.
  if (!firebaseReady) {
    runApp(const _FirebaseUnavailableApp());
    return;
  }

  runApp(const ProviderScope(child: MeningMahallamApp()));

  unawaited(_initBackgroundServices());
}

/// Firebase'ni ishga tushiradi; muvaffaqiyatli bo'lsa `true`.
Future<bool> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 20));

    // ---------------------------------------------------------------
    // Firestore oflayn keshi ANIQ sozlanadi.
    //
    // Mobil SDK'da bu funksiya standart holda YOQILGAN — shuning
    // uchun ilova hozir ham (sozlamasiz) oflaynda oxirgi ko'rilgan
    // ma'lumotlarni ko'rsatib turibdi. Lekin standart kesh hajmi
    // 40MB — mahalla ilovasida ko'plab rasm/URL maydonlari bo'lgan
    // hujjatlar (e'lonlar, murojaatlar) uchun bu tez to'lib, eski
    // yozuvlarni chetlab tashlashi mumkin. Cheksiz (`CACHE_SIZE_
    // UNLIMITED`) o'rniga katta-lekin-chegaralangan 200MB tanlandi:
    // Firestore matn/metama'lumot saqlaydi (rasmning o'zi emas, faqat
    // Supabase Storage URL'i) — 200MB minglab hujjat uchun yetarli,
    // shu bilan birga qurilma xotirasini cheksiz eyishning oldi
    // olinadi.
    //
    // MUHIM: bu sozlama Firestore'dan BIRINCHI o'qishdan OLDIN
    // o'rnatilishi kerak, aks holda `setState was called after...`
    // emas, balki jimgina e'tiborsiz qoldiriladi (yoki xato tashlaydi
    // agar Firestore instance allaqachon ishga tushgan bo'lsa).
    // Shuning uchun aynan shu yerda — Firebase ishga tushgach, lekin
    // hali biror ekran yoki provider Firestore'ni chaqirmasdan turib.
    // ---------------------------------------------------------------
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 200 * 1024 * 1024,
    );

    return true;
  } catch (e, s) {
    debugPrint('Firebase ishga tushmadi: $e\n$s');
    return false;
  }
}

/// Firebase ishga tushmaganda ko'rsatiladigan ekran.
///
/// ATAYLAB juda oddiy: `AppLocalizations`, `AppTheme`, Riverpod yoki
/// GoRouter'ga TEGMAYDI. Bu ekran aynan boshqa hamma narsa
/// ishlamaganda chiziladi — shuning uchun u hech narsaga bog'liq
/// bo'lmasligi kerak, aks holda o'zi ham yiqilib, yana o'sha bo'sh
/// oq ekran qoladi.
class _FirebaseUnavailableApp extends StatefulWidget {
  const _FirebaseUnavailableApp();

  @override
  State<_FirebaseUnavailableApp> createState() =>
      _FirebaseUnavailableAppState();
}

class _FirebaseUnavailableAppState extends State<_FirebaseUnavailableApp> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    final ok = await _initFirebase();
    if (!mounted) return;
    if (ok) {
      // Muvaffaqiyatli bo'lsa — to'liq ilovani ishga tushiramiz.
      runApp(const ProviderScope(child: MeningMahallamApp()));
      unawaited(_initBackgroundServices());
      return;
    }
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off_rounded,
                    size: 64, color: Color(0xFF9AA0A6)),
                const SizedBox(height: 24),
                const Text(
                  'Ilova serverga ulana olmadi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1C1E),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Internet aloqangizni tekshiring va qayta urinib '
                  "ko'ring. Aloqa bor bo'lsa, biroz kutib qayta "
                  'urinish kifoya qiladi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _retrying ? null : _retry,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _retrying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Qayta urinish'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ilova ildizida ushlanmagan xato bo'lganda chiziladigan ekran.
///
/// Flutter release'da bunday holatda MATNSIZ kulrang to'rtburchak
/// ko'rsatadi — foydalanuvchi uchun bu "ilova ochilmadi"dan boshqa
/// hech narsa demaydi va bizga ham hech qanday ma'lumot bermaydi.
class _FatalErrorScreen extends StatelessWidget {
  final String message;

  const _FatalErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    // `Directionality` qo'lda beriladi: bu widget MaterialApp'dan
    // TASHQARIDA ham chizilishi mumkin.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        color: const Color(0xFFF7F8FA),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 56, color: Color(0xFFD93025)),
              const SizedBox(height: 20),
              const Text(
                'Ilovada xatolik yuz berdi',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1C1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ilovani yopib qayta oching. Takrorlansa, quyidagi '
                'matnni bizga yuboring:',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, height: 1.5, color: Color(0xFF5F6368)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9AA0A6),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ilova ko'rinib bo'lgach ishga tushadigan, kechiktirsa bo'ladigan
/// xizmatlar. Har biri alohida himoyalangan — bittasi ishlamasa
/// qolganlari va ilovaning o'zi ishlashda davom etadi.
Future<void> _initBackgroundServices() async {
  try {
    await PushNotificationService.instance.init();
  } catch (_) {
    // Push mavjud bo'lmasa ilova baribir ishlaydi.
  }
}

class MeningMahallamApp extends ConsumerStatefulWidget {
  const MeningMahallamApp({super.key});

  @override
  ConsumerState<MeningMahallamApp> createState() => _MeningMahallamAppState();
}

class _MeningMahallamAppState extends ConsumerState<MeningMahallamApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Online/offline holati endi Firebase Realtime Database'ning
    // onDisconnect() orqali server tomonida kuzatiladi — ilova
    // qanday yopilishidan qat'iy nazar (crash, majburiy o'chirish,
    // internet uzilishi) to'g'ri holat kafolatlanadi. Foydalanuvchi
    // auth holati o'zgarganda (login/logout) qayta ishga tushiriladi.
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        PresenceService.instance.start();
        PushNotificationService.instance.registerToken();
      } else {
        PresenceService.instance.stop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Ilgari faqat `detached` (to'liq yopilish)da offline deb
    // belgilanardi — fonga tushish (`paused`) e'tiborsiz qoldirilib,
    // "RTDB ulanishi o'zi vaqti bilan uziladi" degan taxminga
    // tayanilardi. Amalda bu yetarlicha tez emas: real qurilmalarda
    // (ayniqsa Android) ilova fonda bo'lsa ham RTDB ulanishi
    // daqiqalab (ba'zan undan ko'proq) saqlanib qolishi mumkin —
    // shuning uchun foydalanuvchi ilovadan chiqib ketgan bo'lsa ham
    // "online" bo'lib ko'rinaverardi. Endi fonga tushishning o'zida
    // DARHOL offline deb belgilaymiz (pullik Firebase xizmati kerak
    // emas — bari RTDB'ning bepul rejasida), qaytib ochilganda esa
    // darhol online holatini tiklaymiz.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        PresenceService.instance.stop();
        break;
      case AppLifecycleState.resumed:
        PresenceService.instance.start();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);
    final appLanguage = ref.watch(languageProvider);
    final eyeComfort = ref.watch(eyeComfortProvider);

    // `glass_bottom_navigation` alohida widget sifatida ishlaydi va
    // AdaptiveApp kabi maxsus ilova ildizini talab qilmaydi — shuning
    // uchun oddiy MaterialApp.router'ga qaytdik.
    return MaterialApp.router(
      title: 'Mening Mahallam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: appLanguage.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      // Qariyalar uchun sozlanadigan matn kattaligini butun ilova
      // bo'ylab qo'llaymiz (Sozlamalar > Matn kattaligi).
      builder: (context, child) {
        // Tizim panellari ikonkalari mavzuga ergashadi.
        //
        // `builder` ichida bo'lgani MUHIM: bu yerda `context`
        // allaqachon MaterialApp'ning mavzusini biladi, ya'ni
        // `themeMode == system` bo'lganda ham haqiqiy (hisoblangan)
        // yorug'lik darajasi olinadi. Yuqorida, MaterialApp'dan
        // tashqarida buni bilib bo'lmasdi.
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final overlay = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          // Pastki panel foni shaffof — ilova kontenti uning
          // ostidan ko'rinib turadi.
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness:
              isDark ? Brightness.light : Brightness.dark,
          // Android o'zi shaffof panel ortiga yarim tiniq
          // "himoya" qatlamini qo'shib qo'yadi — aynan o'sha
          // kulrang tasmani hosil qiladi. O'chiramiz.
          systemNavigationBarContrastEnforced: false,
          systemStatusBarContrastEnforced: false,
        );

        Widget content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale.factor),
          ),
          child: child!,
        );

        // "Ko'z himoyasi" — Samsungdagi "Eye comfort shield"ga
        // o'xshab, ko'k rangni kamaytiruvchi issiq filtr. Faqat
        // shu ilova ichida ishlaydi (tizim darajasidagi Night
        // Light'dan farqli), shuning uchun `builder`ning ENG
        // TASHQI qatlamida — barcha ekranlar, dialoglar va
        // bottom sheet'lar ustida ham qo'llanadi.
        if (eyeComfort) {
          content = ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              1.0,
              0,
              0,
              0,
              0,
              0,
              0.92,
              0,
              0,
              0,
              0,
              0,
              0.72,
              0,
              8,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: content,
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay,
          child: content,
        );
      },
    );
  }
}
