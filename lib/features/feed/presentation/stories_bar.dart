import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/story_providers.dart';
import '../data/story_repository.dart';
import 'story_viewer_screen.dart';

/// Bitta muallifning barcha faol hikoyalari — halqa rangini (ko'rilgan
/// / ko'rilmagan) va viewer ochilganda boshlanish nuqtasini aniqlash
/// uchun guruhlangan.
class _StoryGroup {
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final List<Story> stories;
  _StoryGroup({
    required this.authorUid,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.stories,
  });
}

/// Lenta tepasidagi gorizontal hikoyalar qatori — birinchi doira doim
/// "hikoya qo'shish" (joriy foydalanuvchi), keyingilari — faol
/// hikoyasi bor har bir mualliflik uchun bittadan halqa.
class StoriesBar extends ConsumerWidget {
  final String mahallaId;
  const StoriesBar({super.key, required this.mahallaId});

  Future<void> _addStory(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    try {
      final profile = ref.read(currentUserProfileProvider).valueOrNull;
      final authorName =
          '${profile?.firstName ?? ''} ${profile?.lastName ?? ''}'.trim();
      final url = await ImageUploadService().uploadFile(
        file: File(picked.path),
        storagePath:
            'stories/$mahallaId/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.read(storyRepositoryProvider).createStory(
            mahallaId: mahallaId,
            authorName: authorName.isEmpty ? "Qo'shni" : authorName,
            authorPhotoUrl: profile?.photoUrl,
            mediaUrl: url,
          );
    } on ImageUploadException catch (e) {
      if (context.mounted) {
        showAppAlert(context, e.message, kind: AppAlertKind.error);
      }
    } catch (_) {
      if (context.mounted) {
        showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final storiesAsync = ref.watch(activeStoriesProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final stories = storiesAsync.valueOrNull ?? const <Story>[];

    final groups = <_StoryGroup>[];
    for (final story in stories) {
      _StoryGroup? existing;
      for (final g in groups) {
        if (g.authorUid == story.authorUid) {
          existing = g;
          break;
        }
      }
      if (existing != null) {
        existing.stories.add(story);
      } else {
        groups.add(_StoryGroup(
          authorUid: story.authorUid,
          authorName: story.authorName,
          authorPhotoUrl: story.authorPhotoUrl,
          stories: [story],
        ));
      }
    }

    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          _StoryCircle(
            label: l10n.addStoryLabel,
            onTap: () => _addStory(context, ref),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: context.borderColor),
              ),
              child: const Icon(PhosphorIconsBold.plus, color: AppColors.primary),
            ),
          ),
          for (final group in groups)
            _StoryCircle(
              label: group.authorUid == myUid
                  ? l10n.yourStoryLabel
                  : group.authorName,
              onTap: () {
                final flatIndex = stories.indexOf(group.stories.first);
                AppPageRoute.push(
                  context,
                  StoryViewerScreen(
                    mahallaId: mahallaId,
                    stories: stories,
                    initialIndex: flatIndex,
                  ),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: (myUid != null &&
                          group.stories.every((s) => s.isViewedBy(myUid)))
                      ? null
                      : const LinearGradient(
                          colors: [AppAccents.events, AppColors.primary],
                        ),
                  border: (myUid != null &&
                          group.stories.every((s) => s.isViewedBy(myUid)))
                      ? Border.all(color: context.borderColor)
                      : null,
                ),
                child: CircleAvatar(
                  backgroundColor: AppAccents.announcements.withValues(alpha: 0.14),
                  backgroundImage: group.authorPhotoUrl != null &&
                          group.authorPhotoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(group.authorPhotoUrl!)
                      : null,
                  child: group.authorPhotoUrl == null || group.authorPhotoUrl!.isEmpty
                      ? const Icon(PhosphorIconsFill.user,
                          size: 20, color: AppAccents.announcements)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StoryCircle extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;
  const _StoryCircle(
      {required this.label, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: TapScale(
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(
            children: [
              child,
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.captionStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
