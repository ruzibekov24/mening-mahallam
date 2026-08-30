import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../features/qr/presentation/qr_scan_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'animated_ui.dart';
import 'app_feedback.dart';

/// Hali mahallaga qo'shilmagan foydalanuvchi uchun umumiy ko'rinish.
///
/// Ro'yxatdan o'tgan har bir foydalanuvchida `mahallaId == null` bo'ladi
/// va u mahallaga qo'shilmaguncha ilovaning katta qismi bo'sh bo'ladi.
/// Ilgari bunday joylar jimgina `SizedBox.shrink()` qaytarardi —
/// natijada foydalanuvchi hech qanday tushuntirishsiz oq ekran ko'rardi
/// va nima qilish kerakligini bilmasdi.
///
/// Endi hamma shunday joyda shu widget ko'rsatiladi: nima uchun bo'sh
/// ekanini tushuntiradi va QR skanerga olib boradi.
class NoMahallaView extends StatelessWidget {
  /// `RefreshIndicator` ichida ishlatilganda `true` bering.
  final bool scrollable;

  const NoMahallaView({super.key, this.scrollable = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppEmptyView(
      icon: PhosphorIconsFill.qrCode,
      title: l10n.noMahallaTitle,
      subtitle: l10n.noMahallaSubtitle,
      actionLabel: l10n.noMahallaAction,
      scrollable: scrollable,
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      ),
    );
  }
}

/// [NoMahallaView]ning ixcham, banner ko'rinishi.
///
/// Bosh sahifada bir nechta bo'lim (xodimlar, xarita, bannerlar) bir
/// vaqtning o'zida bo'sh bo'ladi. Har biriga to'liq bo'sh holat
/// qo'yilsa, bitta ekranda uchta bir xil kartochka chiqadi. Shuning
/// uchun sahifaning tepasida BITTA shu banner ko'rsatiladi, qolgan
/// bo'limlar esa jimgina yashiriladi — sabab allaqachon tushuntirilgan.
class NoMahallaBanner extends StatelessWidget {
  const NoMahallaBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;

    return TapScale(
      borderRadius: AppRadius.mdAll,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const QrScanScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.08),
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.qrCode,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.noMahallaTitle, style: context.cardTitleStyle),
                  const SizedBox(height: 2),
                  Text(
                    l10n.noMahallaAction,
                    style: context.captionStyle.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(PhosphorIconsBold.caretRight,
                size: 16, color: context.textMuted),
          ],
        ),
      ),
    );
  }
}
