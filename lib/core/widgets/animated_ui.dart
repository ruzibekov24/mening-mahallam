import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ilova bo'ylab qayta ishlatiladigan animatsiya/UI yordamchilari.
/// Maqsad: har bir ekranda alohida-alohida "karta + soya" yozish o'rniga
/// bitta izchil, animatsiyali bazaviy komponentlardan foydalanish.

/// Bosilganda yengil pastga (0.96x) kichrayadigan, va agar
/// [haptic] true bo'lsa yengil tebranish beradigan umumiy wrapper.
/// Barcha bosiladigan kartochkalar/tugmalar shuni ishlatishi kerak —
/// bu iOS'dagi "tactile" tugma hissini beradi.
class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;
  final BorderRadius? borderRadius;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = true,
    this.borderRadius,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Ro'yxat/gridlarda bir martalik "kirish" animatsiyasi: pastdan
/// yengil suzib chiqadi + fade-in, [index]ga qarab ketma-ket
/// (staggered) kechikish bilan boshlanadi. Faqat birinchi marta
/// ekranga chiqqanda ishlaydi (build vaqtida qayta ishga tushmaydi).
class StaggeredEntrance extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const StaggeredEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 40),
  });

  @override
  State<StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<StaggeredEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Har bir keyingi item biroz kech boshlanadi — ro'yxat "to'lqin"
    // bo'lib paydo bo'ladi, hammasi birdan emas.
    final delay = widget.baseDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Ilova bo'ylab bir xil ko'rinishdagi "surface" karta: fon rangi,
/// radius va soya bir joyda belgilanadi — har bir ekran o'zi qayta
/// yozmaydi. [onTap] berilsa avtomatik TapScale + ripple qo'shiladi.
///
/// Auditda aniqlandi: bu widget yozilgan, lekin `lib/features/` ichida
/// **0 marta** ishlatilgan edi — o'rniga 37 ta faylda 132 ta qo'lda
/// yozilgan `BoxDecoration` bor edi, har biri o'z radiusi va soyasi
/// bilan. Aynan shu ekranlarning bir-biriga o'xshamasligiga sabab edi.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;

  /// Ro'yxatdagi kartalar orasidagi pastki bo'shliq. Har bir ekranda
  /// `margin: EdgeInsets.only(bottom: 10)` yozish o'rniga.
  final EdgeInsetsGeometry? margin;

  /// Ixtiyoriy rangli chegara — masalan e'lon kategoriyasi rangida.
  final Color? borderColor;

  /// Soyani o'chirish — karta boshqa karta ichida joylashganda.
  final bool elevated;

  /// Soya o'rniga (yoki qo'shimcha) ingichka, deyarli sezilmas
  /// chegara — spetsifikatsiyadagi "scroll_edge" naqshi: oq/sirt fon +
  /// ~12% qora shaffoflikdagi 1dp chiziq. Tekis, "shisha emas" kartalar
  /// uchun — [borderColor] berilmagan bo'lsa qo'llaniladi.
  final bool hairlineBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.card,
    this.onTap,
    this.radius = AppRadius.md,
    this.color,
    this.margin,
    this.borderColor,
    this.elevated = true,
    this.hairlineBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = color ?? context.surfaceColor;
    final br = BorderRadius.circular(radius);

    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: br,
        border: borderColor != null
            ? Border.all(color: borderColor!.withValues(alpha: 0.18))
            : (hairlineBorder
                ? Border.all(color: Colors.black.withValues(alpha: 0.12))
                : null),
        boxShadow: elevated ? AppShadows.card(isDark) : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                borderRadius: br,
                onTap: null, // bosish TapScale orqali boshqariladi
                child: Padding(padding: padding, child: child),
              ),
      ),
    );

    if (onTap == null) return card;
    return TapScale(onTap: onTap, borderRadius: br, child: card);
  }
}

/// Ro'yxat ichidagi bo'lim sarlavhasi ("Qo'shnilar", "Mahalladoshlar").
/// Har bir ekranda `Padding` + `TextStyle` qo'lda yozish o'rniga.
class AppSectionHeader extends StatelessWidget {
  final String title;

  /// O'ngdagi ixtiyoriy element — masalan "Barchasi" havolasi yoki
  /// elementlar soni.
  final Widget? trailing;

  /// Birinchi bo'lim uchun tepadagi bo'shliqni olib tashlaydi.
  final bool first;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.first = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: first ? 0 : AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: context.sectionStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// "Pill" shaklidagi filtr belgisi — tanlangan/tanlanmagan holatlar
/// orasida almashadi. Ixtiyoriy [count] berilsa, o'ng tomonda kichik
/// hisoblagich ko'rsatiladi (murojaatlar boshqaruvida ishlatiladi).
///
/// Auditdan oldin bu naqsh ikkita fayl (murojaatlar ro'yxati va
/// boshqaruv paneli)da deyarli bir xil, lekin alohida-alohida yozilgan
/// edi.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? count;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : (context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightBorder),
          borderRadius: AppRadius.pillAll,
          boxShadow: isActive
              ? AppShadows.accent(AppColors.primary, context.isDarkMode)
              : null,
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: context.secondaryStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : context.textSecondary,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.xsAll,
                ),
                child: Text(
                  '$count',
                  style: context.captionStyle.copyWith(
                    color: isActive ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chapda rangli ikonka, o'ngda sarlavha + ikkilamchi matn — ilovadagi
/// eng ko'p takrorlanadigan ro'yxat elementi shakli.
///
/// Auditdan oldin bu naqsh `_EventRow`, `_MenuItem`, `_SettingsTile`,
/// `_SearchResultTile` va boshqa ~10 ta mahalliy widget'da deyarli bir
/// xil, lekin har safar boshqa o'lchamlar bilan qayta yozilgan edi.
class AppListCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const AppListCard({
    super.key,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      margin: margin,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.cardTitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: context.secondaryStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}
