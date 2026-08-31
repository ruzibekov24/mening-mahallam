import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/presentation/role_styles.dart' show kPremiumRingColor;

/// Premium foydalanuvchini belgilaydigan chizim — bir tomdan (crown
/// ikonka) tashkil topgan yalang'och belgi o'rniga, endi to'liq "pill"
/// (tepasi/tagi yumaloqlangan) chip: ikonka + "Premium" matni. Ism
/// yonida (profil, qo'shni profili) va boshqa joylarda bir xil
/// ko'rinishda ishlatiladi.
///
/// `onDark: true` — rangli/qorong'i fon ustida (masalan profil
/// ekranining banner qismi) ishlatilganda, oq-shaffof fon + och sariq
/// matn bilan; aks holda och sariq fon + to'q sariq matn bilan.
class PremiumBadge extends StatelessWidget {
  final bool onDark;
  final bool compact;

  const PremiumBadge({super.key, this.onDark = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const gold = kPremiumRingColor;
    final background =
        onDark ? Colors.white.withValues(alpha: 0.2) : gold.withValues(alpha: 0.14);
    final foreground = onDark ? const Color(0xFFFFE29A) : gold;

    return Tooltip(
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
              : Border.all(color: gold.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.crown, size: compact ? 11 : 13, color: foreground),
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
  }
}
