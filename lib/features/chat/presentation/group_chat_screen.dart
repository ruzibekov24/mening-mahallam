import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/chat_providers.dart';
import '../data/group_chat_repository.dart';

/// Guruh chati ekrani — 1:1 `ChatScreen`ga o'xshash, lekin har bir
/// xabar ustida (o'zimniki bo'lmasa) yuboruvchining ismi ko'rsatiladi,
/// chunki guruhda kim yozganini bilish shart.
class GroupChatScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupChatScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends ConsumerState<GroupChatScreen> {
  final _textController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final myName = myProfile == null
        ? ''
        : '${myProfile.firstName} ${myProfile.lastName}'.trim();

    setState(() => _isSending = true);
    _textController.clear();
    try {
      await ref.read(groupChatRepositoryProvider).sendGroupMessage(
            groupId: widget.groupId,
            senderUid: myUid,
            text: text,
            senderFullName: myName,
          );
    } catch (_) {
      _textController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final groupAsync = ref.watch(groupChatProvider(widget.groupId));
    final messagesAsync = ref.watch(groupChatMessagesProvider(widget.groupId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppAccents.neighbors,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(PhosphorIconsFill.usersThree,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: groupAsync.when(
                      data: (group) => Text(
                        group?.name ?? '',
                        style: context.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: messagesAsync.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noMessagesYet,
                        style: context.secondaryStyle,
                      ),
                    );
                  }
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMine = message.senderUid == myUid;
                      return _GroupMessageBubble(
                        message: message,
                        isMine: isMine,
                        onReport: isMine
                            ? null
                            : () {
                                final mahallaId = ref
                                    .read(currentUserProfileProvider)
                                    .valueOrNull
                                    ?.mahallaId;
                                showReportSheet(
                                  context,
                                  ref,
                                  targetType: ReportTargetType.chatMessage,
                                  targetId: message.id,
                                  targetSnippet: message.text,
                                  mahallaId: mahallaId,
                                );
                              },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child:
                      Text(l10n.unexpectedError, style: context.secondaryStyle),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? AppColors.darkSurface
                              : AppColors.lightBorder,
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: l10n.messageHint,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          style: context.bodyStyle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Material(
                      color: AppColors.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isSending ? null : _send,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isSending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(PhosphorIconsFill.paperPlaneRight,
                                  size: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMessageBubble extends ConsumerWidget {
  final GroupChatMessage message;
  final bool isMine;

  /// Boshqa a'zoning xabarini uzoq bosganda shikoyat qilish uchun
  /// chaqiriladi. O'z xabaringiz uchun `null`.
  final VoidCallback? onReport;

  const _GroupMessageBubble({
    required this.message,
    required this.isMine,
    this.onReport,
  });

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1:1 chatdan farqli: guruhda kim yozganini bilish shart bo'lgani
    // uchun o'ziniki bo'lmagan xabarlar ustida yuboruvchi ismi
    // ko'rsatiladi. `chatUserBriefProvider` mavjud 1:1 chat ekranida
    // ham ishlatiladigan bir xil "uid -> qisqa profil" provideri.
    final senderBriefAsync = isMine
        ? null
        : ref.watch(chatUserBriefProvider(message.senderUid));
    final senderName = senderBriefAsync?.valueOrNull == null
        ? null
        : '${senderBriefAsync!.valueOrNull!.firstName} ${senderBriefAsync.valueOrNull!.lastName}'
            .trim();

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onReport,
        child: Container(
          constraints:
              BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isMine
                ? AppColors.primary
                : (context.isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.lightBorder),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMine && senderName != null && senderName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    senderName,
                    style: context.captionStyle.copyWith(
                      color: AppAccents.neighbors,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                message.text,
                style: context.bodyStyle.copyWith(
                  color: isMine ? Colors.white : context.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(message.createdAt),
                style: context.captionStyle.copyWith(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.75)
                      : context.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
