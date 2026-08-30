import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../profile/data/profile_banners.dart';
import '../data/home_repository.dart';
import 'role_styles.dart';
import '../../../core/widgets/app_alert.dart';

/// Bitta qo'shnining profilini ko'rsatadi — qo'ng'iroq qilish va
/// ilova ichida xabar yozish (chat) imkoniyati bilan.
class NeighborProfileScreen extends ConsumerWidget {
  final MahallaMember member;
  const NeighborProfileScreen({super.key, required this.member});

  Future<void> _confirmBlock(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final fullName = '${member.firstName} ${member.lastName}'.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.danger.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(PhosphorIconsFill.prohibit, color: AppColors.danger),
        ),
        title: Text(l10n.blockUserConfirmTitle),
        content: Text(l10n.blockUserConfirmMessage(fullName)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smAll,
              ),
            ),
            child: Text(l10n.blockUserAction),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(homeRepositoryProvider).blockUser(member.uid);
      if (context.mounted) {
        Navigator.of(context).pop();
        showAppAlert(context, l10n.userBlockedMessage(fullName));
      }
    }
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final roleColor = member.role.color;
    final fullName = '${member.firstName} ${member.lastName}'.trim();

    return Scaffold(
      body: Stack(
        children: [
          // Yuqoridagi "cover" — egasi tanlagan haqiqiy profil banneri
          // (yoki tanlamagan bo'lsa, standart banner) ko'rsatiladi, xuddi
          // o'z profilingizdagidek. Avvalroq bu yerda faqat rolga bog'liq
          // rangli gradient bo'lardi, haqiqiy banner ko'rinmasdi.
          _CoverBanner(
            bannerId: member.profileBannerId,
            fallbackColor: roleColor,
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm,
                      AppSpacing.xs, AppSpacing.lg, AppSpacing.xs),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(PhosphorIconsRegular.arrowLeft),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: const Icon(PhosphorIconsRegular.dotsThreeVertical),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll,
                        ),
                        onSelected: (value) {
                          if (value == 'block') {
                            _confirmBlock(context, ref, l10n);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.prohibit,
                                    size: 18, color: AppColors.danger),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  l10n.blockUserAction,
                                  style: context.bodyStyle
                                      .copyWith(color: AppColors.danger),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        // Qo'shnilar ro'yxatidagi avatar shu yerga
                        // "uchib" keladi — sahifa to'satdan almashmaydi.
                        child: Hero(
                          tag: 'member-avatar-${member.uid}',
                          child: UserAvatar(
                            size: 108,
                            firstName: member.firstName,
                            lastName: member.lastName,
                            photoUrl: member.photoUrl,
                            seed: member.uid,
                            ringColor: avatarRingColor(member.role,
                isPremium: member.isPremiumActive),
                            isOnline: member.isOnline,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                fullName.isEmpty ? l10n.notSpecified : fullName,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: context.titleStyle,
                              ),
                            ),
                            if (member.isPremiumActive) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Tooltip(
                                message: l10n.premiumBadgeLabel,
                                child: const Icon(PhosphorIconsFill.crown,
                                    size: 18, color: Color(0xFFE0A526)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (member.role.isHighlighted) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: RoleBadge(
                            role: member.role,
                            staffTitle: member.staffTitle,
                            large: true,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          member.isOnline
                              ? l10n.onlineNow
                              : l10n.lastSeenUnknown,
                          style: context.secondaryStyle.copyWith(
                            color: member.isOnline
                                ? AppColors.success
                                : context.textSecondary,
                            fontWeight: member.isOnline
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      AppListCard(
                        icon: PhosphorIconsFill.chatDots,
                        accent: AppColors.primary,
                        title: l10n.sendMessageAction,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(otherUid: member.uid),
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      ),

                      if (member.phoneVisible && member.phone.isNotEmpty)
                        AppListCard(
                          icon: PhosphorIconsFill.phone,
                          accent: AppColors.primary,
                          title: formatPhoneNumber(member.phone),
                          onTap: () => _launchCall(member.phone),
                          margin: EdgeInsets.zero,
                        )
                      else
                        AppListCard(
                          icon: PhosphorIconsFill.lock,
                          accent: AppAccents.neutral,
                          title: l10n.phoneHiddenByUser,
                          margin: EdgeInsets.zero,
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profil tepasidagi banner — egasi tanlagan haqiqiy banner (surat
/// yoki gradient), pastga qarab fon rangiga yumshoq singib ketadi,
/// shuning uchun aniq chegara ko'rinmaydi. Foydalanuvchi hech qanday
/// banner tanlamagan bo'lsa, katalogdagi standart bannerga qaytadi
/// ([bannerById] xatti-harakati) — [fallbackColor] faqat shu standart
/// banner ustidagi yumshoq rang tusini rolga moslash uchun.
class _CoverBanner extends StatelessWidget {
  final String? bannerId;
  final Color fallbackColor;
  const _CoverBanner({required this.bannerId, required this.fallbackColor});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final banner = bannerById(bannerId);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 260,
      child: DecoratedBox(
        decoration: banner.decoration(),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                fallbackColor.withValues(alpha: isDark ? 0.12 : 0.06),
                bg,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
