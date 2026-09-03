import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/utils/content_filter.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/feed_providers.dart';
import '../data/feed_repository.dart';
import 'post_detail_screen.dart';
import 'video_player_screen.dart';

/// Post ostidagi emoji reaksiya tugmalari qatori — announcements'dagi
/// `ReactionRow` bilan bir xil naqsh, faqat `Post`/`FeedRepository`
/// uchun (ikkalasini bitta generic widget qilib birlashtirish shart
/// emas — ikkita mustaqil kolleksiya, dublikatsiya kam va aniq).
class PostReactionRow extends ConsumerWidget {
  final Post post;
  final String mahallaId;
  const PostReactionRow({super.key, required this.post, required this.mahallaId});

  static const _emojis = ['👍', '❤️', '😮', '😂'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myEmoji = myUid == null ? null : post.reactedUids[myUid];

    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final emoji in _emojis)
          _ReactionChip(
            emoji: emoji,
            count: post.reactionCount(emoji),
            isActive: myEmoji == emoji,
            onTap: myUid == null || profile?.mahallaId == null
                ? null
                : () => ref.read(feedRepositoryProvider).toggleReaction(
                      mahallaId: mahallaId,
                      postId: post.id,
                      uid: myUid,
                      emoji: emoji,
                      currentEmoji: myEmoji,
                    ),
            onLongPress: post.reactedUids.isEmpty
                ? null
                : () => _showReactorsSheet(context, ref, post),
          ),
      ],
    );
  }
}

/// Reaksiya chipini uzoq bosganda kim reaksiya bildirganini
/// ko'rsatuvchi bottom sheet — `reactedUids`dagi uid'lar uchun
/// ismlarni `FeedRepository.fetchUserNames` orqali oladi.
void _showReactorsSheet(BuildContext context, WidgetRef ref, Post post) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.reactionsSheetTitle, style: sheetContext.sectionStyle),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<Map<String, String>>(
              future: ref
                  .read(feedRepositoryProvider)
                  .fetchUserNames(post.reactedUids.keys.toList()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final names = snapshot.data!;
                return Column(
                  children: post.reactedUids.entries
                      .map((entry) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs),
                            child: Row(
                              children: [
                                Text(entry.value,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    names[entry.key] ?? "Qo'shni",
                                    style: context.bodyStyle,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

String _postTimeAgo(BuildContext context, DateTime dt) {
  final l10n = AppLocalizations.of(context);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
  return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

/// Lentadagi bitta foydalanuvchi posti kartochkasi.
class PostCard extends ConsumerWidget {
  final Post post;
  final String mahallaId;
  const PostCard({super.key, required this.post, required this.mahallaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final canDelete = myUid != null &&
        (myUid == post.authorUid ||
            ref.watch(currentUserProfileProvider).valueOrNull?.role.canPost ==
                true);
    // Faqat matnni o'zi yozgan foydalanuvchi tahrirlashi mumkin —
    // repostlar tahrirlanmaydi, chunki `repostSnapshot` original
    // postning holatini aks ettiradi, o'zining matni yo'q.
    final canEdit = myUid != null && myUid == post.authorUid && !post.isRepost;

    // Repost bo'lsa, karta tanasi original mualliflik/matn/rasmni
    // (`repostSnapshot`) ko'rsatadi — ustidagi "X repost qildi"
    // qatori esa repost qilgan kishini bildiradi (`post.authorName`).
    final displayAuthorName =
        post.isRepost ? post.repostSnapshot!.authorName : post.authorName;
    final displayPhotoUrl = post.isRepost ? null : post.authorPhotoUrl;
    final displayText =
        post.isRepost ? post.repostSnapshot!.textPreview : post.text;
    final displayImageUrls = post.isRepost
        ? [if (post.repostSnapshot!.imageUrl != null) post.repostSnapshot!.imageUrl!]
        : post.imageUrls;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      onTap: () => AppPageRoute.push(
        context,
        PostDetailScreen(mahallaId: mahallaId, postId: post.id),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isRepost) ...[
            Row(
              children: [
                Icon(PhosphorIconsFill.repeat,
                    size: 14, color: context.textSecondary),
                const SizedBox(width: AppSpacing.xxs),
                Text(l10n.repostedByLabel(post.authorName),
                    style: context.captionStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppAccents.announcements.withValues(alpha: 0.14),
                backgroundImage: displayPhotoUrl != null && displayPhotoUrl.isNotEmpty
                    ? CachedNetworkImageProvider(displayPhotoUrl)
                    : null,
                child: displayPhotoUrl == null || displayPhotoUrl.isEmpty
                    ? const Icon(PhosphorIconsFill.user,
                        size: 16, color: AppAccents.announcements)
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayAuthorName, style: context.cardTitleStyle),
                    Text(_postTimeAgo(context, post.createdAt),
                        style: context.captionStyle),
                  ],
                ),
              ),
              if (canEdit || canDelete)
                PopupMenuButton<void>(
                  icon: Icon(PhosphorIconsBold.dotsThreeVertical,
                      size: 16, color: context.textMuted),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  tooltip: '',
                  shape:
                      const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
                  itemBuilder: (context) => [
                    if (canEdit)
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 1));
                          if (!context.mounted) return;
                          await _showEditPostDialog(context, ref, post, mahallaId);
                        },
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.pencilSimple,
                                size: 18, color: context.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.editButton, style: context.bodyStyle),
                          ],
                        ),
                      ),
                    if (canDelete)
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 1));
                          if (!context.mounted) return;
                          final confirmed = await confirmDelete(
                            context,
                            itemTitle: displayText,
                          );
                          if (!confirmed || !context.mounted) return;
                          await ref.read(feedRepositoryProvider).deletePost(
                                mahallaId: mahallaId,
                                postId: post.id,
                              );
                          if (context.mounted) {
                            showAppAlert(context, l10n.itemDeletedMessage);
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.trash,
                                size: 18, color: AppColors.danger),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.deleteButton,
                                style: context.bodyStyle
                                    .copyWith(color: AppColors.danger)),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
          if (displayText.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(displayText, style: context.bodyStyle),
          ],
          if (displayImageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: AppRadius.smAll,
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayImageUrls.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (context, index) {
                    final url = displayImageUrls[index];
                    if (isVideoUrl(url)) {
                      return _FeedVideoThumb(videoUrl: url);
                    }
                    return CachedNetworkImage(
                      imageUrl: url,
                      width: 160,
                      height: 160,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 160,
                        color: AppAccents.announcements.withValues(alpha: 0.08),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        width: 160,
                        color: AppAccents.announcements.withValues(alpha: 0.08),
                        child: const Icon(PhosphorIconsRegular.imageBroken),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              PostReactionRow(post: post, mahallaId: mahallaId),
              const Spacer(),
              if (!post.isRepost)
                Builder(builder: (context) {
                  final hasReposted =
                      myUid != null && post.repostedByUids.containsKey(myUid);
                  return Semantics(
                  button: true,
                  selected: hasReposted,
                  label: l10n.repostAction,
                  child: TapScale(
                  haptic: true,
                  onTap: myUid == null
                      ? null
                      : () async {
                          final profile =
                              ref.read(currentUserProfileProvider).valueOrNull;
                          final authorName =
                              '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'
                                  .trim();
                          try {
                            await ref.read(feedRepositoryProvider).toggleRepost(
                                  mahallaId: mahallaId,
                                  original: post,
                                  authorName:
                                      authorName.isEmpty ? "Qo'shni" : authorName,
                                  authorPhotoUrl: profile?.photoUrl,
                                );
                            if (context.mounted) {
                              showAppAlert(
                                context,
                                hasReposted
                                    ? l10n.repostRemovedMessage
                                    : l10n.repostSuccessMessage,
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              showAppAlert(context, l10n.unexpectedError,
                                  kind: AppAlertKind.error);
                            }
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsRegular.repeat,
                          size: 16,
                          color: hasReposted
                              ? AppAccents.announcements
                              : context.textSecondary),
                      if (post.repostCount > 0) ...[
                        const SizedBox(width: AppSpacing.xxs),
                        Text('${post.repostCount}',
                            style: context.captionStyle.copyWith(
                              color: hasReposted
                                  ? AppAccents.announcements
                                  : null,
                              fontWeight:
                                  hasReposted ? FontWeight.w700 : null,
                            )),
                      ],
                    ],
                  ),
                  ),
                  );
                }),
              const SizedBox(width: AppSpacing.md),
              Icon(PhosphorIconsRegular.chatCircle,
                  size: 16, color: context.textSecondary),
              const SizedBox(width: AppSpacing.xxs),
              Text(l10n.commentsTitle, style: context.captionStyle),
            ],
          ),
        ],
      ),
    );
  }
}

/// Post matnini tahrirlash uchun oddiy dialog — rasm o'zgartirilmaydi,
/// faqat matn (yangi rasm/video qo'shish kerak bo'lsa foydalanuvchi
/// yangi post yaratadi).
Future<void> _showEditPostDialog(
  BuildContext context,
  WidgetRef ref,
  Post post,
  String mahallaId,
) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(text: post.text);
  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.editPostTitle),
      content: TextField(
        controller: controller,
        autofocus: true,
        minLines: 3,
        maxLines: 8,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(hintText: l10n.writePostHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.saveButton),
        ),
      ],
    ),
  );
  if (saved != true) return;

  final newText = controller.text.trim();
  if (newText.isEmpty || newText == post.text) return;
  if (!context.mounted) return;
  if (containsBannedWords(newText)) {
    showAppAlert(context, l10n.inappropriateContentError,
        kind: AppAlertKind.error);
    return;
  }
  try {
    await ref.read(feedRepositoryProvider).updatePost(
          mahallaId: mahallaId,
          postId: post.id,
          text: newText,
        );
    if (context.mounted) showAppAlert(context, l10n.postUpdatedMessage);
  } catch (_) {
    if (context.mounted) {
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }
}

/// Post kartochkasidagi video preview — haqiqiy kadr ko'rsatmaydi
/// (bu qo'shimcha yuklashni talab qilardi), shunchaki qora fon +
/// play belgisi, bosilganda [VideoPlayerScreen] to'liq ekranda ochadi.
class _FeedVideoThumb extends StatelessWidget {
  final String videoUrl;
  const _FeedVideoThumb({required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppPageRoute.push(
        context,
        VideoPlayerScreen(videoUrl: videoUrl),
      ),
      child: Container(
        width: 160,
        height: 160,
        color: Colors.black87,
        alignment: Alignment.center,
        child: const Icon(
          PhosphorIconsFill.playCircle,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppAccents.announcements;
    return Semantics(
      button: true,
      selected: isActive,
      value: '$count',
      label: emoji,
      child: GestureDetector(
      onLongPress: onLongPress,
      child: TapScale(
      onTap: onTap,
      haptic: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color:
              isActive ? color.withValues(alpha: 0.14) : context.surfaceColor,
          borderRadius: AppRadius.pillAll,
          border: Border.all(
            color: isActive ? color : context.borderColor,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            if (count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$count',
                style: context.captionStyle.copyWith(
                  color: isActive ? color : context.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      ),
      ),
    );
  }
}
