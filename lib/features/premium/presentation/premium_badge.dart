import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../data/premium_badge_styles.dart';

/// Premium foydalanuvchini belgilaydigan chizim — bir tomdan (crown
/// ikonka) tashkil topgan yalang'och belgi o'rniga, endi to'liq "pill"
/// (tepasi/tagi yumaloqlangan) chip: ikonka + "Premium" matni. Ism
/// yonida (profil, qo'shni profili) va boshqa joylarda bir xil
/// ko'rinishda ishlatiladi.
///
/// `onDark: true` — rangli/qorong'i fon ustida (masalan profil
/// ekranining banner qismi) ishlatilganda, oq-shaffof fon + och sariq
/// matn bilan; aks holda och sariq fon + to'q sariq matn bilan.
///
/// `styleId` — `premium_badge_styles.dart`dagi katalogdan tanlangan
/// ikonka/rang ("gold", "sapphire" ...); `null` yoki noma'lum bo'lsa
/// standart (oltin) uslubga tushadi — shuning uchun eski, hali tanlov
/// qilmagan premium foydalanuvchilarda hech narsa o'zgarmaydi.
class PremiumBadge extends StatelessWidget {
  final bool onDark;
  final bool compact;
  final String? styleId;

  /// Berilsa, belgi bosiladigan qiladi — faqat o'z profilida, uslub
  /// tanlash varag'ini ochish uchun ishlatiladi. Boshqa foydalanuvchi
  /// profilida `null` qoladi (faqat ko'rish uchun).
  final VoidCallback? onTap;

  const PremiumBadge({
    super.key,
    this.onDark = false,
    this.compact = false,
    this.styleId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = premiumBadgeStyleById(styleId);
    final accent = style.color;
    final background =
        onDark ? Colors.white.withValues(alpha: 0.2) : accent.withValues(alpha: 0.14);
    final foreground = onDark ? Colors.white : accent;

    final badge = Tooltip(
      message: l10n.premiumBadgeLabel,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : AppSpacing.sm,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.pillAll,
          border: onDark
              ? null
              : Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, size: compact ? 11 : 13, color: foreground),
            if (!compact) ...[
              const SizedBox(width: 4),
              Text(
                l10n.premiumBadgeLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return badge;
    return GestureDetector(onTap: onTap, child: badge);
  }
}
