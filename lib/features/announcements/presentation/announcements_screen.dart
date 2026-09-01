import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/announcement_repository.dart';
import '../data/announcements_providers.dart';
import '../data/event_repository.dart';
import '../../polls/presentation/polls_screen.dart';
import 'announcement_detail_screen.dart';
import 'announcement_styles.dart';
import 'announcement_widgets.dart';
import 'event_detail_screen.dart';
import 'new_announcement_screen.dart';
import 'new_event_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// Tashqaridan (masalan Home'dagi "Tadbirlar" kartochkasidan) qaysi
/// ichki tab ochilishini boshqarish uchun.
final announcementsShowEventsProvider = StateProvider<bool>((ref) => false);

/// E'lonlar ro'yxatidagi kategoriya filtri — `null` = hammasi.
final _announcementsFilterProvider =
    StateProvider.autoDispose<AnnouncementCategory?>((ref) => null);

/// 10-11. E'LONLAR va TADBIRLAR ekrani — ichki tab orqali almashadi.
class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  void _openNewAnnouncement(BuildContext context, String mahallaId) {
    AppPageRoute.push(context, NewAnnouncementScreen(mahallaId: mahallaId));
  }

  void _openNewEvent(BuildContext context, String mahallaId) {
    AppPageRoute.push(context, NewEventScreen(mahallaId: mahallaId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showEvents = ref.watch(announcementsShowEventsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppAccents.events,
              image: 'assets/images/patterns/abstract_orange.png',
              watermarkIcon: PhosphorIconsFill.megaphone,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      showEvents ? l10n.eventsTitle : l10n.announcementsTitle,
                      style: context.titleStyle.copyWith(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: LiquidGlassCircleButton(
                      icon: PhosphorIconsFill.chartBar,
                      iconColor: Colors.white,
                      diameter: 40,
                      iconSize: 20,
                      onTap: () =>
                          AppPageRoute.push(context, const PollsScreen()),
                    ),
                  ),
                  profileAsync.when(
                    data: (profile) {
                      final canPost = profile?.role.canPost == true &&
                          profile?.mahallaId != null;
                      if (!canPost) return const SizedBox.shrink();
                      return LiquidPillButton(
                        label: l10n.newButton,
                        icon: PhosphorIconsBold.plus,
                        onTap: () => showEvents
                            ? _openNewEvent(context, profile!.mahallaId!)
                            : _openNewAnnouncement(
                                context, profile!.mahallaId!),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBorder,
                  borderRadius: AppRadius.smAll,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentButton(
                        label: l10n.announcementsTitle,
                        isActive: !showEvents,
                        onTap: () => ref
                            .read(announcementsShowEventsProvider.notifier)
                            .state = false,
                      ),
                    ),
                    Expanded(
                      child: _SegmentButton(
                        label: l10n.eventsTitle,
                        isActive: showEvents,
                        onTap: () => ref
                            .read(announcementsShowEventsProvider.notifier)
                            .state = true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child:
                  showEvents ? const _EventsList() : const _AnnouncementsList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      haptic: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.xsAll,
          boxShadow: isActive
              ? AppShadows.accent(AppColors.primary, context.isDarkMode)
              : null,
        ),
        child: Text(
          label,
          style: context.secondaryStyle.copyWith(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : context.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _AnnouncementsList extends ConsumerWidget {
  const _AnnouncementsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final announcementsAsync = ref.watch(myAnnouncementsProvider);
    final selectedCategory = ref.watch(_announcementsFilterProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myAnnouncementsProvider),
      child: announcementsAsync.when(
        data: (allAnnouncements) {
          if (allAnnouncements.isEmpty) {
            return AppEmptyView(
              icon: PhosphorIconsFill.megaphone,
              title: l10n.noAnnouncementsYet,
              subtitle: l10n.noAnnouncementsHint,
              accent: AppAccents.announcements,
              scrollable: true,
            );
          }
          final announcements = selectedCategory == null
              ? allAnnouncements
              : allAnnouncements
                  .where((a) => a.category == selectedCategory)
                  .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      AppFilterChip(
                        label: l10n.allFilter,
                        isActive: selectedCategory == null,
                        onTap: () => ref
                            .read(_announcementsFilterProvider.notifier)
                            .state = null,
                      ),
                      for (final cat in AnnouncementCategory.values) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppFilterChip(
                          label: categoryLabel(l10n, cat),
                          isActive: selectedCategory == cat,
                          onTap: () => ref
                              .read(_announcementsFilterProvider.notifier)
                              .state = cat,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: announcements.isEmpty
                    ? AppEmptyView(
                        icon: PhosphorIconsFill.megaphone,
                        title: l10n.searchNoResults,
                        accent: AppAccents.announcements,
                        scrollable: true,
                      )
                    : ListView.builder(
                        padding: AppSpacing.listPadding,
                        itemCount: announcements.length,
                        itemBuilder: (context, index) => StaggeredEntrance(
                          index: index,
                          child: _AnnouncementCard(
                              announcement: announcements[index]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => ListView(
          padding: AppSpacing.listPadding,
          physics: const NeverScrollableScrollPhysics(),
          children: const [ShimmerList(count: 5)],
        ),
        error: (error, _) => AppErrorView.fromError(
          error,
          onRetry: () => ref.invalidate(myAnnouncementsProvider),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  String _timeAgo(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = announcement.category.color;
    final mahallaId = ref.watch(currentUserProfileProvider).valueOrNull?.mahallaId;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      onTap: mahallaId == null
          ? null
          : () => AppPageRoute.push(
                context,
                AnnouncementDetailScreen(
                  mahallaId: mahallaId,
                  announcementId: announcement.id,
                ),
              ),
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (announcement.imageUrl != null &&
              announcement.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
              child: Hero(
                tag: 'announcement-image-${announcement.id}',
                child: CachedNetworkImage(
                  imageUrl: announcement.imageUrl!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: color.withValues(alpha: 0.08),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 140,
                    color: color.withValues(alpha: 0.08),
                    child: Icon(PhosphorIconsRegular.imageBroken,
                        color: color.withValues(alpha: 0.4)),
                  ),
                ),
              ),
            )
          else
            // Rasm bo'lmaganda ham kartochka bo'sh ko'rinmasin deb,
            // kategoriya rangida ingichka bezak-chiziq qo'yamiz.
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
              child: Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.3)],
                  ),
                ),
              ),
            ),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: AppRadius.xsAll,
                      ),
                      child: Text(
                        categoryLabel(l10n, announcement.category),
                        style: context.captionStyle.copyWith(color: color),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _timeAgo(context, announcement.createdAt),
                          style: context.captionStyle,
                        ),
                        // O'chirish to'g'ridan-to'g'ri bosiladigan
                        // ikonka emas, "..." menyu ichida — ro'yxatni
                        // aylantirish paytida tasodifan bosilib
                        // ketmasligi uchun (avval to'g'ridan-to'g'ri
                        // chiqindi ikonkasi bo'lgan, juda xavfli edi).
                        Consumer(
                          builder: (context, ref, _) {
                            final profile = ref
                                .watch(currentUserProfileProvider)
                                .valueOrNull;
                            final canDelete = profile?.role.canPost == true &&
                                profile?.mahallaId != null;
                            if (!canDelete) return const SizedBox.shrink();
                            return PopupMenuButton<void>(
                              icon: Icon(PhosphorIconsBold.dotsThreeVertical,
                                  size: 16, color: context.textMuted),
                              padding: EdgeInsets.zero,
                              iconSize: 16,
                              tooltip: '',
                              shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.smAll),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  onTap: () async {
                                    await Future.delayed(
                                        const Duration(milliseconds: 1));
                                    if (!context.mounted) return;
                                    AppPageRoute.push(
                                        context,
                                        NewAnnouncementScreen(
                                          mahallaId: profile!.mahallaId!,
                                          existing: announcement,
                                        ));
                                  },
                                  child: Row(
                                    children: [
                                      Icon(PhosphorIconsRegular.pencilSimple,
                                          size: 18,
                                          color: context.textSecondary),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(l10n.editButton,
                                          style: context.bodyStyle),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  onTap: () async {
                                    // PopupMenuItem o'zining onTap'ini
                                    // menyu yopilishidan OLDIN chaqiradi —
                                    // shuning uchun dialog ochish uchun
                                    // bir freym kutamiz.
                                    await Future.delayed(
                                        const Duration(milliseconds: 1));
                                    if (!context.mounted) return;
                                    final confirmed = await confirmDelete(
                                      context,
                                      itemTitle: announcement.title,
                                    );
                                    if (!confirmed || !context.mounted) return;
                                    await ref
                                        .read(announcementRepositoryProvider)
                                        .deleteAnnouncement(
                                          mahallaId: profile!.mahallaId!,
                                          announcementId: announcement.id,
                                        );
                                    if (context.mounted) {
                                      showAppAlert(
                                          context, l10n.itemDeletedMessage);
                                    }
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(PhosphorIconsRegular.trash,
                                          size: 18, color: AppColors.danger),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(l10n.deleteButton,
                                          style: context.bodyStyle.copyWith(
                                              color: AppColors.danger)),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(announcement.title, style: context.cardTitleStyle),
                if (announcement.body.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    announcement.plainTextPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.secondaryStyle,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                ReactionRow(announcement: announcement),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventsList extends ConsumerWidget {
  const _EventsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final eventsAsync = ref.watch(myEventsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myEventsProvider),
      child: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return AppEmptyView(
              icon: PhosphorIconsFill.calendarX,
              title: l10n.noEventsYet,
              accent: AppAccents.events,
              scrollable: true,
            );
          }
          return ListView.builder(
            padding: AppSpacing.listPadding,
            itemCount: events.length,
            itemBuilder: (context, index) => StaggeredEntrance(
              index: index,
              child: _EventCard(event: events[index], colorIndex: index),
            ),
          );
        },
        loading: () => ListView(
          padding: AppSpacing.listPadding,
          physics: const NeverScrollableScrollPhysics(),
          children: const [ShimmerList(count: 5)],
        ),
        error: (error, _) => AppErrorView.fromError(
          error,
          onRetry: () => ref.invalidate(myEventsProvider),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  final MahallaEvent event;
  final int colorIndex;
  const _EventCard({required this.event, required this.colorIndex});

  String _formatDateTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return l10n.todayAt(time);
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')} • $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final gradient = AppAccents
        .bannerGradients[colorIndex % AppAccents.bannerGradients.length];
    final mahallaId = ref.watch(currentUserProfileProvider).valueOrNull?.mahallaId;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.zero,
      onTap: mahallaId == null
          ? null
          : () => AppPageRoute.push(
                context,
                EventDetailScreen(mahallaId: mahallaId, eventId: event.id),
              ),
      radius: AppRadius.lg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            child: Hero(
              tag: 'event-banner-${event.id}',
              child: Container(
              height: 72,
              width: double.infinity,
              padding: AppSpacing.card,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                ),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.cardTitleStyle.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // O'chirish "..." menyu ichida — banner burchagida
                  // to'g'ridan-to'g'ri chiqindi ikonkasi tasodifan
                  // bosilishi oson edi (xavfli joy).
                  Align(
                    alignment: Alignment.topRight,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final profile =
                            ref.watch(currentUserProfileProvider).valueOrNull;
                        final canDelete = profile?.role.canPost == true &&
                            profile?.mahallaId != null;
                        if (!canDelete) return const SizedBox.shrink();
                        return PopupMenuButton<void>(
                          icon: const Icon(PhosphorIconsBold.dotsThreeVertical,
                              size: 16, color: Colors.white),
                          padding: EdgeInsets.zero,
                          iconSize: 16,
                          tooltip: '',
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.smAll),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              onTap: () async {
                                await Future.delayed(
                                    const Duration(milliseconds: 1));
                                if (!context.mounted) return;
                                AppPageRoute.push(
                                    context,
                                    NewEventScreen(
                                      mahallaId: profile!.mahallaId!,
                                      existing: event,
                                    ));
                              },
                              child: Row(
                                children: [
                                  Icon(PhosphorIconsRegular.pencilSimple,
                                      size: 18, color: context.textSecondary),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(l10n.editButton,
                                      style: context.bodyStyle),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              onTap: () async {
                                await Future.delayed(
                                    const Duration(milliseconds: 1));
                                if (!context.mounted) return;
                                final confirmed = await confirmDelete(
                                  context,
                                  itemTitle: event.title,
                                );
                                if (!confirmed || !context.mounted) return;
                                await ref
                                    .read(eventRepositoryProvider)
                                    .deleteEvent(
                                      mahallaId: profile!.mahallaId!,
                                      eventId: event.id,
                                    );
                                if (context.mounted) {
                                  showAppAlert(
                                      context, l10n.itemDeletedMessage);
                                }
                              },
                              child: Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.trash,
                                      size: 18, color: AppColors.danger),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(l10n.deleteButton,
                                      style: context.bodyStyle
                                          .copyWith(color: AppColors.danger)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          ),
          Padding(
            padding: AppSpacing.card,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.calendar,
                        size: 13, color: context.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatDateTime(context, event.dateTime),
                      style: context.captionStyle,
                    ),
                    if (event.location.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(PhosphorIconsRegular.mapPin,
                          size: 13, color: context.textSecondary),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.captionStyle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (event.participantsCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(PhosphorIconsFill.usersThree,
                          size: 13, color: gradient.last),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.participantsCount(event.participantsCount),
                        style: context.captionStyle.copyWith(
                          color: gradient.last,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
