import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart' show ShimmerList;
import '../data/assistant_chat_repository.dart';
import 'assistant_screen.dart';

/// AI Yordamchi bilan bo'lgan barcha (saqlangan) suhbatlar ro'yxati —
/// Home ekrani va Sozlamalardagi ✨ belgisi shu yerga olib keladi.
/// "Yangi suhbat" tugmasi bo'sh (chatId'siz) `AssistantScreen` ochadi,
/// u birinchi xabar yuborilganda avtomatik ravishda shu ro'yxatga
/// qo'shiladi.
class AssistantChatsListScreen extends ConsumerWidget {
  const AssistantChatsListScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AssistantChatSummary chat,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        title: const Text("Suhbatni o'chirish"),
        content: Text('"${chat.title}" suhbatini butunlay o\'chirmoqchimisiz?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("O'chirish",
                style: TextStyle(color: AppColors.danger)),
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
    final chatsAsync = ref.watch(assistantChatsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AssistantScreen()),
        ),
        icon: const Icon(PhosphorIconsFill.plus),
        label: const Text('Yangi suhbat'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppColors.primary,
              image: 'assets/images/patterns/abstract_blue.png',
              watermarkIcon: PhosphorIconsFill.sparkle,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text('AI Yordamchi',
                      style: context.titleStyle.copyWith(color: Colors.white)),
                ],
              ),
            ),
            Expanded(
              child: chatsAsync.when(
                data: (chats) {
                  if (chats.isEmpty) {
                    return const AppEmptyView(
                      icon: PhosphorIconsFill.sparkle,
                      title: 'Hali suhbatlar yo\'q',
                      subtitle:
                          'Yangi suhbat boshlash uchun pastdagi tugmani bosing',
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding.copyWith(bottom: 96),
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      return StaggeredEntrance(
                        index: index,
                        child: _ChatTile(
                          chat: chats[index],
                          onDelete: () =>
                              _confirmDelete(context, ref, chats[index]),
                        ),
                      );
                    },
                  );
                },
                loading: () => const _ChatsListShimmer(),
                error: (error, _) => AppErrorView.fromError(error,
                    onRetry: () => ref.invalidate(assistantChatsProvider)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final AssistantChatSummary chat;
  final VoidCallback onDelete;
  const _ChatTile({required this.chat, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              AssistantScreen(chatId: chat.id, initialTitle: chat.title),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.sparkle,
                  color: AppColors.primary, size: 18),
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

class _ChatsListShimmer extends StatelessWidget {
  const _ChatsListShimmer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.listPadding,
      children: const [ShimmerList(count: 6)],
    );
  }
}
