import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';
import 'chat_screen.dart';

/// Barcha suhbatlar ro'yxati — Profil menyusidagi "Xabarlar" orqali
/// ochiladi.
class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final conversationsAsync = ref.watch(myConversationsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      // Bu ekran Navigator.push bilan ochiladi — orqasida
      // MainShell foni YO'Q. Shaffof qoldirilsa ekran qop-qora
      // bo'lib ko'rinardi. Rang berilmasa mavzudagi
      // `scaffoldBackgroundColor` ishlaydi (dark mode ham).
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.conversationsTitle,
                      style: context.titleStyle.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: conversationsAsync.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.chatDots,
                      title: l10n.noConversationsYet,
                      subtitle: l10n.noConversationsHint,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      final otherUid = conversation.otherUid(myUid ?? '');
                      final unread = conversation.unreadCounts[myUid] ?? 0;
                      return StaggeredEntrance(
                        index: index,
                        child: _ConversationTile(
                          conversation: conversation,
                          otherUid: otherUid,
                          unreadCount: unread,
                        ),
                      );
                    },
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
              ),
            ),
          ],
        ),
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
    final l10n = AppLocalizations.of(context)!;
    final briefAsync = ref.watch(chatUserBriefProvider(otherUid));

    return briefAsync.when(
      data: (member) {
        final fullName = member == null
            ? l10n.defaultUserName
            : '${member.firstName} ${member.lastName}'.trim();
        return AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(otherUid: otherUid),
            ),
          ),
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
      loading: () => const ShimmerBox(height: 64, borderRadius: AppRadius.mdAll),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
