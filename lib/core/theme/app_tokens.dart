/// Ilova bo'ylab yagona o'lchov tizimi (design token'lar).
///
/// Auditdan oldin loyihada 22 xil bo'shliq, 17 xil radius va 8 xil soya
/// bluri ishlatilar edi — har bir ekran o'z qiymatini tanlagani uchun
/// kartochkalar bir-biriga o'xshamas edi. Bu fayl shu qiymatlarni bitta
/// joyda belgilaydi.
///
/// Qoida: yangi kod **faqat** shu konstantalardan foydalanadi. Agar mos
/// qiymat topilmasa — bu shkalani kengaytirish kerakligini bildiradi,
/// tasodifiy son yozish emas.
library;

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 4pt bazasidagi bo'shliq shkalasi.
///
/// Har bir qiymat 4 ga karrali — bu Material va iOS'ning umumiy qoidasi,
/// va turli ekranlarda bir xil "nafas" hissini beradi.
class AppSpacing {
  AppSpacing._();

  /// 2 — faqat matn qatorlari orasidagi eng zich holat uchun.
  static const double xxs = 2;

  /// 4 — ikonka bilan yonidagi matn orasi.
  static const double xs = 4;

  /// 8 — element ichidagi standart bo'shliq (sarlavha ↔ tavsif).
  static const double sm = 8;

  /// 12 — ro'yxat elementlari orasi, avatar ↔ matn orasi.
  static const double md = 12;

  /// 16 — kartochka ichki padding'i, bo'lim ichidagi bo'shliq.
  static const double lg = 16;

  /// 20 — ekran chetidagi gorizontal padding.
  static const double xl = 20;

  /// 24 — bo'limlar orasidagi bo'shliq.
  static const double xxl = 24;

  /// 32 — katta vizual pauza (sarlavha bloki ↔ kontent).
  static const double xxxl = 32;

  /// Ekranning chap/o'ng cheti uchun standart padding.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: xl);

  /// Ro'yxatli ekranlar uchun standart padding — pastda glass bottom nav
  /// ostida qolib ketmasligi uchun qo'shimcha joy bor.
  static const EdgeInsets listPadding =
      EdgeInsets.fromLTRB(xl, md, xl, 120);

  /// Kartochka ichidagi standart padding.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

/// Burchak radiusi shkalasi — 4 ta pog'ona, ko'proq emas.
class AppRadius {
  AppRadius._();

  /// 8 — kichik teglar, rang nuqtalari.
  static const double xs = 8;

  /// 12 — ikonka konteynerlari, chip/badge.
  static const double sm = 12;

  /// 16 — **standart kartochka radiusi**. Tema `cardTheme` bilan bir xil.
  static const double md = 16;

  /// 20 — katta sirtlar: bottom sheet, profil paneli, tugmalar.
  static const double lg = 20;

  /// 28 — "pill" shakl: segment tugmalar, filtr chiplari.
  static const double pill = 28;

  static const BorderRadius xsAll = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Soya retseptlari.
///
/// Auditdan oldin `blurRadius: 10, offset: (0,3)` kombinatsiyasi 10+ marta
/// qo'lda qayta yozilgan edi, har safar biroz boshqa shaffoflik bilan.
/// Endi soya faqat shu yerdan olinadi.
class AppShadows {
  AppShadows._();

  /// Oddiy kartochka — ro'yxat elementlari, sozlama qatorlari.
  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  /// Ko'tarilgan sirt — qidiruv maydoni, asosiy CTA panellari.
  static List<BoxShadow> elevated(bool isDark) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  /// Rangli akцент soyasi — kategoriya kartalari va rangli tugmalar
  /// ostida, o'sha element rangida yumshoq "yorug'lik" beradi.
  static List<BoxShadow> accent(Color color, bool isDark) => [
        BoxShadow(
          color: color.withValues(alpha: isDark ? 0.22 : 0.16),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Ilovaning 4 ta tematik akцент rangi.
///
/// Bu ranglar auditdan oldin `AppColors`da umuman yo'q edi — ular
/// `Color(0xFF27AE60)` ko'rinishida 78 marta ekranlar bo'ylab qo'lda
/// yozilgan edi. Endi manba bitta.
class AppAccents {
  AppAccents._();

  /// E'lonlar — ko'k (brend asosiy rangi bilan bir xil).
  static const announcements = AppColors.primary;

  /// Tadbirlar — to'q sariq.
  static const events = Color(0xFFF2994A);

  /// Murojaatlar — yashil.
  static const requests = Color(0xFF27AE60);

  /// Qo'shnilar / rais — binafsha.
  static const neighbors = Color(0xFF9254DE);

  /// Oddiy fuqaro roli — neytral kulrang.
  static const neutral = Color(0xFF9AA0A6);

  /// Tadbir bannerlari uchun gradient juftliklari — ro'yxatda ketma-ket
  /// kartalar bir xil rangda chiqmasligi uchun `index % length` bilan
  /// aylantiriladi.
  static const bannerGradients = <List<Color>>[
    [AppColors.primary, AppColors.primaryLight],
    [requests, Color(0xFF6FCF97)],
    [events, Color(0xFFFFC080)],
    [neighbors, Color(0xFFC49CFF)],
  ];
}

/// Tipografiya — `Theme.of(context).textTheme` orqali olinadigan
/// stillarga qulay qisqartma.
///
/// Auditdan oldin 23 xil `fontSize` qiymati ishlatilardi (9, 9.5, 10,
/// 10.5, 11 ... 32) va 192 ta xom `TextStyle` bor edi. Endi ierarxiya
/// 7 pog'onadan iborat va u `app_theme.dart` da belgilanadi.
extension AppTextStyles on BuildContext {
  TextTheme get _t => Theme.of(this).textTheme;

  /// 28/w800 — faqat onboarding va splash sarlavhalari.
  TextStyle get displayStyle => _t.displaySmall!;

  /// 20/w700 — ekran sarlavhasi (AppBar bilan bir xil).
  TextStyle get titleStyle => _t.titleLarge!;

  /// 17/w700 — bo'lim sarlavhasi ("Yaqin tadbirlar", "Statistika").
  TextStyle get sectionStyle => _t.titleMedium!;

  /// 15/w600 — kartochka sarlavhasi.
  TextStyle get cardTitleStyle => _t.titleSmall!;

  /// 14/w400 — asosiy matn.
  TextStyle get bodyStyle => _t.bodyLarge!;

  /// 13/w400 — ikkilamchi matn (sana, tavsif, meta).
  TextStyle get secondaryStyle => _t.bodyMedium!;

  /// 11/w600 — teg, badge, eng mayda yorliq.
  TextStyle get captionStyle => _t.labelSmall!;
}

/// Matn ranglari uchun qisqartmalar — har bir ekranda
/// `isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary`
/// yozish o'rniga.
extension AppTextColors on BuildContext {
  Color get textPrimary => isDarkMode
      ? AppColors.darkTextPrimary
      : AppColors.lightTextPrimary;

  Color get textSecondary => isDarkMode
      ? AppColors.darkTextSecondary
      : AppColors.lightTextSecondary;

  Color get textMuted =>
      isDarkMode ? AppColors.darkTextMuted : AppColors.lightTextMuted;

  Color get surfaceColor =>
      isDarkMode ? AppColors.darkSurface : AppColors.lightSurface;

  Color get surfaceElevated => isDarkMode
      ? AppColors.darkSurfaceElevated
      : AppColors.lightSurface;

  Color get borderColor =>
      isDarkMode ? AppColors.darkBorder : AppColors.lightBorder;
}
