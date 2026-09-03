import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/feed_providers.dart';
import '../data/feed_repository.dart';
import 'post_widgets.dart';

/// Bitta post + izohlar ro'yxati + izoh yozish paneli — `requests`
/// murojaat tafsilot ekranidagi `_CommentsSection` naqshiga asoslanadi.
class PostDetailScreen extends ConsumerWidget {
  final String mahallaId;
  final String postId;
  const PostDetailScreen(
      {super.key, required this.mahallaId, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final postStream = ref.watch(feedRepositoryProvider).watchPostById(
          mahallaId: mahallaId,
          postId: postId,
        );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(l10n.feedTitle, style: context.titleStyle),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<Post?>(
                stream: postStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListView(
                      padding: AppSpacing.listPadding,
                      children: const [ShimmerList(count: 3)],
                    );
                  }
                  final post = snapshot.data;
                  if (post == null) {
                    return Center(
                      child: Text(l10n.searchNoResults,
                          style: context.secondaryStyle),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0,
                        AppSpacing.xl, AppSpacing.xl),
                    children: [
                      PostCard(post: post, mahallaId: mahallaId),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => showReportSheet(
                            context,
                            ref,
                            targetType: ReportTargetType.post,
                            targetId: post.id,
                            targetSnippet: post.text,
                            mahallaId: mahallaId,
                          ),
                          icon: const Icon(PhosphorIconsRegular.flag, size: 14),
                          label: Text(l10n.reportSheetTitle),
                          style: TextButton.styleFrom(
                            foregroundColor: context.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PostCommentsSection(mahallaId: mahallaId, postId: postId),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCommentsSection extends ConsumerStatefulWidget {
  final String mahallaId;
  final String postId;
  const _PostCommentsSection({required this.mahallaId, required this.postId});

  @override
  ConsumerState<_PostCommentsSection> createState() =>
      _PostCommentsSectionState();
}

class _PostCommentsSectionState extends ConsumerState<_PostCommentsSection> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    if (containsBannedWords(text)) {
      showAppAlert(context, AppLocalizations.of(context).inappropriateContentError,
          kind: AppAlertKind.error);
      return;
    }
    final profile = ref.read(currentUserProfileProvider).valueOrNull;
    final authorName = '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();
    setState(() => _isSending = true);
    try {
      await ref.read(feedRepositoryProvider).addComment(
            mahallaId: widget.mahallaId,
            postId: widget.postId,
            authorName: authorName.isEmpty ? 'Qo\'shni' : authorName,
            text: text,
          );
      _controller.clear();
    } catch (_) {
      if (mounted) {
        showAppAlert(context, AppLocalizations.of(context).unexpectedError,
            kind: AppAlertKind.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref
        .watch(postCommentsProvider('${widget.mahallaId}:${widget.postId}'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.commentsTitle, style: context.sectionStyle),
        const SizedBox(height: AppSpacing.sm),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(l10n.noCommentsYet, style: context.secondaryStyle),
              );
            }
            return Column(
              children: comments
                  .map((comment) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PostCommentBubble(
                          comment: comment,
                          formattedTime: _formatTime(comment.createdAt),
                          mahallaId: widget.mahallaId,
                          postId: widget.postId,
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: ShimmerListTile(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBorder,
                  borderRadius: AppRadius.pillAll,
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.commentHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      ],
    );
  }
}

class _PostCommentBubble extends ConsumerWidget {
  final PostComment comment;
  final String formattedTime;
  final String mahallaId;
  final String postId;

  const _PostCommentBubble({
    required this.comment,
    required this.formattedTime,
    required this.mahallaId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isMine = comment.authorUid == myUid;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isMine
            ? AppColors.primary.withValues(alpha: 0.06)
            : context.surfaceColor,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(comment.authorName, style: context.cardTitleStyle),
              ),
              Text(formattedTime, style: context.captionStyle),
              if (isMine) ...[
                const SizedBox(width: AppSpacing.xs),
                InkWell(
                  onTap: () async {
                    final confirmed = await confirmDelete(
                      context,
                      itemTitle: comment.text,
                    );
                    if (!confirmed || !context.mounted) return;
                    await ref.read(feedRepositoryProvider).deleteComment(
                          mahallaId: mahallaId,
                          postId: postId,
                          commentId: comment.id,
                        );
                    if (context.mounted) {
                      showAppAlert(context, l10n.itemDeletedMessage);
                    }
                  },
                  child: Icon(PhosphorIconsRegular.trash,
                      size: 15, color: context.textMuted),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(comment.text, style: context.bodyStyle),
        ],
      ),
    );
  }
}
