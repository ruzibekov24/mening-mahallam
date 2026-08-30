import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_version.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';

/// 1. SPLASH ekrani.
///
/// Animatsiya tartibi:
///   1. Avval FAQAT ikonka (`assets/images/app_icon.png`, matnsiz)
///      markazda o'rtacha o'lchamda paydo bo'ladi — hech qanday
///      qo'shimcha ramka/fon quti/halqa yo'q.
///   2. Keyin ikonka yonidan "Mening Mahallam" yozuvi ENI 0'dan to'liq
///      enigacha "ochiladi" (`ClipRect` + `Align(widthFactor:)`). Butun
///      guruh (ikonka+matn) tashqi `Center` ichida turgani uchun, matn
///      kengayganda butun qator qayta markazlashadi — bu "ikonka
///      chapga suriladi, yonidan matn chiqadi" hissini beradi, holbuki
///      ikonkaning o'zi harakatlanmaydi.
///   3. Nihoyat, tagline pastda Poppins shriftida yoritiladi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _titleReveal;
  late final Animation<double> _taglineOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 1-bosqich: ikonka yolg'iz paydo bo'ladi (0.0-0.4).
    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutBack),
      ),
    );
    _iconOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    // 2-bosqich: ikonka "joyida turadi", uning yonidan ilova nomi
    // matni kengligi bo'yicha ochilib chiqadi (0.42-0.8).
    _titleReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.42, 0.8, curve: Curves.easeOutCubic),
    );

    // 3-bosqich: tagline pastda yoritiladi (0.82-1.0).
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    // Splash HAR DOIM ko'rsatiladi (login qilingan bo'lsa ham) — endi
    // shu yerda auth holatini tekshirib, mos ekranga yo'naltiramiz.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      context.go(AppRoutes.language);
      return;
    }

    try {
      // MUDDAT SHART: internet bo'lmasa yoki sekin bo'lsa, Firestore
      // `.get()` darhol xato qaytarmaydi — u serverni kutib turishi
      // mumkin. Muddat bo'lmasa splash ekrani cheksiz turib qolardi
      // va foydalanuvchi uchun bu "ilova muzlab qoldi" bo'lardi.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      final mahallaId = doc.data()?['mahallaId'] as String?;
      if (!mounted) return;
      if (mahallaId != null && mahallaId.isNotEmpty) {
        context.go(AppRoutes.home);
      } else {
        context.go(AppRoutes.qrScan);
      }
    } catch (_) {
      if (!mounted) return;
      context.go(AppRoutes.qrScan);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bg = context.isDarkMode ? AppColors.darkBg : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ikonka + ilova nomi bitta qatorda — matn ikonka
                // yonidan "ochilib" chiqadi, butun qator markazda
                // turgani uchun bu ikonka chapga surilayotgandek
                // ko'rinadi.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: _iconOpacity.value,
                      child: Transform.scale(
                        scale: _iconScale.value,
                        // `app_icon.png` — to'liq to'ldirilgan kvadrat
                        // (burchaklari shaffof emas). Launcher uni
                        // o'zi niqoblab yumaloqlaydi, splashda esa
                        // niqob yo'q edi va logotip o'tkir qirrali
                        // kvadrat bo'lib ko'rinardi. Shu yerda o'zimiz
                        // yumaloqlaymiz — 22% Android/iOS ikonka
                        // niqobiga yaqin nisbat.
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(64 * 0.22),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: _titleReveal.value,
                        child: Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: Text(
                            l10n.appTitle,
                            softWrap: false,
                            style: context.displayStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Opacity(
                  opacity: _taglineOpacity.value,
                  child: Column(
                    children: [
                      Text(
                        l10n.splashTagline,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      // Versiya belgisi — qaysi build o'rnatilgani har
                      // doim aniq bo'lishi uchun. Sinov paytida "eski
                      // versiyani sinagan bo'lishim mumkin" degan
                      // noaniqlikni yo'q qiladi.
                      Text(
                        'v$kAppVersion',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: context.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
