import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Brend identity — yorqin ko'k asosiy rang, qora va issiq kulrang
/// neytral fonlar bilan.
class AppColors {
  AppColors._();

  static const primary = Color(0xFF0752EB);
  static const primaryLight = Color(0xFF6690FF);
  static const primaryDark = Color(0xFF1A3FCC);

  static const ink = Color(0xFF111111);

  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFF0A500);
  static const danger = Color(0xFFE53935);

  // Light mode — issiq oq/kulrang tonlar
  static const lightBg = Color(0xFFFAF8F6);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFEDEAE7);
  static const lightTextPrimary = Color(0xFF111111);
  static const lightTextSecondary = Color(0xFF6B6B6B);
  static const lightTextMuted = Color(0xFF9A9A9A);

  // Dark mode — yumshoqroq, ko'karoq kulrang fon (sof qora emas),
  // kartochkalar fondan aniq ajralib turishi uchun bir necha pog'ona
  // yorqinroq sirt rangi bilan.
  static const darkBg = Color(0xFF15171C);
  static const darkSurface = Color(0xFF20232B);
  static const darkSurfaceElevated = Color(0xFF272B35);
  static const darkBorder = Color(0xFF383C47);
  static const darkTextPrimary = Color(0xFFF3F4F6);
  static const darkTextSecondary = Color(0xFFAFB4C0);
  static const darkTextMuted = Color(0xFF7B818F);

  // Dark rejimda quyuq fon ustida yorqinroq ko'rinishi uchun bir oz
  // ochilgan versiyalari.
  static const primaryDarkMode = Color(0xFF5E8FF2);
  static const successDarkMode = Color(0xFF5CC26E);
  static const dangerDarkMode = Color(0xFFFF6B63);
  static const warningDarkMode = Color(0xFFFFB74D);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  /// Yagona tipografiya ierarxiyasi — 7 pog'ona, ko'proq emas.
  ///
  /// Auditdan oldin ilovada 23 xil `fontSize` qiymati ishlatilardi
  /// (9, 9.5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14 ...), ya'ni
  /// 12 va 15 orasida 8 ta turli o'lcham bor edi. Bu ierarxiya emas —
  /// har bir ekranda alohida tanlangan tasodifiy sonlar edi.
  ///
  /// Endi har bir pog'ona aniq vazifaga ega va ular orasidagi farq
  /// ko'zga sezilarli (28 → 20 → 17 → 15 → 14 → 13 → 11).
  static TextTheme _textTheme(Color primary, Color secondary) {
    final base = GoogleFonts.sourceSans3TextTheme();

    return base.copyWith(
      // 28/w800 — onboarding va splash sarlavhalari.
      displaySmall: GoogleFonts.workSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.25,
        color: primary,
      ),
      // 20/w700 — ekran sarlavhasi (AppBar bilan bir xil).
      titleLarge: GoogleFonts.workSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primary,
      ),
      // 17/w700 — bo'lim sarlavhasi ("Yaqin tadbirlar", "Statistika").
      titleMedium: GoogleFonts.workSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primary,
      ),
      // 15/w600 — kartochka sarlavhasi.
      titleSmall: GoogleFonts.workSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: primary,
      ),
      // 14/w400 — asosiy matn.
      bodyLarge: GoogleFonts.sourceSans3(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: primary,
      ),
      // 13/w400 — ikkilamchi matn: sana, tavsif, meta ma'lumot.
      bodyMedium: GoogleFonts.sourceSans3(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondary,
      ),
      // 12/w500 — kichik yordamchi matn.
      bodySmall: GoogleFonts.sourceSans3(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: secondary,
      ),
      // 15/w700 — tugma matni.
      labelLarge: GoogleFonts.sourceSans3(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      // 11/w600 — teg, badge, eng mayda yorliq.
      labelSmall: GoogleFonts.sourceSans3(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.2,
        color: secondary,
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    // Dark rejimda quyuq fon ustida asosiy rang biroz yorqinroq
    // ko'rinishi kerak — aks holda xira va bosib ketgandek tuyuladi.
    final primary = isDark ? AppColors.primaryDarkMode : AppColors.primary;

    final baseTextTheme = _textTheme(textPrimary, textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        surface: surface,
        primary: primary,
      ),
      textTheme: baseTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        centerTitle: false,
        titleTextStyle: baseTextTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkSurfaceElevated : surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(color: border, width: isDark ? 0.8 : 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF5F5F7),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide:
              BorderSide(color: primary.withValues(alpha: 0.5), width: 1.5),
        ),
        hintStyle: baseTextTheme.bodyLarge?.copyWith(color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle: baseTextTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: baseTextTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5),
    );
  }
}

/// Onboarding va boshqa joylarda ishlatiladigan kichik rang yordamchisi.
extension AppColorsContext on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}