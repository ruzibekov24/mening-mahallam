import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ilova bo'ylab ko'rinadigan, ingichka oflayn ogohlantirish paneli.
///
/// Firestore keshi tufayli ilova internetsiz ham ishlashda davom
/// etadi (oxirgi ko'rilgan ma'lumotlar), lekin foydalanuvchi buni
/// bilmasa — nega ro'yxat yangilanmayapti yoki nega yuborilgan
/// murojaat "yuklanmoqda"da qolib ketganini tushunmay qoladi. Bu
/// banner shu holatni ANIQ ko'rsatadi.
///
/// `MainShell`ning o'zidagi `AnimatedSwitcher` naqshiga mos ravishda
/// shu yerda ham fade + slide bilan kirib-chiqadi — qattiq
/// show/hide o'rniga.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final isDark = context.isDarkMode;
    final color = isDark ? AppColors.dangerDarkMode : AppColors.danger;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: isOnline
          ? const SizedBox.shrink(key: ValueKey('online'))
          : _BannerContent(key: const ValueKey('offline'), color: color),
    );
  }
}

class _BannerContent extends StatelessWidget {
  final Color color;

  const _BannerContent({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          color: color,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 16, color: Colors.white),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.offlineBannerMessage,
                style: context.captionStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
