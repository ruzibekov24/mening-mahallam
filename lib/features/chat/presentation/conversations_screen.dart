import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import '../data/group_chat_repository.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'new_group_screen.dart';

/// Barcha suhbatlar ro'yxati — Profil menyusidagi "Xabarlar" orqali
/// ochiladi.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      // Bu ekran Navigator.push bilan ochiladi — orqasida
      // MainShell foni YO'Q. Shaffof qoldirilsa ekran qop-qora
      // bo'lib ko'rinardi. Rang berilmasa mavzudagi
      // `scaffoldBackgroundColor` ishlaydi (dark mode ham).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AppPageRoute.push(context, const NewGroupScreen()),
        icon: const Icon(PhosphorIconsFill.usersThree),
        label: Text(l10n.createGroupAction),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppColors.primary,
              image: 'assets/images/patterns/abstract_blue.png',
              watermarkIcon: PhosphorIconsFill.chatDots,
              child: Row(
                children: [
                  LiquidGlassBackButton(iconColor: Colors.white),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.conversationsTitle,
                      style: context.titleStyle.copyWith(color: Colors.white)),
                ],
              ),
            ),
            const Expanded(child: ConversationsListBody()),
          ],
        ),
      ),
    );
  }
}

/// Suhbatlar ro'yxatining "tanasi" — sarlavha/FAB kabi ekran
/// chizig'isiz, faqat guruh+shaxsiy suhbatlar ro'yxati. `NeighborsScreen`
/// ichidagi "Yozishmalar" segmentida ham xuddi shu widget ishlatiladi —
/// alohida ekran sifatida ochilganda (`ConversationsScreen`) va segment
/// sifatida ko'milganda bir xil natija berish uchun.
class ConversationsListBody extends ConsumerWidget {
  const ConversationsListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(myConversationsProvider);
    final groupsAsync = ref.watch(myGroupChatsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return conversationsAsync.when(
      data: (conversations) {
        final groups = groupsAsync.valueOrNull ?? const [];
        if (conversations.isEmpty && groups.isEmpty) {
          return AppEmptyView(
            icon: PhosphorIconsFill.chatDots,
            title: l10n.noConversationsYet,
            subtitle: l10n.noConversationsHint,
            scrollable: true,
          );
        }
        return ListView(
          padding: AppSpacing.listPadding,
          children: [
            if (groups.isNotEmpty) ...[
              AppSectionHeader(title: l10n.groupsSectionTitle, first: true),
              const SizedBox(height: AppSpacing.sm),
              ...groups.asMap().entries.map((entry) {
                return StaggeredEntrance(
                  index: entry.key,
                  child: _GroupChatTile(
                    group: entry.value,
                    myUid: myUid ?? '',
                  ),
                );
              }),
              const SizedBox(height: AppSpacing.lg),
              AppSectionHeader(title: l10n.conversationsTitle),
              const SizedBox(height: AppSpacing.sm),
            ],
            ...conversations.asMap().entries.map((entry) {
              final conversation = entry.value;
              final otherUid = conversation.otherUid(myUid ?? '');
              final unread = conversation.unreadCounts[myUid] ?? 0;
              return StaggeredEntrance(
                index: entry.key,
                child: _ConversationTile(
                  conversation: conversation,
                  otherUid: otherUid,
                  unreadCount: unread,
                ),
              );
            }),
          ],
        );
      },
      loading: () => ListView(
        padding: AppSpacing.listPadding,
        physics: const NeverScrollableScrollPhysics(),
        children: const [ShimmerList(count: 6)],
      ),
      error: (error, _) => AppErrorView.fromError(
        error,
        onRetry: () => ref.invalidate(myConversationsProvider),
      ),
    );
  }
}

class _GroupChatTile extends StatelessWidget {
  final GroupChat group;
  final String myUid;

  const _GroupChatTile({required this.group, required this.myUid});

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () =>
          AppPageRoute.push(context, GroupChatScreen(groupId: group.id)),
      child: Row(
        children: [
          // Guruhlar shaxsiy avatar o'rniga umumiy belgi bilan
          // ko'rsatiladi — ro'yxatda 1:1 suhbatlardan vizual jihatdan
          // ajratish uchun.
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppAccents.neighbors,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(PhosphorIconsFill.usersThree,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: context.cardTitleStyle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  group.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.secondaryStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(_formatTime(group.lastMessageAt), style: context.captionStyle),
        ],
      ),
    );
  }
}

class _ConversationTile extends ConsumerWidget {
  final Conversation conversation;
  final String otherUid;
  final int unreadCount;

  const _ConversationTile({
    required this.conversation,
    required this.otherUid,
    required this.unreadCount,
  });

  String _formatTime(DateTime? t) {
    if (t == null) return '';
    final now = DateTime.now();
    final isToday =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (isToday) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final briefAsync = ref.watch(chatUserBriefProvider(otherUid));

    return briefAsync.when(
      data: (member) {
        final fullName = member == null
            ? l10n.defaultUserName
            : '${member.firstName} ${member.lastName}'.trim();
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () =>
              AppPageRoute.push(context, ChatScreen(otherUid: otherUid)),
          child: Row(
            children: [
              UserAvatar(
                size: 48,
                firstName: member?.firstName ?? '',
                lastName: member?.lastName ?? '',
                photoUrl: member?.photoUrl,
                seed: otherUid,
                isOnline: member?.isOnline ?? false,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: context.cardTitleStyle),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.secondaryStyle.copyWith(
                        fontWeight:
                            unreadCount > 0 ? FontWeight.w700 : FontWeight.w400,
                        color: unreadCount > 0
                            ? context.textPrimary
                            : context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatTime(conversation.lastMessageAt),
                      style: context.captionStyle),
                  const SizedBox(height: AppSpacing.xs),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () =>
          const ShimmerBox(height: 64, borderRadius: AppRadius.mdAll),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
