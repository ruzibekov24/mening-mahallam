import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/presentation/chat_screen.dart';
import '../../chat/presentation/conversations_screen.dart';
import '../../chat/presentation/new_group_screen.dart';
import '../../services/presentation/services_screen.dart';
import '../data/home_repository.dart';
import 'role_styles.dart';

/// "Qo'shni" bo'limi ichida qaysi segment ko'rsatilishini boshqaradi —
/// `announcementsShowEventsProvider` bilan bir xil naqsh
/// (`announcements_screen.dart`ga qarang).
final neighborsShowConversationsProvider = StateProvider<bool>((ref) => false);

/// Qo'shnilar ekrani: ikkita segment — "Qo'shnilar" (mahalla a'zolari
/// ro'yxati, ko'chaga qarab guruhlangan) va "Yozishmalar" (shaxsiy va
/// guruh suhbatlari, ilgari alohida `ConversationsScreen` sifatida
/// ochilardi). Qo'shni bosilganda endi to'g'ridan-to'g'ri u bilan
/// suhbat ochiladi (Telegram uslubi) — profilni ko'rish uchun esa
/// suhbat ichidagi ism/rasmga bosiladi (`ChatScreen`da allaqachon bor).
class NeighborsScreen extends ConsumerWidget {
  final String mahallaId;
  const NeighborsScreen({super.key, required this.mahallaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showConversations = ref.watch(neighborsShowConversationsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppAccents.neighbors,
              image: 'assets/images/patterns/abstract_purple.png',
              watermarkIcon: PhosphorIconsFill.usersThree,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      showConversations
                          ? l10n.yozishmalarTitle
                          : l10n.neighborsTitle,
                      style:
                          context.titleStyle.copyWith(color: Colors.white),
                    ),
                  ),
                  if (showConversations)
                    LiquidGlassCircleButton(
                      icon: PhosphorIconsFill.usersThree,
                      diameter: 40,
                      iconSize: 20,
                      iconColor: Colors.white,
                      onTap: () =>
                          AppPageRoute.push(context, const NewGroupScreen()),
                    )
                  else
                    LiquidGlassCircleButton(
                      icon: PhosphorIconsFill.toolbox,
                      diameter: 40,
                      iconSize: 20,
                      iconColor: Colors.white,
                      onTap: () => AppPageRoute.push(
                          context, const ServicesScreen()),
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
                        label: l10n.neighborsTitle,
                        isActive: !showConversations,
                        onTap: () => ref
                            .read(neighborsShowConversationsProvider.notifier)
                            .state = false,
                      ),
                    ),
                    Expanded(
                      child: _SegmentButton(
                        label: l10n.yozishmalarTitle,
                        isActive: showConversations,
                        onTap: () => ref
                            .read(neighborsShowConversationsProvider.notifier)
                            .state = true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: showConversations
                  ? const ConversationsListBody()
                  : _NeighborsList(mahallaId: mahallaId),
            ),
          ],
        ),
      ),
    );
  }
}

/// `AnnouncementsScreen._SegmentButton` bilan vizual jihatdan bir xil —
/// ikkalasi ham juda kichik widget bo'lgani uchun umumiy fayl
/// chiqarish o'rniga shu yerda alohida nusxasi saqlangan
/// (`feedback_screen.dart`dagi `_FeedbackModeButton` bilan bir xil
/// qaror).
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

/// "Qo'shnilar" segmentining tanasi — qidiruv maydoni + a'zolar
/// ro'yxati. Avval `NeighborsScreen`ning butun tanasi shu edi.
class _NeighborsList extends ConsumerStatefulWidget {
  final String mahallaId;
  const _NeighborsList({required this.mahallaId});

  @override
  ConsumerState<_NeighborsList> createState() => _NeighborsListState();
}

class _NeighborsListState extends ConsumerState<_NeighborsList> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(neighborsProvider(widget.mahallaId));
    final myProfileAsync = ref.watch(currentUserProfileProvider);
    final myStreet = myProfileAsync.valueOrNull?.street?.trim();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightBorder,
              borderRadius: AppRadius.smAll,
            ),
            child: Row(
              children: [
                Icon(PhosphorIconsBold.magnifyingGlass,
                    size: 18, color: context.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: l10n.searchNeighborHint,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: context.bodyStyle,
                  ),
                ),
                if (_query.isNotEmpty)
                  TapScale(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                    child: Icon(PhosphorIconsFill.xCircle,
                        size: 18, color: context.textSecondary),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: membersAsync.when(
            data: (allMembers) {
              final members = _query.isEmpty
                  ? allMembers
                  : allMembers
                      .where((m) => '${m.firstName} ${m.lastName}'
                          .toLowerCase()
                          .contains(_query))
                      .toList();

              if (allMembers.isEmpty) {
                return AppEmptyView(
                  icon: PhosphorIconsFill.usersThree,
                  title: l10n.noNeighborsYet,
                  subtitle: l10n.noNeighborsHint,
                  accent: AppAccents.neighbors,
                );
              }
              if (members.isEmpty) {
                return AppEmptyView(
                  icon: PhosphorIconsFill.magnifyingGlass,
                  title: l10n.searchNoResults,
                  accent: AppAccents.neighbors,
                  scrollable: true,
                );
              }

              // Bir xil ko'chada yashovchilar — "Qo'shnilar";
              // qolgan mahalla a'zolari — "Mahalladoshlar".
              // Agar foydalanuvchi profilida ko'cha kiritilmagan
              // bo'lsa, hammasi "Mahalladoshlar" ostida chiqadi.
              final hasMyStreet = myStreet != null && myStreet.isNotEmpty;
              final neighbors = hasMyStreet
                  ? members
                      .where((m) => m.street?.trim() == myStreet)
                      .toList()
                  : <MahallaMember>[];
              final others = hasMyStreet
                  ? members
                      .where((m) => m.street?.trim() != myStreet)
                      .toList()
                  : members;

              void sortByOnlineThenName(List<MahallaMember> list) {
                list.sort((a, b) {
                  if (a.isOnline != b.isOnline) {
                    return a.isOnline ? -1 : 1;
                  }
                  return a.firstName.compareTo(b.firstName);
                });
              }

              sortByOnlineThenName(neighbors);
              sortByOnlineThenName(others);

              final sections = <Widget>[];
              if (neighbors.isNotEmpty) {
                sections.add(AppSectionHeader(
                  title: l10n.neighborsTitle,
                  first: true,
                ));
                sections.addAll(neighbors.asMap().entries.map(
                      (e) => StaggeredEntrance(
                        index: e.key,
                        child: _NeighborTile(member: e.value),
                      ),
                    ));
              }
              if (others.isNotEmpty) {
                sections.add(AppSectionHeader(
                  title: l10n.mahalladoshlar,
                  first: neighbors.isEmpty,
                ));
                sections.addAll(others.asMap().entries.map(
                      (e) => StaggeredEntrance(
                        index: e.key,
                        child: _NeighborTile(member: e.value),
                      ),
                    ));
              }

              return ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                    AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                children: sections,
              );
            },
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                  AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
              physics: const NeverScrollableScrollPhysics(),
              children: const [ShimmerList(count: 6)],
            ),
            error: (error, _) => AppErrorView.fromError(
              error,
              onRetry: () =>
                  ref.invalidate(neighborsProvider(widget.mahallaId)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeighborTile extends StatelessWidget {
  final MahallaMember member;
  const _NeighborTile({required this.member});

  String _lastSeenLabel(AppLocalizations l10n) {
    final lastSeen = member.lastSeenAt;
    if (lastSeen == null) return l10n.lastSeenUnknown;

    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return l10n.lastSeenJustNow;
    if (diff.inMinutes < 60) return l10n.lastSeenMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.lastSeenHoursAgo(diff.inHours);
    return l10n.lastSeenDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      // Telegram uslubi: qo'shnini bosish endi to'g'ridan-to'g'ri u
      // bilan suhbatni ochadi — profilni ko'rish uchun suhbat ichidagi
      // ism/rasmga bosiladi (`ChatScreen`da allaqachon bor).
      onTap: () =>
          AppPageRoute.push(context, ChatScreen(otherUid: member.uid)),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          // Hero — bu avatar qo'shni profiliga o'tganda kattalashib
          // "uchib" boradi, sahifa to'satdan almashmaydi.
          Hero(
            tag: 'member-avatar-${member.uid}',
            child: UserAvatar(
              size: 44,
              firstName: member.firstName,
              lastName: member.lastName,
              photoUrl: member.photoUrl,
              seed: member.uid,
              ringColor: avatarRingColor(member.role),
              isOnline: member.isOnline,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${member.firstName} ${member.lastName}'.trim(),
                        overflow: TextOverflow.ellipsis,
                        style: context.cardTitleStyle,
                      ),
                    ),
                    if (member.role.isHighlighted) ...[
                      const SizedBox(width: AppSpacing.sm),
                      RoleBadge(role: member.role),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  member.isOnline ? l10n.onlineNow : _lastSeenLabel(l10n),
                  style: context.secondaryStyle.copyWith(
                    color: member.isOnline
                        ? AppColors.success
                        : context.textSecondary,
                    fontWeight:
                        member.isOnline ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Telefon raqami — faqat egasi ruxsat bergan bo'lsa ko'rinadi.
          if (member.phoneVisible && member.phone.isNotEmpty)
            TapScale(
              onTap: () => _launchCall(member.phone),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(PhosphorIconsFill.phone,
                    size: 18, color: AppColors.primary),
              ),
            )
          else
            Icon(PhosphorIconsFill.lock, size: 16, color: context.textMuted),
        ],
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
