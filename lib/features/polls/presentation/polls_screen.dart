import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/poll_repository.dart';
import '../data/polls_providers.dart';
import '../../../core/widgets/app_alert.dart';

/// So'rovnomalar ekrani — xodim/rais savol yaratadi, barcha a'zolar
/// bitta variantga ovoz beradi, natijalar jonli (real-time) chiziq
/// diagramma sifatida ko'rinadi.
class PollsScreen extends ConsumerWidget {
  const PollsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final pollsAsync = ref.watch(mahallaPollsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

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
              color: AppAccents.neighbors,
              image: 'assets/images/patterns/abstract_purple.png',
              watermarkIcon: PhosphorIconsFill.chartBar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsRegular.arrowLeft,
                        color: Colors.white),
                  ),
                  Expanded(
                    child: Text(l10n.pollsTitle,
                        style: context.titleStyle
                            .copyWith(color: Colors.white)),
                  ),
                  profileAsync.when(
                    data: (profile) {
                      final canPost = profile?.role.canPost == true &&
                          profile?.mahallaId != null;
                      if (!canPost) return const SizedBox.shrink();
                      return _AddPollButton(mahallaId: profile!.mahallaId!);
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: pollsAsync.when(
                data: (polls) {
                  if (polls.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.chartBar,
                      title: l10n.noPollsYet,
                      subtitle: l10n.noPollsHint,
                      accent: AppAccents.neighbors,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: polls.length,
                    itemBuilder: (context, index) => StaggeredEntrance(
                      index: index,
                      child: _PollCard(poll: polls[index]),
                    ),
                  );
                },
                loading: () => ListView(
                  padding: AppSpacing.listPadding,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [ShimmerList(count: 4)],
                ),
                error: (error, _) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(mahallaPollsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPollButton extends StatelessWidget {
  final String mahallaId;
  const _AddPollButton({required this.mahallaId});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _NewPollSheet(mahallaId: mahallaId),
      ),
      icon: const Icon(PhosphorIconsFill.plusCircle, color: Colors.white),
    );
  }
}

class _PollCard extends ConsumerWidget {
  final Poll poll;
  const _PollCard({required this.poll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final myVote = poll.myVote(myUid);
    final counts = poll.voteCounts;
    final total = poll.totalVotes;
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final canDelete =
        profile?.role.canPost == true && profile?.mahallaId != null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(poll.question, style: context.cardTitleStyle),
              ),
              if (canDelete)
                PopupMenuButton<void>(
                  icon: Icon(PhosphorIconsBold.dotsThreeVertical,
                      size: 16, color: context.textMuted),
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  tooltip: '',
                  shape: const RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 1));
                        if (!context.mounted) return;
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _NewPollSheet(
                            mahallaId: profile!.mahallaId!,
                            existing: poll,
                          ),
                        );
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
                    PopupMenuItem(
                      onTap: () async {
                        await Future.delayed(const Duration(milliseconds: 1));
                        if (!context.mounted) return;
                        final confirmed = await confirmDelete(
                          context,
                          itemTitle: poll.question,
                        );
                        if (!confirmed || !context.mounted) return;
                        await ref.read(pollRepositoryProvider).deletePoll(
                              mahallaId: profile!.mahallaId!,
                              pollId: poll.id,
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
          const SizedBox(height: AppSpacing.md),
          ...List.generate(poll.options.length, (index) {
            final optionVotes = counts[index];
            final ratio = total == 0 ? 0.0 : optionVotes / total;
            final isMyVote = myVote == index;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                borderRadius: AppRadius.smAll,
                onTap: profile?.mahallaId == null || isMyVote
                    ? null
                    : () async {
                        if (myVote != null) {
                          // Foydalanuvchi allaqachon boshqa variantga
                          // ovoz bergan — ovozni osonlikcha almashtira
                          // olmasligi uchun tasdiqlash so'raladi.
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.pillAll),
                              title: Text(l10n.changeVoteConfirmTitle),
                              content: Text(l10n.changeVoteConfirmMessage),
                              actionsAlignment: MainAxisAlignment.spaceBetween,
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: Text(l10n.cancelButton),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(l10n.changeVoteConfirmButton),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) return;
                        }
                        if (!context.mounted) return;
                        await ref.read(pollRepositoryProvider).vote(
                              mahallaId: profile!.mahallaId!,
                              pollId: poll.id,
                              optionIndex: index,
                            );
                      },
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: AppRadius.smAll,
                      child: Container(
                        height: 40,
                        width: double.infinity,
                        color: context.isDarkMode
                            ? AppColors.darkSurface
                            : AppColors.lightBorder,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: ratio,
                          child: Container(
                            color: (isMyVote
                                    ? AppColors.primary
                                    : AppAccents.neighbors)
                                .withValues(alpha: 0.35),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                        child: Row(
                          children: [
                            if (isMyVote)
                              const Padding(
                                padding: EdgeInsets.only(right: AppSpacing.xs),
                                child: Icon(PhosphorIconsFill.checkCircle,
                                    size: 16, color: AppColors.primary),
                              ),
                            Expanded(
                              child: Text(
                                poll.options[index],
                                overflow: TextOverflow.ellipsis,
                                style: context.bodyStyle.copyWith(
                                  fontWeight: isMyVote
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${(ratio * 100).round()}%',
                              style: context.secondaryStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.pollVotesCount(total), style: context.captionStyle),
        ],
      ),
    );
  }
}

class _NewPollSheet extends ConsumerStatefulWidget {
  final String mahallaId;
  final Poll? existing;
  const _NewPollSheet({required this.mahallaId, this.existing});

  @override
  ConsumerState<_NewPollSheet> createState() => _NewPollSheetState();
}

class _NewPollSheetState extends ConsumerState<_NewPollSheet> {
  late final _questionController =
      TextEditingController(text: widget.existing?.question ?? '');
  late final List<TextEditingController> _optionControllers =
      widget.existing != null
          ? widget.existing!.options
              .map((text) => TextEditingController(text: text))
              .toList()
          : [TextEditingController(), TextEditingController()];
  bool _isSubmitting = false;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final question = _questionController.text.trim();
    final options = _optionControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      showAppAlert(context, l10n.fillPollFields, kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(pollRepositoryProvider);
      if (_isEditing) {
        await repo.updatePoll(
          mahallaId: widget.mahallaId,
          pollId: widget.existing!.id,
          question: question,
          options: options,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        showAppAlert(context, l10n.pollUpdatedMessage);
        return;
      }
      await repo.createPoll(
            mahallaId: widget.mahallaId,
            question: question,
            options: options,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context, l10n.pollPostedMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.lgAll,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEditing ? l10n.editPollTitle : l10n.newPollTitle,
                    style: context.titleStyle),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _questionController,
                  decoration: InputDecoration(hintText: l10n.pollQuestionHint),
                ),
                const SizedBox(height: AppSpacing.md),
                ...List.generate(_optionControllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TextField(
                      controller: _optionControllers[index],
                      decoration: InputDecoration(
                        hintText: l10n.pollOptionHint(index + 1),
                      ),
                    ),
                  );
                }),
                if (_optionControllers.length < 6)
                  TextButton.icon(
                    onPressed: _addOption,
                    icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                    label: Text(l10n.addOptionButton),
                  ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(_isEditing ? l10n.saveButton : l10n.postButton),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
