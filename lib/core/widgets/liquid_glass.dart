/// iOS 26 "Liquid Glass" uslubidagi qayta ishlatiladigan komponentlar.
///
/// Retsept manbasi — `glass_bottom_nav.dart`: pastki navigatsiya panelida
/// allaqachon sinalgan blur/gradient/border/soya qiymatlari shu yerda
/// umumiy widget'larga ko'chirilgan, shunda ilovaning boshqa joylarida
/// "shisha" hissi har safar qayta ixtiro qilinmasdan takrorlanadi.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'animated_ui.dart';

/// Ichki — blur/gradient/border/soya konstantalari, faqat shu fayl
/// ichida ishlatiladi.
class _GlassRecipe {
  _GlassRecipe._();

  static const double blurSigma = 14;

  static List<Color> gradient(bool isDark) => isDark
      ? [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.06),
        ]
      : [
          Colors.white.withValues(alpha: 0.38),
          Colors.white.withValues(alpha: 0.16),
        ];

  static Color border(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.28)
      : Colors.white.withValues(alpha: 0.75);

  /// [strong] — katta modal/varaqlar uchun (masalan sana/vaqt tanlagich
  /// sheet'i) — spetsifikatsiyadagi "elevation 60dp" ga yaqinroq, kattaroq
  /// blur va spread bilan.
  static List<BoxShadow> shadow(bool isDark, {bool strong = false}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
          blurRadius: strong ? 40 : 24,
          spreadRadius: strong ? 2 : 0,
          offset: Offset(0, strong ? 16 : 10),
        ),
      ];
}

/// Umumiy frosted-glass sirt: blur + gradient + border + soya.
/// `LiquidGlassButton` va `LiquidGlassCircleButton` shu asosda quriladi,
/// katta modal/varaqlarni (masalan sana/vaqt tanlagich) o'rash uchun ham
/// to'g'ridan-to'g'ri ishlatilishi mumkin.
class LiquidGlassSurface extends StatelessWidget {
  const LiquidGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = AppRadius.lg,
    this.width,
    this.height,
    this.padding,
    this.strongShadow = false,
  });

  final Widget child;
  final double borderRadius;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  /// Katta modal/varaqlar uchun kuchliroq soya (spetsifikatsiyadagi
  /// "elevation 60dp" ga yaqinlashtirish uchun).
  final bool strongShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final br = BorderRadius.circular(borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: _GlassRecipe.shadow(isDark, strong: strongShadow),
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _GlassRecipe.blurSigma,
            sigmaY: _GlassRecipe.blurSigma,
          ),
          child: Container(
            width: width,
            height: height,
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _GlassRecipe.gradient(isDark),
              ),
              borderRadius: br,
              border: Border.all(color: _GlassRecipe.border(isDark), width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// iOS uslubidagi pill shaklidagi toggle switch — `Switch` bilan bir xil
/// API (`value`/`onChanged`), shuning uchun mavjud kodda to'g'ridan-to'g'ri
/// o'rniga qo'yiladi. Yoqilganda ilovaning "muvaffaqiyat" rangida
/// (`AppColors.success`) to'ladi, o'chirilganda shaffof/shisha rangdagi
/// yo'lakcha ko'rinadi.
class LiquidToggleSwitch extends StatelessWidget {
  const LiquidToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const double _width = 64;
  static const double _height = 28;
  static const double _knobSize = 24;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final onColor = isDark ? AppColors.successDarkMode : AppColors.success;
    final offColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);
    final offBorder = isDark
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.08);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onChanged == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onChanged!(!value);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: _width,
        height: _height,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? onColor : offColor,
          borderRadius: BorderRadius.circular(_height / 2),
          border: value ? null : Border.all(color: offBorder, width: 1),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: _knobSize,
          height: _knobSize,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kichik, qattiq rangli pill/kapsula tugma — ixcham harakatlar uchun
/// (masalan bo'lim ichidagi tezkor tugma). Rang berilmasa
/// `AppColors.primary` ishlatiladi.
class LiquidPillButton extends StatelessWidget {
  const LiquidPillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.color,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    return TapScale(
      onTap: onTap,
      borderRadius: AppRadius.pillAll,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillAll,
          boxShadow: AppShadows.accent(bg, context.isDarkMode),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: context.captionStyle.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass (yarim shaffof/xira) tugma — ikkilamchi/tonal
/// harakatlar uchun, `LiquidPillButton`dan farqli o'laroq tekis rang
/// bilan emas, shisha retsepti bilan to'ladi.
class LiquidGlassButton extends StatelessWidget {
  const LiquidGlassButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.width = 85,
    this.height = 48,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(AppRadius.lg);
    return TapScale(
      onTap: onTap,
      borderRadius: br,
      child: LiquidGlassSurface(
        width: width,
        height: height,
        borderRadius: AppRadius.lg,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: context.textPrimary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.secondaryStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Doira shaklidagi frosted-glass ikonka tugmasi. `diameter` orqali
/// ham kichik (masalan 48dp) ham katta (masalan 160dp) o'lchamlar bilan
/// ishlatiladi.
class LiquidGlassCircleButton extends StatelessWidget {
  const LiquidGlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.diameter = 48,
    this.iconSize,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double diameter;
  final double? iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(diameter / 2),
      child: LiquidGlassSurface(
        width: diameter,
        height: diameter,
        borderRadius: diameter / 2,
        child: Center(
          child: Icon(
            icon,
            size: iconSize ?? diameter * 0.42,
            color: iconColor ?? context.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Qulaylik uchun o'ram — ekranlarning yuqorisidagi maxsus sarlavha
/// qatorlarida (custom header row) ishlatiladigan "orqaga" tugmasi.
/// Avval bu joylarda yalang'och `IconButton` (hech qanday fon/shisha
/// ta'sirisiz) ishlatilardi — bu ilovaning turli ekranlari orasida
/// nomuvofiqlik hissini kuchaytirgan asosiy sabablardan biri edi.
/// Endi `LiquidGlassCircleButton` ustida quriladi — 44dp minimal teginish
/// hajmi (HIG talabi) va aniq doira shakli bilan. Faqat AVTOMATIK
/// `AppBar` orqaga tugmasini ALMASHTIRMAYDI — faqat qo'lda qurilgan
/// sarlavha qatorlari uchun.
class LiquidGlassBackButton extends StatelessWidget {
  const LiquidGlassBackButton({
    super.key,
    this.onTap,
    this.diameter = 44,
    this.iconColor,
  });

  final VoidCallback? onTap;

  /// 44dp — HIG minimal teginish hajmi; bundan kichik berilsa ham
  /// shu qiymatga ko'tariladi.
  final double diameter;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final effectiveDiameter = diameter < 44 ? 44.0 : diameter;
    return LiquidGlassCircleButton(
      icon: PhosphorIconsRegular.arrowLeft,
      diameter: effectiveDiameter,
      iconSize: effectiveDiameter * 0.45,
      iconColor: iconColor,
      onTap: onTap ?? () => Navigator.of(context).pop(),
    );
  }
}
