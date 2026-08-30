import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/language_repository.dart';

/// Splash'dan keyin, Onboarding'dan oldin ko'rsatiladigan til tanlash
/// ekrani. Boshqa kirish oqimi ekranlari (Parolni unutdim, Fikr
/// bildirish) bilan bir xil naqsh: markazda rangli ikonka qutisi +
/// sarlavha + tavsif + kontent, alohida banner/wave dizaynisiz.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({super.key});

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String _continueLabel(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
        return 'Davom etish';
      case AppLanguage.uzbekCyrillic:
        return 'Давом этиш';
      case AppLanguage.russian:
        return 'Продолжить';
    }
  }

  String _titleFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
        return 'Tilni tanlash';
      case AppLanguage.uzbekCyrillic:
        return 'Тилни танлаш';
      case AppLanguage.russian:
        return 'Выберите язык';
    }
  }

  String _subtitleFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.uzbekLatin:
        return "Ilovadan oson foydalanish uchun interfeys tilini tanlang";
      case AppLanguage.uzbekCyrillic:
        return 'Иловадан осон фойдаланиш учун интерфейс тилини танланг';
      case AppLanguage.russian:
        return 'Выберите язык интерфейса для удобного использования приложения';
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(languageProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxxl),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.lgAll,
                ),
                child: const Icon(PhosphorIconsFill.translate,
                    color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                _titleFor(selected),
                textAlign: TextAlign.center,
                style: context.displayStyle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _subtitleFor(selected),
                textAlign: TextAlign.center,
                style: context.secondaryStyle.copyWith(height: 1.4),
              ),
              const SizedBox(height: AppSpacing.xxl),
              ...AppLanguage.values.map((language) {
                final isSelected = language == selected;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _LanguageTile(
                    language: language,
                    isSelected: isSelected,
                    onTap: () =>
                        ref.read(languageProvider.notifier).select(language),
                  ),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.mdAll,
                    boxShadow:
                        AppShadows.accent(AppColors.primary, context.isDarkMode),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.onboarding),
                    child: Text(_continueLabel(selected)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Material(
      color: isSelected
          ? AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08)
          : context.surfaceColor,
      borderRadius: AppRadius.mdAll,
      elevation: 0,
      child: InkWell(
        borderRadius: AppRadius.mdAll,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdAll,
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected ? [] : AppShadows.card(isDark),
          ),
          child: Row(
            children: [
              // Bayroq — rasm fayli emas, kod orqali chiziladi.
              // Sabab: assets/images/flags/ru.png aslida PNG emas edi
              // (ichida SVG matni saqlangan edi, noto'g'ri kengaytma
              // bilan), shuning uchun ochilmay, bo'sh joy qolardi.
              // Chizilgan versiya asset buzilishidan butunlay mustaqil.
              // Bayroq DOIRA ichida emas, yumaloq to'rtburchakda.
              //
              // Doira ishlatilganda hilol va yulboqlar bayroqning
              // yuqori-chap burchagida turgani uchun qirqilib
              // ketardi. Bayroqning haqiqiy nisbati 1:2 — shu
              // nisbatda ko'rsatilsa hamma belgisi to'liq ko'rinadi.
              Container(
                width: 36,
                height: 24,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                  ),
                ),
                child: LanguageFlag(language: language),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  language.label,
                  style: context.cardTitleStyle.copyWith(
                    color: isSelected ? AppColors.primary : null,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// O'zbekiston/Rossiya bayrog'ini chizib beradi — rasm fayliga
/// bog'liq emas. Doiraviy belgi ichida ishlatilishi uchun to'g'ridan
/// -to'g'ri gorizontal chiziqlar bilan (kichik o'lchamda hilol/yulduz
/// kabi mayda detallar baribir ilg'anmaydi).
///
/// Rasm fayliga qaytmaslik SABABI ikkita: `assets/images/flags/ru.png`
/// bir vaqtlar ichida SVG matni saqlangan soxta PNG edi, `uz.png` esa
/// hozir ham aslida WebP — ya'ni bu fayllarga ishonib bo'lmaydi.
class LanguageFlag extends StatelessWidget {
  final AppLanguage language;
  const LanguageFlag({super.key, required this.language});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: language == AppLanguage.russian
          ? const _RussiaFlagPainter()
          : const _UzbekistanFlagPainter(),
      child: const SizedBox.expand(),
    );
  }
}

/// Rossiya bayrog'i — uchta teng gorizontal chiziq.
class _RussiaFlagPainter extends CustomPainter {
  const _RussiaFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Colors.white, Color(0xFF0039A6), Color(0xFFD52B1E)];
    final band = size.height / 3;
    final paint = Paint();
    for (var i = 0; i < 3; i++) {
      paint.color = colors[i];
      canvas.drawRect(
        Rect.fromLTWH(0, band * i, size.width, band + 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// O'zbekiston bayrog'i — hilol va 12 yulduz bilan.
///
/// Ilgari bayroq faqat uchta rangli chiziqdan iborat edi: hilol ham,
/// yulduzlar ham, qizil ajratuvchi chiziqlar ham yo'q edi. Natijada u
/// boshqa ko'k-oq-yashil bayroqlardan farq qilmasdi.
///
/// Nisbatlar rasmiy standartga yaqin olingan, lekin kichik o'lchamda
/// (32 px) o'qilishi uchun hilol va yulduzlar biroz kattalashtirilgan.
class _UzbekistanFlagPainter extends CustomPainter {
  const _UzbekistanFlagPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint();

    // Uchta asosiy chiziq.
    const blue = Color(0xFF0099B5);
    const green = Color(0xFF1EB53A);
    const red = Color(0xFFCE1126);

    paint.color = blue;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 3 + 0.5), paint);
    paint.color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3 + 0.5), paint);
    paint.color = green;
    canvas.drawRect(Rect.fromLTWH(0, h * 2 / 3, w, h / 3 + 0.5), paint);

    // Ko'k va yashil chiziqlarni oqdan ajratuvchi ingichka qizil
    // chiziqlar — bayroqning tanib olinadigan belgilaridan biri.
    paint.color = red;
    final hair = (h * 0.022).clamp(0.6, 2.0);
    canvas.drawRect(Rect.fromLTWH(0, h / 3 - hair / 2, w, hair), paint);
    canvas.drawRect(Rect.fromLTWH(0, h * 2 / 3 - hair / 2, w, hair), paint);

    // --- Hilol -------------------------------------------------------
    // Ikki doiraning ayirmasi sifatida chiziladi: to'liq oq doira,
    // ustidan biroz siljitilgan ko'k doira.
    final r = h * 0.115;
    final cx = w * 0.17;
    final cy = h * 0.165;

    paint.color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, paint);
    paint.color = blue;
    canvas.drawCircle(Offset(cx + r * 0.42, cy), r * 0.92, paint);

    // --- Yulduzlar ---------------------------------------------------
    // Rasmiy bayroqda 12 ta yulduz 3 qatorda (3+4+5) joylashgan.
    paint.color = Colors.white;
    final starR = h * 0.042;
    final rows = [3, 4, 5];
    final startX = w * 0.33;
    final stepX = w * 0.085;
    for (var row = 0; row < rows.length; row++) {
      final count = rows[row];
      final y = cy - h * 0.075 + row * h * 0.075;
      for (var i = 0; i < count; i++) {
        // Har bir qator o'ngga siljib boradi — natijada uchburchak
        // shaklidagi guruh hosil bo'ladi.
        final x = startX + (rows.length - 1 - row) * stepX + i * stepX;
        _drawStar(canvas, paint, Offset(x, y), starR);
      }
    }
  }

  /// Besh burchakli yulduz.
  void _drawStar(Canvas canvas, Paint paint, Offset c, double r) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      // Toq indekslarda ichki radius — bu yulduzning "botiq"
      // burchaklarini beradi.
      final radius = i.isEven ? r : r * 0.42;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(
        c.dx + radius * math.cos(angle),
        c.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
