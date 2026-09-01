import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/language/presentation/language_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/qr/presentation/qr_scan_screen.dart';
import '../../features/qr/presentation/qr_result_screen.dart';
import '../../features/qr/data/mahalla_repository.dart';
import '../widgets/main_shell.dart';
import 'app_page_route.dart';

/// Push bildirishnoma bosilganda (BuildContext mavjud bo'lmagan joydan —
/// [PushNotificationService] ichidan) navigatsiya qilish uchun global
/// kalit. GoRouter konstruktoriga beriladi, shuning uchun ildiz
/// Navigator'ining joriy holati va context'iga istalgan joydan
/// murojaat qilish mumkin.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Ilova bo'ylab ishlatiladigan yo'llar (routes) nomlari.
/// Keyingi bosqichlarda login, home va h.k. shu yerga qo'shiladi.
abstract class AppRoutes {
  static const splash = '/';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const qrScan = '/qr-scan';
  static const qrResult = '/qr-result';
  static const home = '/home';
}

/// GoRouter'ga Firebase auth holati o'zgarganda (login/logout)
/// qayta baholashni buyuradigan yordamchi klass.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<void> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Login qilinmasa kirib bo'lmaydigan yo'llar.
const _authRequiredPaths = {
  AppRoutes.qrScan,
  AppRoutes.qrResult,
  AppRoutes.home,
};

/// Login qilingandan keyin qaytadan ko'rsatilmasligi kerak bo'lgan yo'llar
/// (onboarding/login/register) — agar foydalanuvchi allaqachon tizimga
/// kirgan bo'lsa, bu yerdan avtomatik boshqa joyga yo'naltiriladi.
/// Splash bu ro'yxatda YO'Q — chunki u har doim (login qilingan bo'lsa
/// ham) ko'rsatilishi kerak, keyin o'zi auth holatini tekshirib
/// navigatsiya qiladi (splash_screen.dart ichida).
const _preAuthPaths = {
  AppRoutes.language,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

/// Barcha sahifalar uchun bir xil, silliq o'tish: yengil o'ngdan
/// suzib kirish + fade. Standart Material "flat" o'tish o'rniga
/// ilovaga iOS'ga yaqinroq, "jonli" his beradi.
CustomTransitionPage<void> _buildPageWithTransition({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: appPageTransitionDuration,
    reverseTransitionDuration: appPageReverseTransitionDuration,
    transitionsBuilder: appPageTransitionsBuilder,
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final auth = FirebaseAuth.instance;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(auth.authStateChanges()),
    redirect: (context, state) async {
      final user = auth.currentUser;
      final path = state.matchedLocation;

      // Login talab qiladigan sahifaga login qilmasdan kirmoqchi bo'lsa —
      // login ekraniga qaytaramiz.
      if (_authRequiredPaths.contains(path) && user == null) {
        return AppRoutes.login;
      }

      // Foydalanuvchi allaqachon tizimga kirgan bo'lsa, splash/onboarding/
      // login/register kabi "kirishdan oldingi" sahifalarda qolib
      // ketmasligi kerak — mahallaga bog'langan-bog'lanmaganiga qarab
      // to'g'ridan-to'g'ri Home yoki QR skanerlashga yo'naltiramiz.
      if (_preAuthPaths.contains(path) && user != null) {
        final userDocRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        try {
          // MUDDAT SHART: GoRouter async `redirect` tugaguncha HECH
          // QANDAY sahifa chizmaydi — ekran bo'sh qoladi. Firestore
          // `.get()` internet bo'lmaganda uzoq kutishi mumkin,
          // shuning uchun muddatsiz qoldirish "oq ekranda muzlab
          // qolgan ilova" degani.
          final doc = await userDocRef.get().timeout(const Duration(seconds: 10));
          final mahallaId = doc.data()?['mahallaId'];
          return (mahallaId != null && mahallaId != '')
              ? AppRoutes.home
              : AppRoutes.qrScan;
        } catch (e) {
          debugPrint('app_router: users/${user.uid} server read failed: $e');
          // Server o'qish muvaffaqiyatsiz bo'ldi (tarmoq/timeout). Foydalanuvchi
          // avval muvaffaqiyatli login qilgan bo'lsa, mahallaId odatda mahalliy
          // Firestore keshida bor — uni QR skanerlashga qaytarishdan oldin
          // tekshiramiz, aks holda vaqtinchalik tarmoq muammosi tufayli
          // allaqachon bog'langan mahallasi "yo'qolib qoladi".
          try {
            final cached = await userDocRef.get(
              const GetOptions(source: Source.cache),
            );
            final cachedMahallaId = cached.data()?['mahallaId'];
            if (cachedMahallaId != null && cachedMahallaId != '') {
              return AppRoutes.home;
            }
          } catch (cacheError) {
            debugPrint(
                'app_router: users/${user.uid} cache read failed: $cacheError');
          }
          return AppRoutes.qrScan;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.language,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const LanguageScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qrScan,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const QrScanScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.qrResult,
        pageBuilder: (context, state) {
          final mahalla = state.extra as MahallaInfo;
          return _buildPageWithTransition(
            state: state,
            child: QrResultScreen(mahalla: mahalla),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) => _buildPageWithTransition(
          state: state,
          child: const MainShell(),
        ),
      ),
      // Boshqa tab ekranlari (E'lonlar, Murojaatlar, Profil) MainShell
      // ichidagi IndexedStack orqali boshqariladi — alohida route
      // sifatida ro'yxatlanmagan.
    ],
  );
});