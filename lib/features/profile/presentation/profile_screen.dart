import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/mahalla_switcher_screen.dart';
import '../../auth/data/auth_repository.dart';
import '../../chat/data/chat_providers.dart';
import '../../banners/presentation/banner_management_screen.dart';
import '../../chat/presentation/conversations_screen.dart';
import '../../feedback/presentation/feedback_list_screen.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/role_styles.dart';
import '../../requests/presentation/request_detail_screen.dart';
import '../../premium/presentation/premium_badge.dart';
import '../../premium/presentation/premium_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/profile_activity_providers.dart';
import '../data/profile_banners.dart';
import 'edit_profile_screen.dart';
import 'help_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// 13. PROFIL ekrani.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
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
          child: const Icon(
            PhosphorIconsFill.signOut,
            color: AppColors.danger,
          ),
        ),
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
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
            child: Text(l10n.logoutMenuItem),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
      // Chiqishdan keyin router avtomatik Login ekraniga yo'naltiradi
      // (auth holatini kuzatuvchi redirect logikasi orqali).
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final mahallaNameAsync = ref.watch(currentMahallaNameProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            profileAsync.when(
              data: (profile) => _ProfileBannerHeader(
                profile: profile,
                mahallaNameAsync: mahallaNameAsync,
              ),
              loading: () => _ProfileBannerHeader(
                profile: null,
                mahallaNameAsync: mahallaNameAsync,
              ),
              error: (_, __) => _ProfileBannerHeader(
                profile: null,
                mahallaNameAsync: mahallaNameAsync,
              ),
            ),
            Expanded(
              child: ListView(
                padding: AppSpacing.listPadding,
                children: [
                  profileAsync.when(
                    data: (profile) {
                      if (profile != null &&
                          (profile.displayAddress?.isNotEmpty == true ||
                              profile.birthDate != null ||
                              profile.gender != null)) {
                        return _InfoRowsCard(profile: profile, l10n: l10n);
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => Text(
                      l10n.profileLoadError,
                      style: context.secondaryStyle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Faollik statistikasi — yuborilgan murojaatlar, e'lonlar
                  // (agar xodim/rais bo'lsa), qo'shilingan ommaviy murojaatlar.
                  const _ActivityStatsRow(),
                  const SizedBox(height: AppSpacing.xl),

                  profileAsync.when(
                    data: (profile) {
                      if (profile == null) return const SizedBox.shrink();
                      return _MyActivitySection(profile: profile);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: PhosphorIconsFill.userCircle,
                        label: l10n.myInfoMenuItem,
                        iconColor: AppAccents.announcements,
                        onTap: () => AppPageRoute.push(
                            context, const EditProfileScreen()),
                      ),
                      Consumer(
                        builder: (context, ref, _) {
                          final unread = ref
                                  .watch(totalUnreadMessagesProvider)
                                  .valueOrNull ??
                              0;
                          return _MenuItem(
                            icon: PhosphorIconsFill.chatDots,
                            label: l10n.conversationsMenuItem,
                            iconColor: AppColors.primary,
                            badgeCount: unread,
                            onTap: () => AppPageRoute.push(
                                context, const ConversationsScreen()),
                          );
                        },
                      ),
                      _MenuItem(
                        icon: PhosphorIconsFill.bell,
                        label: l10n.notificationsMenuItem,
                        iconColor: AppAccents.events,
                        onTap: () =>
                            AppPageRoute.push(context, const SettingsScreen()),
                      ),
                      // Premium — Profil menyusining o'zida. Ilgari u faqat
                      // Sozlamalar ichida edi va amalda topilmasdi.
                      _MenuItem(
                        icon: PhosphorIconsFill.crown,
                        label: l10n.premiumTitle,
                        iconColor: const Color(0xFFE0A526),
                        onTap: () =>
                            AppPageRoute.push(context, const PremiumScreen()),
                      ),
                      _MenuItem(
                        icon: PhosphorIconsFill.gearSix,
                        label: l10n.settingsMenuItem,
                        iconColor: AppAccents.neighbors,
                        onTap: () =>
                            AppPageRoute.push(context, const SettingsScreen()),
                      ),
                      _MenuItem(
                        icon: PhosphorIconsFill.question,
                        label: l10n.helpMenuItem,
                        iconColor: AppAccents.requests,
                        onTap: () =>
                            AppPageRoute.push(context, const HelpScreen()),
                        showDivider: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  profileAsync.when(
                    data: (profile) {
                      if (profile?.role.isSuperAdmin != true) {
                        return const SizedBox.shrink();
                      }
                      final override = ref.watch(activeMahallaOverrideProvider);
                      return Column(
                        children: [
                          _MenuCard(
                            children: [
                              _MenuItem(
                                icon: PhosphorIconsFill.buildings,
                                label: override == null
                                    ? l10n.switchMahallaMenuItem
                                    : l10n.switchMahallaMenuItemActive,
                                iconColor: AppColors.danger,
                                onTap: () => AppPageRoute.push(
                                    context, const MahallaSwitcherScreen()),
                              ),
                              _MenuItem(
                                icon: PhosphorIconsFill.star,
                                label: l10n.feedbackListTitle,
                                iconColor: AppAccents.events,
                                onTap: () => AppPageRoute.push(
                                    context, const FeedbackListScreen()),
                              ),
                              _MenuItem(
                                icon: PhosphorIconsFill.image,
                                label: l10n.bannerManagementTitle,
                                iconColor: AppAccents.neighbors,
                                onTap: () => AppPageRoute.push(
                                    context, const BannerManagementScreen()),
                                showDivider: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  _MenuCard(
                    children: [
                      _MenuItem(
                        icon: PhosphorIconsFill.signOut,
                        label: l10n.logoutMenuItem,
                        iconColor: AppColors.danger,
                        labelColor: AppColors.danger,
                        onTap: () => _confirmLogout(context, ref),
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profil qopqog'i — ism, unvon, telefon va rasm hammasi tanlangan
/// banner (surat yoki gradient) ustida, oq matn bilan ko'rsatiladi
/// (Facebook/Twitter uslubidagi cover-photo, lekin ism/unvon ham
/// qopqoq ichida — pastdagi oq sahifaga chiqarilmaydi).
class _ProfileBannerHeader extends StatelessWidget {
  final UserProfile? profile;
  final AsyncValue<String?> mahallaNameAsync;
  const _ProfileBannerHeader({
    required this.profile,
    required this.mahallaNameAsync,
  });

  static const double _avatarSize = 84;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final banner = bannerById(profile?.profileBannerId);
    final fullName = profile == null
        ? l10n.defaultUserName
        : '${profile!.firstName} ${profile!.lastName}'.trim();
    final phone = profile?.phone ?? '';

    return Container(
      width: double.infinity,
      decoration: banner.decoration().copyWith(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
          ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(28),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                right: AppSpacing.md,
                child: _ChangeBannerButton(
                  currentBannerId: banner.id,
                  isPremiumActive: profile?.isPremiumActive == true,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar.fromFullName(
                      size: _avatarSize,
                      fullName: fullName,
                      photoUrl: profile?.photoUrl,
                      seed: profile?.phone,
                      // Premium halqasi o'z profilida ham ko'rinadi —
                      // ilgari u faqat boshqalar ro'yxatida chizilardi
                      // va obunachi o'zi to'lagan narsani ko'rmasdi.
                      ringColor: profile == null
                          ? null
                          : avatarRingColor(profile!.role,
                              isPremium: profile!.isPremiumActive),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            fullName,
                            overflow: TextOverflow.ellipsis,
                            style: context.titleStyle
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        if (profile?.verifiedBadge == true) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(PhosphorIconsFill.sealCheck,
                              size: 18, color: Colors.white),
                        ],
                        if (profile?.isPremiumActive == true) ...[
                          const SizedBox(width: AppSpacing.xs),
                          const PremiumBadge(onDark: true),
                        ],
                      ],
                    ),
                    if (profile != null && profile!.role.isHighlighted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _RoleBadge(
                        role: profile!.role,
                        staffTitle: profile!.staffTitle,
                        mahallaNameAsync: mahallaNameAsync,
                      ),
                    ],
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        formatPhoneNumber(phone),
                        style: context.secondaryStyle.copyWith(
                            color: Colors.white.withValues(alpha: 0.85)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Banner ustidagi tahrirlash tugmasi — bosilganda tanlov varag'ini
/// ochadi.
class _ChangeBannerButton extends ConsumerWidget {
  final String currentBannerId;
  final bool isPremiumActive;
  const _ChangeBannerButton({
    required this.currentBannerId,
    required this.isPremiumActive,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _showBannerPicker(
          context,
          ref,
          currentBannerId,
          isPremiumActive: isPremiumActive,
        ),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(PhosphorIconsFill.pencilSimple,
              size: 16, color: Colors.white),
        ),
      ),
    );
  }
}

Future<void> _showBannerPicker(
  BuildContext context,
  WidgetRef ref,
  String currentBannerId, {
  required bool isPremiumActive,
}) async {
  final l10n = AppLocalizations.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => _BannerPickerSheet(
      currentBannerId: currentBannerId,
      isPremiumActive: isPremiumActive,
      onSelected: (bannerId) async {
        Navigator.of(sheetContext).pop();
        try {
          await ref.read(authRepositoryProvider).updateProfileBanner(bannerId);
        } catch (_) {
          if (context.mounted) {
            showAppAlert(context, l10n.profileLoadError);
          }
        }
      },
    ),
  );
}

class _BannerPickerSheet extends StatelessWidget {
  final String currentBannerId;
  final bool isPremiumActive;
  final ValueChanged<String> onSelected;

  const _BannerPickerSheet({
    required this.currentBannerId,
    required this.isPremiumActive,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.lgAll,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chooseBannerTitle, style: context.titleStyle),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: profileBanners.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) {
                  final banner = profileBanners[index];
                  final isSelected = banner.id == currentBannerId;
                  final locked = banner.isPremium && !isPremiumActive;
                  return _BannerOptionTile(
                    banner: banner,
                    isSelected: isSelected,
                    locked: locked,
                    onTap: () {
                      if (locked) {
                        showAppAlert(context, l10n.premiumBannerLockedMessage);
                        return;
                      }
                      onSelected(banner.id);
                    },
                  );
                },
              ),
            ),
            if (profileBanners.any((b) => b.attribution != null)) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                profileBanners
                    .where((b) => b.attribution != null)
                    .map((b) => b.attribution!)
                    .join('\n'),
                style: context.captionStyle.copyWith(color: context.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BannerOptionTile extends StatelessWidget {
  final ProfileBanner banner;
  final bool isSelected;
  final bool locked;
  final VoidCallback onTap;

  const _BannerOptionTile({
    required this.banner,
    required this.isSelected,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Container(
        decoration: banner.decoration().copyWith(
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
        child: Stack(
          children: [
            if (locked)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: AppRadius.mdAll,
                  ),
                ),
              ),
            if (locked)
              const Center(
                child: Icon(PhosphorIconsFill.lockSimple,
                    color: Colors.white, size: 22),
              ),
            if (isSelected && !locked)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(PhosphorIconsFill.check,
                      size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<Widget> children;
  const _MenuCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? labelColor;
  final bool showDivider;

  /// O'qilmagan xabarlar/bildirishnomalar soni — berilsa, o'ng
  /// tomonda kichik qizil belgi sifatida ko'rsatiladi.
  final int badgeCount;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.labelColor,
    this.showDivider = true,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? context.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: showDivider
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.borderColor, width: 0.5),
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, size: 18, color: effectiveIconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.bodyStyle.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.sm),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: const BoxDecoration(
                    color: AppColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (labelColor == null)
                Icon(PhosphorIconsRegular.caretRight,
                    size: 18, color: context.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rol/lavozim belgisi — rais/xodim uchun rangli, ko'zga tashlanadigan
/// badge (avvalgi shunchaki matn qatoridan farqli).
class _RoleBadge extends StatelessWidget {
  final UserRole role;
  final String? staffTitle;
  final AsyncValue<String?> mahallaNameAsync;

  const _RoleBadge({
    required this.role,
    required this.staffTitle,
    required this.mahallaNameAsync,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = staffTitle?.isNotEmpty == true ? staffTitle! : role.label;
    final label = switch (mahallaNameAsync) {
      AsyncData(:final value) when value != null => '$subtitle · $value',
      _ => subtitle,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: AppRadius.pillAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            role == UserRole.superAdmin
                ? PhosphorIconsFill.shieldStar
                : role == UserRole.rais
                    ? PhosphorIconsFill.crown
                    : PhosphorIconsFill.identificationBadge,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.secondaryStyle
                .copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Manzil, tug'ilgan sana, jins — profilda to'ldirilgan bo'lsa
/// ko'rsatiladigan qo'shimcha ma'lumot qatorlari.
class _InfoRowsCard extends StatelessWidget {
  final UserProfile profile;
  final AppLocalizations l10n;
  const _InfoRowsCard({required this.profile, required this.l10n});

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    // Telefon — eng ko'p kerak bo'ladigan ma'lumot, lekin ilgari bu
    // kartochkada umuman ko'rsatilmasdi va foydalanuvchi o'zi qaysi
    // raqam bilan ro'yxatdan o'tganini ko'rolmasdi.
    if (profile.phone.isNotEmpty) {
      rows.add(_InfoRow(
        icon: PhosphorIconsRegular.phone,
        label: l10n.phoneLabel,
        value: formatPhoneNumber(profile.phone),
      ));
    }
    if (profile.displayAddress?.isNotEmpty == true) {
      rows.add(_InfoRow(
        icon: PhosphorIconsRegular.mapPin,
        label: l10n.addressLabel,
        value: profile.displayAddress!,
      ));
    }
    if (profile.birthDate != null) {
      rows.add(_InfoRow(
        icon: PhosphorIconsRegular.cake,
        label: l10n.birthDateLabel,
        value: _formatDate(profile.birthDate!),
      ));
    }
    if (profile.gender != null) {
      rows.add(_InfoRow(
        icon: PhosphorIconsRegular.userCircle,
        label: l10n.genderLabel,
        value: profile.gender == UserGender.male
            ? l10n.genderMale
            : l10n.genderFemale,
      ));
    }
    // Obuna holati — premium bo'lganda qachon tugashi ko'rinib
    // tursin, aks holda foydalanuvchi buni faqat Premium ekranini
    // ochib bilib olardi.
    if (profile.isPremiumActive) {
      rows.add(_InfoRow(
        icon: PhosphorIconsFill.crown,
        label: l10n.premiumTitle,
        value: l10n.premiumUntilShort(_formatDate(profile.premiumUntil!)),
        valueColor: const Color(0xFFE0A526),
      ));
    }

    // Qatorlar orasiga ingichka ajratgich — endi qatorlar ikki
    // satrdan iborat bo'lgani uchun ajratgichsiz ular bir-biriga
    // qo'shilib ketardi.
    final separated = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      separated.add(rows[i]);
      if (i != rows.length - 1) {
        separated.add(Padding(
          // Ajratgich ikonka ustunidan keyin boshlanadi — iOS/Telegram
          // ro'yxatlaridagi kabi.
          padding: const EdgeInsets.only(left: 34),
          child: Divider(height: 1, color: context.borderColor),
        ));
      }
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      elevated: false,
      child: Column(children: separated),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// Qiymat rangi — odatda standart, lekin premium kabi ajratib
  /// ko'rsatiladigan qatorlar uchun boshqacha bo'lishi mumkin.
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    // Ilgari bu qator "yorliq CHAPDA — qiymat O'NGDA" ko'rinishida
    // edi. Ikki uchi bir-biridan uzoqda turgani uchun ko'z har safar
    // bo'sh joyni kesib o'tishga majbur bo'lardi va uzun manzil
    // qisqarib ketardi.
    //
    // Endi Telegram/iOS uslubi: qiymat TEPADA (asosiy, to'q), yorlig'i
    // ostida (mayda, kulrang) — ikkalasi ham chapga tekislangan,
    // ikonkadan boshlab bitta ustunda.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon,
                size: 18, color: valueColor ?? context.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: context.bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style:
                      context.captionStyle.copyWith(color: context.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Faollik statistikasi — yuborilgan murojaatlar, qo'shilingan
/// ommaviy murojaatlar va (agar xodim/rais bo'lsa) joylangan e'lonlar.
class _ActivityStatsRow extends ConsumerWidget {
  const _ActivityStatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myRequestsAsync = ref.watch(myOwnRequestsProvider);
    final myAnnouncementsAsync = ref.watch(myOwnAnnouncementsProvider);
    final joinedCount = ref.watch(myJoinedRequestsCountProvider);

    return Row(
      children: [
        Expanded(
          child: StaggeredEntrance(
            index: 0,
            child: _StatTile(
              icon: PhosphorIconsFill.chatCircleDots,
              color: AppAccents.requests,
              value: myRequestsAsync.valueOrNull?.length ?? 0,
              label: l10n.myRequestsStat,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StaggeredEntrance(
            index: 1,
            child: _StatTile(
              icon: PhosphorIconsFill.megaphone,
              color: AppAccents.announcements,
              value: myAnnouncementsAsync.valueOrNull?.length ?? 0,
              label: l10n.myAnnouncementsStat,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: StaggeredEntrance(
            index: 2,
            child: _StatTile(
              icon: PhosphorIconsFill.usersThree,
              color: AppAccents.events,
              value: joinedCount,
              label: l10n.myJoinedStat,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: context.titleStyle.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.captionStyle,
          ),
        ],
      ),
    );
  }
}

/// "Mening murojaatlarim" — foydalanuvchi shaxsan yuborgan
/// murojaatlar ro'yxati (qisqa, 3 tagacha ko'rsatiladi).
class _MyActivitySection extends ConsumerWidget {
  final UserProfile profile;
  const _MyActivitySection({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myRequestsAsync = ref.watch(myOwnRequestsProvider);
    final mahallaId = profile.mahallaId;

    return myRequestsAsync.when(
      data: (requests) {
        if (requests.isEmpty || mahallaId == null) {
          return const SizedBox.shrink();
        }
        final recent = requests.take(3).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.myRequestsTitle, style: context.sectionStyle),
            const SizedBox(height: AppSpacing.sm),
            ...recent.map((request) => AppCard(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                  onTap: () => AppPageRoute.push(
                      context,
                      RequestDetailScreen(
                        mahallaId: mahallaId,
                        requestId: request.id,
                      )),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.cardTitleStyle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(PhosphorIconsRegular.caretRight,
                          size: 18, color: context.textSecondary),
                    ],
                  ),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
