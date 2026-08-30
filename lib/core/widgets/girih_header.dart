import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ekran tepasidagi bezakli lenta — haqiqiy, litsenziyalangan (CC0,
/// Met Museum) o'zbek ikat to'qimachiligi surati bilan.
///
/// Avval bu yerda o'zim chizgan vektor girih naqshi bor edi — foydalanuvchi
/// buni yoqtirmadi ("o'zing chizib o'tirma"). Endi haqiqiy surat
/// ishlatiladi, rangli parda bilan bosilgan (matn oq bo'lgani uchun
/// o'qilishi kerak).
///
/// Naqsh/surat faqat SHU lentada bo'ladi: pastdagi ro'yxat va
/// kartochkalar toza fonda qoladi. Lenta ekranning yuqori chetigacha
/// (status bar ostigacha) cho'ziladi — shuning uchun ichida
/// `MediaQuery` tepa padding'i hisobga olinadi va chaqiruvchi ekran
/// `SafeArea(top: false)` ishlatishi kerak.
class GirihHeader extends StatelessWidget {
  /// Lenta ichidagi kontent (sarlavha, tugmalar va h.k.).
  final Widget child;

  /// Surat ustidagi parda rangi. Berilmasa brend ko'ki ishlatiladi.
  final Color? color;

  /// Fon surati — `assets/images/patterns/` ichidan.
  final String image;

  /// Surat qaysi qismi ko'rinishini boshqaradi — bir xil surat turli
  /// ekranlarda turlicha "kesilgan" ko'rinishi uchun.
  final Alignment imageAlignment;

  /// Har bir ekranga xos, katta va xira (past shaffoflik) fon belgisi —
  /// naqsh chizish o'rniga, ekranlar orasida shaxsiyat farqini
  /// mavjud ikonalar bilan yaratadi.
  final IconData? watermarkIcon;

  const GirihHeader({
    super.key,
    required this.child,
    this.color,
    this.image = 'assets/images/patterns/uzbek_ikat_stripes.jpg',
    this.imageAlignment = Alignment.center,
    this.watermarkIcon,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    final topInset = MediaQuery.paddingOf(context).top;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.pill),
      ),
      // SizedBox(width: infinity) — Stack o'zining kengligini "non-
      // positioned" bolalaridan (bu yerda sarlavha) oladi. Agar
      // sarlavha tor bo'lsa (masalan yolg'iz Text, Row(spaceBetween)
      // kabi kengaymaydi), butun header torayib, ekran chap-o'ngida
      // bo'sh joy qolib ketardi (Qo'shnilar ekranida sodir bo'lgan
      // xato). Endi Stack har doim to'liq enda majburlanadi.
      child: SizedBox(
        width: double.infinity,
        child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(image, fit: BoxFit.cover, alignment: imageAlignment),
          ),
          // Rangli parda — surat ustida oq matn o'qilishi uchun,
          // shu bilan birga lentaning brend rangi bilan bog'liqligini
          // saqlaydi.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    base.withValues(alpha: 0.7),
                    base.withValues(alpha: 0.48),
                  ],
                ),
              ),
            ),
          ),
          if (watermarkIcon != null)
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                watermarkIcon,
                size: 108,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              topInset + AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            child: child,
          ),
        ],
        ),
      ),
    );
  }
}
