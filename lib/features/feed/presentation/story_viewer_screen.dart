import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../l10n/app_localizations.dart';
import '../../moderation/data/report_repository.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/story_providers.dart';
import '../data/story_repository.dart';

/// To'liq ekran hikoya ko'ruvchisi — Instagram-uslubidagi tap-through:
/// har bir hikoya belgilangan vaqt (5s) davomida ko'rsatiladi, keyin
/// avtomatik keyingisiga o'tadi; ekranning o'ng 2/3 qismiga bosish —
/// keyingisi, chap 1/3 — oldingisi.
class StoryViewerScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  final List<Story> stories;
  final int initialIndex;

  const StoryViewerScreen({
    super.key,
    required this.mahallaId,
    required this.stories,
    required this.initialIndex,
  });

  @override
  ConsumerState<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends ConsumerState<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
  late int _index = widget.initialIndex;

  @override
  void initState() {
    super.initState();
    _startCurrent();
  }

  @override
  void dispose() {
    _progress.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startCurrent() {
    _progress
      ..reset()
      ..forward();
    final story = widget.stories[_index];
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && !story.isViewedBy(uid)) {
      ref.read(storyRepositoryProvider).markViewed(
            mahallaId: widget.mahallaId,
            storyId: story.id,
            uid: uid,
          );
    }
  }

  void _goNext() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  void _goPrevious() {
    if (_index <= 0) return;
    _pageController.previousPage(
        duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  Future<void> _delete(Story story) async {
    final l10n = AppLocalizations.of(context);
    _progress.stop();
    final confirmed =
        await confirmDelete(context, itemTitle: story.authorName);
    if (!confirmed || !mounted) return;
    try {
      await ref.read(storyRepositoryProvider).deleteStory(
            mahallaId: widget.mahallaId,
            storyId: story.id,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
        _progress.forward();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.stories.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _startCurrent();
              },
              itemBuilder: (context, i) {
                final story = widget.stories[i];
                return GestureDetector(
                  onTapUp: (details) {
                    final width = MediaQuery.sizeOf(context).width;
                    if (details.globalPosition.dx < width / 3) {
                      _goPrevious();
                    } else {
                      _progress.stop();
                      _goNext();
                    }
                  },
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorWidget: (_, __, ___) => const Icon(
                          PhosphorIconsRegular.imageBroken,
                          color: Colors.white38,
                          size: 48),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: [
                  for (var i = 0; i < widget.stories.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: AppRadius.pillAll,
                        child: SizedBox(
                          height: 3,
                          child: i < _index
                              ? const ColoredBox(color: Colors.white)
                              : i > _index
                                  ? ColoredBox(
                                      color: Colors.white.withValues(alpha: 0.3))
                                  : AnimatedBuilder(
                                      animation: _progress,
                                      builder: (context, _) => LinearProgressIndicator(
                                        value: _progress.value,
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.3),
                                        valueColor: const AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: AppSpacing.lg,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white24,
                    backgroundImage: widget.stories[_index].authorPhotoUrl !=
                                null &&
                            widget.stories[_index].authorPhotoUrl!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            widget.stories[_index].authorPhotoUrl!)
                        : null,
                    child: widget.stories[_index].authorPhotoUrl == null ||
                            widget.stories[_index].authorPhotoUrl!.isEmpty
                        ? const Icon(PhosphorIconsFill.user,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(widget.stories[_index].authorName,
                        style: context.bodyStyle.copyWith(color: Colors.white)),
                  ),
                  if (widget.stories[_index].authorUid == myUid)
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.trash,
                          color: Colors.white),
                      onPressed: () => _delete(widget.stories[_index]),
                    )
                  else
                    IconButton(
                      icon: const Icon(PhosphorIconsRegular.flag,
                          color: Colors.white),
                      onPressed: () {
                        _progress.stop();
                        showReportSheet(
                          context,
                          ref,
                          targetType: ReportTargetType.story,
                          targetId: widget.stories[_index].id,
                          targetSnippet: widget.stories[_index].authorName,
                          mahallaId: widget.mahallaId,
                        ).then((_) {
                          if (mounted) _progress.forward();
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(PhosphorIconsBold.x, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
