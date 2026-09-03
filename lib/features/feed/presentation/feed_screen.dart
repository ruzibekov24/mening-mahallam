import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
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

enum _FeedFilter { announcements, events, posts }

final _feedFilterProvider =
    StateProvider.autoDispose<_FeedFilter>((ref) => _FeedFilter.announcements);

/// Lenta — postlar, e'lonlar va tadbirlarni bitta ekranda, lekin
/// ALOHIDA-ALOHIDA (aralashtirilmasdan) ko'rsatadi: yuqoridagi 3 ta
/// chip har doim aynan bitta turkumni tanlaydi, "hammasi" degan
/// aralash ko'rinish yo'q — rasmiy e'lon/tadbirlar oddiy foydalanuvchi
/// postlari orasida yo'qolib qolmasligi uchun. `announcements`/`events`
/// kolleksiyalari o'zgarishsiz qoladi — bu faqat ular orasida almashish
/// uchun UI ko'rinishi.
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
                      child: _FeedSegmentButton(
                        label: l10n.announcementsTitle,
                        isActive: filter == _FeedFilter.announcements,
                        onTap: () =>
                            ref.read(_feedFilterProvider.notifier).state =
                                _FeedFilter.announcements,
                      ),
                    ),
                    Expanded(
                      child: _FeedSegmentButton(
                        label: l10n.eventsTitle,
                        isActive: filter == _FeedFilter.events,
                        onTap: () =>
                            ref.read(_feedFilterProvider.notifier).state =
                                _FeedFilter.events,
                      ),
                    ),
                    Expanded(
                      child: _FeedSegmentButton(
                        label: l10n.postsFilterLabel,
                        isActive: filter == _FeedFilter.posts,
                        onTap: () =>
                            ref.read(_feedFilterProvider.notifier).state =
                                _FeedFilter.posts,
                      ),
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
                  final showLoadMoreRow =
                      hasMorePosts && filter == _FeedFilter.posts;
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

/// `NeighborsScreen._SegmentButton` bilan vizual jihatdan bir xil
/// (uch bo'lakli qatorda) — kichik widget bo'lgani uchun umumiy fayl
/// chiqarish o'rniga shu yerda alohida nusxasi saqlangan.
class _FeedSegmentButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FeedSegmentButton({
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

bool _isPost(FeedItem item) =>
    item.map(post: (_) => true, announcement: (_) => false, event: (_) => false);
bool _isAnnouncement(FeedItem item) =>
    item.map(post: (_) => false, announcement: (_) => true, event: (_) => false);
bool _isEvent(FeedItem item) =>
    item.map(post: (_) => false, announcement: (_) => false, event: (_) => true);
