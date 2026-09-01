import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import 'change_password_screen.dart';
import 'change_phone_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// Telegram uslubidagi "Maxfiylik va xavfsizlik" ekrani: oxirgi
/// faollik va telefon ko'rinishini boshqarish, bloklangan
/// foydalanuvchilar ro'yxati, parol/telefon almashtirish.
class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Row(
              children: [
                const LiquidGlassBackButton(),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.privacySecurityTitle, style: context.titleStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sectionVisibility.toUpperCase(),
                        style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.eye,
                          iconColor: AppAccents.announcements,
                          title: l10n.showLastSeenTitle,
                          subtitle: l10n.showLastSeenSubtitle,
                          trailing: LiquidToggleSwitch(
                            value: profile.lastSeenVisible,
                            onChanged: (value) => ref
                                .read(homeRepositoryProvider)
                                .setLastSeenVisible(value),
                          ),
                        ),
                        SettingsTile(
                          icon: PhosphorIconsFill.phoneOutgoing,
                          iconColor: AppAccents.requests,
                          title: l10n.showPhoneToNeighborsTitle,
                          subtitle: l10n.showPhoneToNeighborsSubtitle,
                          trailing: LiquidToggleSwitch(
                            value: profile.phoneVisible,
                            onChanged: (value) => ref
                                .read(homeRepositoryProvider)
                                .setPhoneVisible(value),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(l10n.sectionBlockedUsers.toUpperCase(),
                        style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.prohibit,
                          iconColor: AppColors.danger,
                          title: l10n.blockedUsersTitle,
                          subtitle: profile.blockedUids.isEmpty
                              ? l10n.noBlockedUsers
                              : l10n.blockedUsersCount(
                                  profile.blockedUids.length),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => BlockedUsersScreen(
                                blockedUids: profile.blockedUids,
                              ),
                            ),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(l10n.sectionAccount.toUpperCase(),
                        style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.lockKey,
                          iconColor: AppAccents.announcements,
                          title: l10n.changePasswordTitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          ),
                        ),
                        SettingsTile(
                          icon: PhosphorIconsFill.phone,
                          iconColor: AppAccents.neighbors,
                          title: l10n.changePhoneTitle,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePhoneScreen(),
                            ),
                          ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloklangan foydalanuvchilar ro'yxati — har birini bekor qilish
/// (unblock) imkoniyati bilan.
class BlockedUsersScreen extends ConsumerWidget {
  final List<String> blockedUids;
  const BlockedUsersScreen({super.key, required this.blockedUids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.blockedUsersTitle, style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: blockedUids.isEmpty
                  ? AppEmptyView(
                      icon: PhosphorIconsFill.prohibit,
                      title: l10n.noBlockedUsers,
                      accent: AppColors.danger,
                    )
                  : FutureBuilder<List<MahallaMember>>(
                      future: ref
                          .read(homeRepositoryProvider)
                          .fetchMembersByUids(blockedUids),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return ListView(
                            padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                                AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                            physics: const NeverScrollableScrollPhysics(),
                            children: const [ShimmerList(count: 4)],
                          );
                        }
                        final members = snapshot.data!;
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                              AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            final member = members[index];
                            final fullName =
                                '${member.firstName} ${member.lastName}'
                                    .trim();
                            return AppCard(
                              margin:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Row(
                                children: [
                                  UserAvatar(
                                    size: 40,
                                    firstName: member.firstName,
                                    lastName: member.lastName,
                                    photoUrl: member.photoUrl,
                                    seed: member.uid,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Text(
                                      fullName,
                                      style: context.cardTitleStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await ref
                                          .read(homeRepositoryProvider)
                                          .unblockUser(member.uid);
                                      if (context.mounted) {
                                        showAppAlert(context, l10n.userUnblockedMessage(
                                                    fullName));
                                      }
                                    },
                                    child: Text(l10n.unblockAction),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
