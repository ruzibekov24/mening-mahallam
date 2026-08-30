import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../services/presentation/services_screen.dart';
import 'neighbor_profile_screen.dart';
import 'role_styles.dart';

/// Qo'shnilar ekrani: ikkita bo'lim ko'rsatadi —
/// "Qo'shnilar" (joriy foydalanuvchi bilan bir xil ko'chada
/// yashovchilar) va "Mahalladoshlar" (butun mahalladagi qolgan
/// barcha a'zolar). Har birining online/offline holati va, agar
/// o'sha kishi ruxsat bergan bo'lsa, telefon raqami ko'rinadi.
class NeighborsScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const NeighborsScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<NeighborsScreen> createState() => _NeighborsScreenState();
}

class _NeighborsScreenState extends ConsumerState<NeighborsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final membersAsync = ref.watch(neighborsProvider(widget.mahallaId));
    final myProfileAsync = ref.watch(currentUserProfileProvider);
    final myStreet = myProfileAsync.valueOrNull?.street?.trim();

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
                    child: Text(l10n.neighborsTitle,
                        style: context.titleStyle
                            .copyWith(color: Colors.white)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const ServicesScreen()),
                    ),
                    icon: const Icon(PhosphorIconsFill.toolbox,
                        color: Colors.white),
                    tooltip: l10n.servicesTitle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
        ),
      ),
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
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => NeighborProfileScreen(member: member),
        ),
      ),
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
              ringColor: avatarRingColor(member.role,
                isPremium: member.isPremiumActive),
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