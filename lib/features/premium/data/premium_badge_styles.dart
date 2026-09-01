import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';

/// Premium foydalanuvchi tanlashi mumkin bo'lgan `PremiumBadge`
/// ko'rinishlaridan biri — ikonka + rang.
///
/// Ilgari premium bitta doimiy oltin belgi bilan ko'rsatilardi (va
/// avatarda ham oltin halqa bo'lardi). Endi halqa umuman yo'q
/// (`role_styles.dart`dagi `avatarRingColor`ga qarang) — premium'ning
/// yagona vizual imzosi shu belgi, shuning uchun uni tanlash mumkin
/// bo'lishi kerak edi. Barcha uslublar bir xil huquqqa ega (hech biri
/// boshqasidan "yuqoriroq" tarif emas) — bu faqat kosmetik tanlov, xuddi
/// profil banneri kabi.
class PremiumBadgeStyle {
  final String id;
  final String labelKey;
  final IconData icon;
  final Color color;

  const PremiumBadgeStyle({
    required this.id,
    required this.labelKey,
    required this.icon,
    required this.color,
  });
}

/// Standart uslub — mavjud premium foydalanuvchilar hali tanlov
/// qilmagan bo'lsa, avvalgi (yagona) oltin ko'rinish saqlanib qoladi,
/// hech kimning belgisi "sindirilmaydi".
const String kDefaultPremiumBadgeStyleId = 'gold';

/// Barcha mavjud badge uslublari — ranglar iloji boricha
/// `AppAccents`/`AppColors`dagi mavjud akцентlardan olingan, yangi
/// hex qiymat faqat oltin uchun (bu avvalgi `kPremiumRingColor` bilan
/// bir xil, orqaga moslik uchun).
const premiumBadgeStyles = <PremiumBadgeStyle>[
  PremiumBadgeStyle(
    id: 'gold',
    labelKey: 'gold',
    icon: PhosphorIconsFill.crown,
    color: Color(0xFFE0A526),
  ),
  PremiumBadgeStyle(
    id: 'sapphire',
    labelKey: 'sapphire',
    icon: PhosphorIconsFill.star,
    color: AppColors.primary,
  ),
  PremiumBadgeStyle(
    id: 'emerald',
    labelKey: 'emerald',
    icon: PhosphorIconsFill.leaf,
    color: AppAccents.requests,
  ),
  PremiumBadgeStyle(
    id: 'ruby',
    labelKey: 'ruby',
    icon: PhosphorIconsFill.heart,
    color: AppColors.danger,
  ),
  PremiumBadgeStyle(
    id: 'silver',
    labelKey: 'silver',
    icon: PhosphorIconsFill.shieldCheck,
    color: AppAccents.neutral,
  ),
];

/// `id` bo'yicha uslubni topadi — mos kelmasa yoki `null` bo'lsa,
/// standart (oltin) uslubga tushadi.
PremiumBadgeStyle premiumBadgeStyleById(String? id) {
  return premiumBadgeStyles.firstWhere(
    (s) => s.id == id,
    orElse: () => premiumBadgeStyles.first,
  );
}
