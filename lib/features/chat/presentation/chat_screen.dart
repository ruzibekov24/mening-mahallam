import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/neighbor_profile_screen.dart';
import '../data/chat_providers.dart';
import '../data/chat_repository.dart';

/// Ikkita foydalanuvchi orasidagi suhbat ekrani — real-vaqtli xabar
/// oqimi, pastda matn kiritish maydoni.
class ChatScreen extends ConsumerStatefulWidget {
  final String otherUid;
  const ChatScreen({super.key, required this.otherUid});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();
  bool _isSending = false;

  String get _conversationId => ref
      .read(chatRepositoryProvider)
      .conversationIdFor(
        FirebaseAuth.instance.currentUser?.uid ?? '',
        widget.otherUid,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatRepositoryProvider).markConversationRead(_conversationId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    final myProfile = ref.read(currentUserProfileProvider).valueOrNull;
    final myName = myProfile == null
        ? ''
        : '${myProfile.firstName} ${myProfile.lastName}'.trim();

    setState(() => _isSending = true);
    _textController.clear();
    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            otherUid: widget.otherUid,
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
    final otherBriefAsync = ref.watch(chatUserBriefProvider(widget.otherUid));
    final messagesAsync =
        ref.watch(conversationMessagesProvider(_conversationId));

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
                  Expanded(
                    child: otherBriefAsync.when(
                      data: (member) => InkWell(
                        borderRadius: AppRadius.smAll,
                        onTap: member == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        NeighborProfileScreen(member: member),
                                  ),
                                ),
                        child: Row(
                          children: [
                            UserAvatar(
                              size: 36,
                              firstName: member?.firstName ?? '',
                              lastName: member?.lastName ?? '',
                              photoUrl: member?.photoUrl,
                              seed: widget.otherUid,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                member == null
                                    ? l10n.defaultUserName
                                    : '${member.firstName} ${member.lastName}'
                                        .trim(),
                                style: context.titleStyle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      loading: () => const Row(
                        children: [
                          SizedBox(width: 36, height: 36),
                          SizedBox(width: AppSpacing.sm),
                        ],
                      ),
                      error: (_, __) => const Row(
                        children: [
                          SizedBox(width: 36, height: 36),
                          SizedBox(width: AppSpacing.sm),
                        ],
                      ),
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
                      return _MessageBubble(message: message, isMine: isMine);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Text(l10n.unexpectedError, style: context.secondaryStyle),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  const _MessageBubble({required this.message, required this.isMine});

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.75),
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
    );
  }
}
