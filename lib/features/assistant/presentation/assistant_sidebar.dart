import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart' show ShimmerList;
import '../../../l10n/app_localizations.dart';
import '../data/assistant_chat_repository.dart';

/// `AssistantScreen`ning `Drawer`i ichida ko'rsatiladigan, AI Yordamchi
/// (Mahal) bilan bo'lgan barcha saqlangan suhbatlar ro'yxati — avvalgi
/// alohida `AssistantChatsListScreen` marshrutining o'rnini bosadi.
/// Bu yerda tanlash ekranni almashtirmaydi (push qilmaydi) — shunchaki
/// varaqni yopadi va [onSelectChat] orqali `AssistantScreen`ga hozirgi
/// suhbatni shu joyning o'zida almashtirishni buyuradi.
class AssistantSidebar extends ConsumerWidget {
  final String? activeChatId;
  final ValueChanged<AssistantChatSummary?> onSelectChat;

  const AssistantSidebar({
    super.key,
    required this.activeChatId,
    required this.onSelectChat,
  });

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    AssistantChatSummary chat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        title: Text(l10n.assistantDeleteChatTitle),
        content: Text(l10n.assistantDeleteChatMessage(chat.title)),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.deleteButton,
                style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(assistantChatRepositoryProvider).deleteChat(chat.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(assistantChatsProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              l10n.assistantScreenTitle,
              style: context.titleStyle,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: TapScale(
              onTap: () {
                Navigator.of(context).pop();
                onSelectChat(null);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.plus,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.assistantNewChat,
                      style: context.bodyStyle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          Expanded(
            child: chatsAsync.when(
              data: (chats) {
                if (chats.isEmpty) {
                  return AppEmptyView(
                    icon: PhosphorIconsFill.sparkle,
                    title: l10n.assistantGreetingTitle,
                    subtitle: l10n.assistantGreetingSubtitle,
                    scrollable: true,
                  );
                }
                return ListView.builder(
                  padding: AppSpacing.listPadding,
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return _SidebarChatTile(
                      chat: chat,
                      isActive: chat.id == activeChatId,
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectChat(chat);
                      },
                      onDelete: () =>
                          _confirmDelete(context, ref, l10n, chat),
                    );
                  },
                );
              },
              loading: () => ListView(
                padding: AppSpacing.listPadding,
                children: const [ShimmerList(count: 6)],
              ),
              error: (error, _) => AppErrorView.fromError(error,
                  onRetry: () => ref.invalidate(assistantChatsProvider)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarChatTile extends StatelessWidget {
  final AssistantChatSummary chat;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _SidebarChatTile({
    required this.chat,
    required this.isActive,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : context.surfaceColor,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: isActive ? AppColors.primary : context.borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.sparkle,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d MMM, HH:mm').format(chat.updatedAt),
                    style: context.captionStyle,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(PhosphorIconsRegular.trash,
                  size: 18, color: context.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
