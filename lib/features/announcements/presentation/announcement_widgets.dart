import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../home/data/home_repository.dart';
import '../data/announcement_repository.dart';
import '../data/announcements_providers.dart';

/// E'lon ostidagi emoji reaksiya tugmalari qatori — ro'yxat kartasi
/// (`announcements_screen.dart`) va tafsilot ekrani
/// (`announcement_detail_screen.dart`) BIR XIL widget'dan foydalanadi,
/// dublikatsiz.
class ReactionRow extends ConsumerWidget {
  final Announcement announcement;
  const ReactionRow({super.key, required this.announcement});

  /// Firestore'da saqlanadigan emoji -> iOS (Apple) uslubidagi PNG.
  static const _emojis = ['👍', '❤️', '😮', '😂'];
  static const _emojiAssets = {
    '👍': 'assets/images/emoji/thumbsup.png',
    '❤️': 'assets/images/emoji/heart.png',
    '😮': 'assets/images/emoji/wow.png',
    '😂': 'assets/images/emoji/laugh.png',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myEmoji = myUid == null ? null : announcement.reactedUids[myUid];

    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        for (final emoji in _emojis)
          _ReactionChip(
            emoji: emoji,
            asset: _emojiAssets[emoji]!,
            count: announcement.reactionCount(emoji),
            isActive: myEmoji == emoji,
            onTap: myUid == null || profile?.mahallaId == null
                ? null
                : () => ref.read(announcementRepositoryProvider).toggleReaction(
                      mahallaId: profile!.mahallaId!,
                      announcementId: announcement.id,
                      uid: myUid,
                      emoji: emoji,
                      currentEmoji: myEmoji,
                    ),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final String asset;
  final int count;
  final bool isActive;
  final VoidCallback? onTap;

  const _ReactionChip({
    required this.emoji,
    required this.asset,
    required this.count,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const color = AppAccents.announcements;
    return TapScale(
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
            Image.asset(asset, width: 18, height: 18),
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
    );
  }
}
