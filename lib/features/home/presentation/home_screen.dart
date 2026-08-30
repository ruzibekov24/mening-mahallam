import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/no_mahalla_view.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../announcements/data/announcements_providers.dart';
import '../../banners/data/promo_banner_repository.dart';
import '../../banners/presentation/promo_banner_carousel.dart';
import '../../chat/data/chat_providers.dart';
import '../../chat/presentation/conversations_screen.dart';
import '../../map/presentation/mahalla_map_screen.dart';
import '../../map/presentation/mahalla_map_view.dart';
import '../../notifications/data/notification_repository.dart';
import '../../qr/presentation/qr_scan_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../requests/data/requests_repository.dart';
import '../../requests/presentation/new_request_flow_screen.dart';
import '../../search/presentation/search_screen.dart';
import '../data/home_repository.dart';
import '../data/home_stats_provider.dart';
import 'neighbor_profile_screen.dart';
import 'role_styles.dart';

/// 9. ASOSIY (HOME) ekrani.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final mahallaNameAsync = ref.watch(currentMahallaNameProvider);
    final statsAsync = ref.watch(homeStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        // Bezakli lenta ekranning eng tepasigacha (status bar ostigacha)
        // cho'zilishi uchun tepa SafeArea o'chirilgan — uning o'rniga
        // GirihHeader o'zi tepa padding'ni hisobga oladi.
        top: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProfileProvider);
            ref.invalidate(upcomingEventsProvider);
            ref.invalidate(currentMahallaNameProvider);
            ref.invalidate(myRequestsProvider);
            ref.invalidate(myAnnouncementsProvider);
            ref.invalidate(myEventsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 120),
            children: [
              GirihHeader(
                image: 'assets/images/patterns/abstract_blue.png',
                watermarkIcon: PhosphorIconsFill.houseLine,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.welcomeGreeting,
                            style: context.secondaryStyle.copyWith(
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          profileAsync.when(
                            data: (profile) => Text(
                              l10n.helloUser(
                                profile?.firstName.isNotEmpty == true
                                    ? profile!.firstName
                                    : l10n.guestName,
                              ),
                              style: context.titleStyle
                                  .copyWith(color: Colors.white),
                            ),
                            loading: () => Text(
                              l10n.helloGeneric,
                              style: context.titleStyle
                                  .copyWith(color: Colors.white),
                            ),
                            error: (_, __) => Text(
                              l10n.helloGeneric,
                              style: context.titleStyle
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                          mahallaNameAsync.when(
                            data: (name) {
                              if (name == null || name.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(PhosphorIconsFill.mapPin,
                                        size: 13, color: Colors.white),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        name,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.captionStyle.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    TapScale(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ConversationsScreen(),
                        ),
                      ),
                      borderRadius: AppRadius.smAll,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            margin: const EdgeInsets.only(right: AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: const Icon(
                              PhosphorIconsFill.chatDots,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final unreadAsync =
                                  ref.watch(totalUnreadMessagesProvider);
                              final count = unreadAsync.valueOrNull ?? 0;
                              if (count == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: AppSpacing.sm - 2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: context.captionStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    TapScale(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      ),
                      borderRadius: AppRadius.smAll,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: AppRadius.smAll,
                            ),
                            child: const Icon(
                              PhosphorIconsFill.bell,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final unreadAsync =
                                  ref.watch(unreadNotificationCountProvider);
                              final count = unreadAsync.valueOrNull ?? 0;
                              if (count == 0) return const SizedBox.shrink();
                              return Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    count > 9 ? '9+' : '$count',
                                    style: context.captionStyle.copyWith(
                                      color: Colors.white,
                                      fontSize: 9,
                                      height: 1.0,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Lentadan pastdagi butun kontent — yon tomonlardan bir xil
              // padding bilan. Lenta esa ekran chetigacha cho'ziladi,
              // shuning uchun ListView'ning o'zida gorizontal padding yo'q.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xl),

                    // Qidiruv maydoni — hammasidan tepada, SearchScreen'ga
                    // o'tadi.
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.smAll,
                        boxShadow: AppShadows.elevated(context.isDarkMode),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: l10n.searchHint,
                          prefixIcon: Icon(PhosphorIconsBold.magnifyingGlass,
                              color: context.textSecondary),
                          filled: true,
                          fillColor: context.surfaceColor,
                          border: const OutlineInputBorder(
                            borderRadius: AppRadius.smAll,
                            borderSide: BorderSide.none,
                          ),
                        ),
                        readOnly: true,
                        onTap: () {
                          final mahallaId = profileAsync.value?.mahallaId;
                          if (mahallaId == null) {
                            // Ilgari bu yerda "tez orada" deb yozilardi —
                            // aslida qidiruv ishlaydi, shunchaki mahallaga
                            // qo'shilish kerak edi. Endi to'g'ri yo'l
                            // ko'rsatiladi.
                            // Xabar markazda, ikkita tugma bilan: bu
                            // yagona joy bo'lib, unda xabardan keyin
                            // darhol harakat qilish taklif etiladi.
                            showDialog<void>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                shape: const RoundedRectangleBorder(
                                    borderRadius: AppRadius.lgAll),
                                icon: Container(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(PhosphorIconsFill.qrCode,
                                      color: AppColors.primary, size: 26),
                                ),
                                content: Text(
                                  l10n.noMahallaTitle,
                                  textAlign: TextAlign.center,
                                  style: dialogContext.bodyStyle,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: Text(l10n.cancelButton),
                                  ),
                                  FilledButton(
                                    onPressed: () {
                                      Navigator.of(dialogContext).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                const QrScanScreen()),
                                      );
                                    },
                                    style: FilledButton.styleFrom(
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: AppRadius.smAll),
                                    ),
                                    child: Text(l10n.noMahallaAction),
                                  ),
                                ],
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  SearchScreen(mahallaId: mahallaId),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Hali mahallaga qo'shilmagan foydalanuvchi uchun
                    // yagona tushuntirish. Pastdagi bo'limlar (xodimlar,
                    // xarita, bannerlar) shu holatda jimgina yashiriladi
                    // — sabab shu yerda bir marta aytilgani uchun ularga
                    // alohida bo'sh kartochka qo'yish takrorlash bo'lardi.
                    profileAsync.maybeWhen(
                      data: (profile) => profile?.mahallaId == null
                          ? const Padding(
                              padding:
                                  EdgeInsets.only(bottom: AppSpacing.xl),
                              child: NoMahallaBanner(),
                            )
                          : const SizedBox.shrink(),
                      orElse: () => const SizedBox.shrink(),
                    ),

                    // Mahalla xodimlari — qidiruvdan keyin, aholi kim bilan
                    // bog'lanishi mumkinligini ko'rsatadi.
                    profileAsync.when(
                      data: (profile) {
                        final mahallaId = profile?.mahallaId;
                        if (mahallaId == null) return const SizedBox.shrink();
                        return Consumer(
                          builder: (context, ref, _) {
                            final staffAsync =
                                ref.watch(staffMembersProvider(mahallaId));
                            return staffAsync.when(
                              data: (staff) {
                                if (staff.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.mahallaStaffTitle,
                                      style: context.sectionStyle,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    SizedBox(
                                      height: 100,
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: staff.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(
                                                width: AppSpacing.md),
                                        itemBuilder: (context, index) =>
                                            StaggeredEntrance(
                                          index: index,
                                          child:
                                              _StaffCard(member: staff[index]),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.xxl),
                                  ],
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Avtomatik aylanuvchi bannerlar — e'lon, tashqi
                    // havola, konkurs yoki reklama bo'lishi mumkin
                    // (super admin boshqaradi). Banner bo'lmasa bu
                    // butunlay ko'rinmaydi, quyidagi bo'shliq ham
                    // qo'shilmaydi.
                    const PromoBannerCarousel(),
                    Consumer(
                      builder: (context, ref, _) {
                        final hasBanners =
                            ref.watch(activeBannersProvider).valueOrNull;
                        if (hasBanners == null || hasBanners.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return const SizedBox(height: AppSpacing.xl);
                      },
                    ),

                    // Mahalla xaritasi — murojaatlar joylashuvi (yangi/
                    // jarayonda/yakunlandi) rangli markerlar bilan.
                    Text(l10n.mahallaOnMapTitle, style: context.sectionStyle),
                    const SizedBox(height: AppSpacing.md),
                    profileAsync.when(
                      data: (profile) {
                        final mahallaId = profile?.mahallaId;
                        if (mahallaId == null) return const SizedBox.shrink();
                        return TapScale(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  MahallaMapScreen(mahallaId: mahallaId),
                            ),
                          ),
                          borderRadius: AppRadius.mdAll,
                          // flutter_map o'zining ichki tap-tanish (gesture)
                          // qatlamiga ega — `interactive: false` faqat
                          // pan/zoom/rotate'ni o'chiradi, lekin bosishni hali
                          // ham "yutib qo'yishi" mumkin va tashqi TapScale
                          // hech qachon ishga tushmasligiga olib keladi.
                          // AbsorbPointer xaritani hit-test'dan butunlay olib
                          // tashlaydi — bosish faqat TapScale'ga tegadi.
                          child: AbsorbPointer(
                            child: MahallaMapView(
                              mahallaId: mahallaId,
                              height: 170,
                              interactive: false,
                              showRequestMarkers: false,
                            ),
                          ),
                        );
                      },
                      loading: () => Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: AppRadius.mdAll,
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Xarita ostidagi tezkor amal — yangi murojaat
                    // yuborish (eng tez-tez kerak bo'ladigan amal, xarita
                    // bilan bir mavzuda: "hududda muammo ko'rdim").
                    profileAsync.when(
                      data: (profile) {
                        final mahallaId = profile?.mahallaId;
                        if (mahallaId == null) return const SizedBox.shrink();
                        return AppListCard(
                          icon: PhosphorIconsFill.plusCircle,
                          accent: AppAccents.requests,
                          title: l10n.quickNewRequestTitle,
                          subtitle: l10n.quickNewRequestSubtitle,
                          margin: EdgeInsets.zero,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  NewRequestFlowScreen(mahallaId: mahallaId),
                            ),
                          ),
                          trailing: Icon(PhosphorIconsRegular.caretRight,
                              size: 18, color: context.textSecondary),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(l10n.upcomingEventsTitle, style: context.sectionStyle),
                    const SizedBox(height: AppSpacing.md),

                    eventsAsync.when(
                      data: (events) {
                        if (events.isEmpty) {
                          return AppEmptyView(
                            icon: PhosphorIconsFill.calendarX,
                            title: l10n.noUpcomingEvents,
                            accent: AppAccents.events,
                          );
                        }
                        return Column(
                          children: [
                            for (var i = 0; i < events.length; i++)
                              StaggeredEntrance(
                                index: i,
                                child: _EventRow(event: events[i]),
                              ),
                          ],
                        );
                      },
                      loading: () => Column(
                        children:
                            List.generate(2, (_) => const ShimmerListTile()),
                      ),
                      error: (error, _) => AppErrorView.fromError(
                        error,
                        onRetry: () => ref.invalidate(upcomingEventsProvider),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    Text(l10n.mahallaStatsTitle, style: context.sectionStyle),
                    const SizedBox(height: AppSpacing.md),

                    statsAsync.when(
                      data: (stats) => _StatsGrid(stats: stats),
                      loading: () => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 1.35,
                        children:
                            List.generate(4, (_) => const ShimmerStatCard()),
                      ),
                      error: (error, _) => AppErrorView.fromError(
                        error,
                        onRetry: () => ref.invalidate(homeStatsProvider),
                      ),
                    ),
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

class _EventRow extends StatelessWidget {
  final UpcomingEvent event;
  const _EventRow({required this.event});

  static const _uzMonths = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  String _formatWhen(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final tomorrow = now.add(const Duration(days: 1));
    final isTomorrow = dt.year == tomorrow.year &&
        dt.month == tomorrow.month &&
        dt.day == tomorrow.day;

    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    if (isToday) return '${l10n.today} $time';
    if (isTomorrow) return '${l10n.tomorrow} $time';
    return '${dt.day}-${_uzMonths[dt.month - 1]} $time';
  }

  @override
  Widget build(BuildContext context) {
    return AppListCard(
      icon: PhosphorIconsFill.calendarCheck,
      accent: AppAccents.events,
      title: event.title,
      subtitle: _formatWhen(context, event.dateTime),
    );
  }
}

/// Mahalla xodimlari — statistika o'rniga, aholi kim bilan
/// bog'lanishi mumkinligini bevosita ko'rsatadi.
class _StaffCard extends StatelessWidget {
  final MahallaMember member;
  const _StaffCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final fullName = '${member.firstName} ${member.lastName}'.trim();

    return AppCard(
      radius: AppRadius.md,
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: 6),
      color: context.surfaceColor,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NeighborProfileScreen(member: member),
        ),
      ),
      child: SizedBox(
        width: 78,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'member-avatar-${member.uid}',
              child: UserAvatar(
                size: 40,
                firstName: member.firstName,
                lastName: member.lastName,
                photoUrl: member.photoUrl,
                seed: member.uid,
                ringColor: avatarRingColor(member.role,
                isPremium: member.isPremiumActive),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              fullName.isEmpty ? '—' : fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.captionStyle.copyWith(color: context.textPrimary),
            ),
            Text(
              member.staffTitle?.isNotEmpty == true
                  ? member.staffTitle!
                  : member.role.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.captionStyle.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mahalla statistikasi — 2x2 grid ko'rinishida, minimal kartalar.
class _StatsGrid extends StatelessWidget {
  final HomeStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        icon: PhosphorIconsFill.usersThree,
        color: AppAccents.announcements,
        value: stats.totalMembers,
        label: l10n.statsTotalMembers,
      ),
      (
        icon: PhosphorIconsFill.chatCircleDots,
        color: AppAccents.requests,
        value: stats.activeRequests,
        label: l10n.statsActiveRequests,
      ),
      (
        icon: PhosphorIconsFill.megaphone,
        color: AppAccents.events,
        value: stats.newAnnouncements,
        label: l10n.statsNewAnnouncements,
      ),
      (
        icon: PhosphorIconsFill.calendarCheck,
        color: AppAccents.neighbors,
        value: stats.upcomingEvents,
        label: l10n.statsUpcomingEvents,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [
        for (var i = 0; i < items.length; i++)
          StaggeredEntrance(
            index: i,
            child: _StatCard(
              icon: items[i].icon,
              color: items[i].color,
              value: items[i].value,
              label: items[i].label,
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: context.isDarkMode ? 0.18 : 0.1),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$value', style: context.titleStyle),
          Text(
            label,
            style: context.captionStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
