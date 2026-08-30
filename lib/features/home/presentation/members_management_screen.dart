import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../data/home_repository.dart';
import 'role_styles.dart';
import '../../../core/widgets/app_alert.dart';

/// Rais uchun — mahalladagi barcha a'zolarni ko'rish va rolini
/// o'zgartirish (fuqaro -> xodim -> rais). Faqat role.canManageMembers
/// bo'lgan foydalanuvchi bu ekranga kira oladi (chaqiruvchi tomonda
/// tekshiriladi).
class MembersManagementScreen extends ConsumerWidget {
  final String mahallaId;
  const MembersManagementScreen({super.key, required this.mahallaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(mahallaMembersProvider(mahallaId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.membersManagementTitle,
                      style: context.titleStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: membersAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.usersThree,
                      title: l10n.noMembersYet,
                      accent: AppAccents.neighbors,
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      return StaggeredEntrance(
                        index: index,
                        child: _MemberTile(member: members[index]),
                      );
                    },
                  );
                },
                // Auditdan oldin bu yerda markazda aylanuvchi doira
                // turardi — endi kontent shaklidagi skeleton, ya'ni
                // ro'yxat nima bilan to'lishini oldindan ko'rsatadi.
                loading: () => ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [ShimmerList(count: 6)],
                ),
                error: (error, _) => AppErrorView.fromError(
                  error,
                  onRetry: () =>
                      ref.invalidate(mahallaMembersProvider(mahallaId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final MahallaMember member;
  const _MemberTile({required this.member});

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    UserRole newRole,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(homeRepositoryProvider).updateMemberRole(
            uid: member.uid,
            role: newRole,
          );
      if (context.mounted) {
        showAppAlert(context, l10n.roleUpdated);
      }
    } catch (_) {
      if (context.mounted) {
        showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleColor = member.role.color;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          UserAvatar(
            size: 44,
            firstName: member.firstName,
            lastName: member.lastName,
            photoUrl: member.photoUrl,
            seed: member.uid,
            ringColor: avatarRingColor(member.role,
                isPremium: member.isPremiumActive),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.firstName} ${member.lastName}'.trim(),
                  style: context.cardTitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(formatPhoneNumber(member.phone), style: context.secondaryStyle),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TapScale(
            onTap: () => _showRolePicker(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.smAll,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    member.role.label,
                    style: context.captionStyle.copyWith(color: roleColor),
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Icon(PhosphorIconsRegular.caretDown,
                      size: 12, color: roleColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRolePicker(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      // Bu ekran Navigator.push bilan ochiladi — orqasida
      // MainShell foni YO'Q. Shaffof qoldirilsa ekran qop-qora
      // bo'lib ko'rinardi. Rang berilmasa mavzudagi
      // `scaffoldBackgroundColor` ishlaydi (dark mode ham).
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sudrash uchun ishora chizig'i — sheet ekanini
                // ko'rsatadi.
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: AppRadius.xsAll,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(l10n.selectRoleTitle,
                      style: context.cardTitleStyle),
                ),
                // superAdmin bu ro'yxatda ko'rsatilmaydi — bu rol faqat
                // Firebase Console orqali qo'lda beriladi, rais orqali
                // hech kimni shu darajaga ko'tarib bo'lmasligi kerak.
                for (final role in UserRole.values
                    .where((r) => r != UserRole.superAdmin))
                  ListTile(
                    leading: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: role.color.withValues(alpha: 0.12),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(
                        role == UserRole.rais
                            ? PhosphorIconsFill.crown
                            : role == UserRole.staff
                                ? PhosphorIconsFill.briefcase
                                : PhosphorIconsFill.user,
                        size: 17,
                        color: role.color,
                      ),
                    ),
                    title: Text(role.label, style: context.bodyStyle),
                    trailing: role == member.role
                        ? const Icon(PhosphorIconsFill.checkCircle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      if (role != member.role) {
                        _changeRole(context, ref, role);
                      }
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
