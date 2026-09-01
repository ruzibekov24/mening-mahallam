import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../data/home_repository.dart';

/// Foydalanuvchi roli uchun vizual uslublar.
///
/// Auditdan oldin `_roleColor` funksiyasi **beshta faylda bayt-ma-bayt
/// bir xil** ko'chirilgan edi (home_screen, neighbors_screen,
/// neighbor_profile_screen, members_management_screen va uning o'lik
/// nusxasi), va ranglar `AppColors`da umuman yo'q edi.
extension UserRoleStyle on UserRole {
  /// Rol rangi — teg, halqa va badge'lar uchun.
  Color get color {
    switch (this) {
      case UserRole.rais:
        return AppAccents.neighbors;
      case UserRole.staff:
        return AppAccents.announcements;
      case UserRole.citizen:
        return AppAccents.neutral;
      case UserRole.superAdmin:
        return const Color(0xFF111111);
    }
  }

  /// Oddiy fuqarodan farqli — ya'ni avatarda halqa va badge ko'rsatiladi.
  bool get isHighlighted => this != UserRole.citizen;

  /// Avatar atrofidagi halqa rangi. Oddiy fuqaroda halqa yo'q, shuning
  /// uchun `null` — bu ro'yxatni shovqinsiz saqlaydi va xodimlarni
  /// darhol ko'zga tashlanadigan qiladi.
  Color? get ringColor => isHighlighted ? color : null;
}

/// Avatar halqasi rangi — FAQAT rol asosida (rais/xodim). Premium endi
/// halqa bilan emas, tanlanadigan `PremiumBadge` uslubi bilan
/// ko'rsatiladi (`premium_badge_styles.dart`) — oltin halqa hamma
/// premium obunachida bir xil ko'rinardi va rais/xodim halqasidan farqi
/// past yorug'likda deyarli sezilmasdi.
Color? avatarRingColor(UserRole role) => role.ringColor;

/// Rol tegi ("Rais", "Xodim") — ism yonida ko'rsatiladi.
///
/// Auditdan oldin bu teg to'rtta ekranda qo'lda, har safar boshqa
/// padding va shrift o'lchami bilan yozilgan edi.
class RoleBadge extends StatelessWidget {
  final UserRole role;

  /// Xodimning aniq lavozimi (masalan "Kotib"). Berilsa rol nomi
  /// o'rniga shu ko'rsatiladi.
  final String? staffTitle;

  /// Kattaroq variant — profil sahifasi uchun.
  final bool large;

  const RoleBadge({
    super.key,
    required this.role,
    this.staffTitle,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!role.isHighlighted) return const SizedBox.shrink();

    final color = role.color;
    final label = (staffTitle != null && staffTitle!.trim().isNotEmpty)
        ? staffTitle!.trim()
        : role.label;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? AppSpacing.md : AppSpacing.sm,
        vertical: large ? AppSpacing.xs : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.xsAll,
      ),
      child: Text(
        label,
        style: (large ? context.secondaryStyle : context.captionStyle)
            .copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}
