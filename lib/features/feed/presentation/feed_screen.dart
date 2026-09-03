import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../announcements/data/announcements_providers.dart';
import '../../announcements/presentation/announcements_screen.dart';
import '../../announcements/presentation/new_announcement_screen.dart';
import '../../announcements/presentation/new_event_screen.dart';
import '../../home/data/home_repository.dart';
import '../../polls/presentation/polls_screen.dart';
import '../data/feed_item.dart';
import '../data/feed_providers.dart';
import 'new_post_screen.dart';
import 'post_widgets.dart';
import 'stories_bar.dart';

enum _FeedFilter { all, posts, announcements, events }

final _feedFilterProvider =
    StateProvider.autoDispose<_FeedFilter>((ref) => _FeedFilter.all);

/// Lenta — postlar, e'lonlar va tadbirlarni bitta xronologik
/// ro'yxatda ko'rsatadi (avvalgi "E'lonlar" tabining o'rnida).
/// `announcements`/`events` kolleksiyalari o'zgarishsiz qoladi —
/// bu faqat ularni birlashtiruvchi UI ko'rinishi.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Ro'yxat oxiriga yaqinlashganda (va ko'proq post mavjud bo'lishi
  /// mumkin bo'lsa) `postsLimitProvider`ni oshiradi — Firestore stream
  /// avtomatik qo'shimcha hujjatlarni yuklaydi.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400;
    if (!nearBottom) return;
    if (!ref.read(hasMorePostsProvider)) return;
    ref.read(postsLimitProvider.notifier).state += 20;
  }

  void _openNewPost(BuildContext context, String mahallaId) {
    AppPageRoute.push(context, NewPostScreen(mahallaId: mahallaId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final filter = ref.watch(_feedFilterProvider);
    final items = ref.watch(myFeedItemsProvider);
    final isLoading = ref.watch(myFeedLoadingProvider);
    final hasMorePosts = ref.watch(hasMorePostsProvider);

    final filtered = switch (filter) {
      _FeedFilter.all => items,
      _FeedFilter.posts => items.where(_isPost).toList(),
      _FeedFilter.announcements => items.where(_isAnnouncement).toList(),
      _FeedFilter.events => items.where(_isEvent).toList(),
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppAccents.announcements,
              watermarkIcon: PhosphorIconsFill.rows,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(l10n.feedTitle,
                        style: context.titleStyle.copyWith(color: Colors.white)),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: LiquidGlassCircleButton(
                      icon: PhosphorIconsFill.chartBar,
                      iconColor: Colors.white,
                      diameter: 40,
                      iconSize: 20,
                      onTap: () => AppPageRoute.push(context, const PollsScreen()),
                    ),
                  ),
                  profileAsync.when(
                    data: (profile) {
                      final mahallaId = profile?.mahallaId;
                      if (mahallaId == null) return const SizedBox.shrink();
                      final canPostOfficial = profile?.role.canPost == true;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (canPostOfficial) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.xs),
                              child: LiquidGlassCircleButton(
                                icon: PhosphorIconsFill.megaphone,
                                iconColor: Colors.white,
                                diameter: 40,
                                iconSize: 18,
                                onTap: () => AppPageRoute.push(context,
                                    NewAnnouncementScreen(mahallaId: mahallaId)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(right: AppSpacing.sm),
                              child: LiquidGlassCircleButton(
                                icon: PhosphorIconsFill.calendarPlus,
                                iconColor: Colors.white,
                                diameter: 40,
                                iconSize: 18,
                                onTap: () => AppPageRoute.push(context,
                                    NewEventScreen(mahallaId: mahallaId)),
                              ),
                            ),
                          ],
                          LiquidPillButton(
                            label: l10n.newButton,
                            icon: PhosphorIconsBold.plus,
                            onTap: () => _openNewPost(context, mahallaId),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (profileAsync.valueOrNull?.mahallaId != null) ...[
              StoriesBar(mahallaId: profileAsync.valueOrNull!.mahallaId!),
              const SizedBox(height: AppSpacing.sm),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(
                      label: l10n.allFilter,
                      isActive: filter == _FeedFilter.all,
                      onTap: () => ref.read(_feedFilterProvider.notifier).state =
                          _FeedFilter.all,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: l10n.postsFilterLabel,
                      isActive: filter == _FeedFilter.posts,
                      onTap: () => ref.read(_feedFilterProvider.notifier).state =
                          _FeedFilter.posts,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: l10n.announcementsTitle,
                      isActive: filter == _FeedFilter.announcements,
                      onTap: () => ref.read(_feedFilterProvider.notifier).state =
                          _FeedFilter.announcements,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppFilterChip(
                      label: l10n.eventsTitle,
                      isActive: filter == _FeedFilter.events,
                      onTap: () => ref.read(_feedFilterProvider.notifier).state =
                          _FeedFilter.events,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: profileAsync.when(
                data: (profile) {
                  final mahallaId = profile?.mahallaId;
                  if (mahallaId == null) return const SizedBox.shrink();

                  if (isLoading && filtered.isEmpty) {
                    return ListView(
                      padding: AppSpacing.listPadding,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [ShimmerList(count: 5)],
                    );
                  }
                  if (filtered.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.rows,
                      title: l10n.noPostsYet,
                      subtitle: l10n.noPostsHint,
                      accent: AppAccents.announcements,
                      scrollable: true,
                    );
                  }
                  final showLoadMoreRow = hasMorePosts &&
                      (filter == _FeedFilter.all || filter == _FeedFilter.posts);
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.read(postsLimitProvider.notifier).state = 20;
                      ref.invalidate(myPostsProvider);
                      ref.invalidate(myAnnouncementsProvider);
                      ref.invalidate(myEventsProvider);
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.listPadding,
                      itemCount: filtered.length + (showLoadMoreRow ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filtered.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.lg),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5),
                              ),
                            ),
                          );
                        }
                        final item = filtered[index];
                        return StaggeredEntrance(
                          index: index,
                          child: item.map(
                            post: (post) =>
                                PostCard(post: post, mahallaId: mahallaId),
                            announcement: (announcement) =>
                                AnnouncementCard(announcement: announcement),
                            event: (event) =>
                                EventCard(event: event, colorIndex: index),
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AppErrorView.fromError(error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isPost(FeedItem item) =>
    item.map(post: (_) => true, announcement: (_) => false, event: (_) => false);
bool _isAnnouncement(FeedItem item) =>
    item.map(post: (_) => false, announcement: (_) => true, event: (_) => false);
bool _isEvent(FeedItem item) =>
    item.map(post: (_) => false, announcement: (_) => false, event: (_) => true);
