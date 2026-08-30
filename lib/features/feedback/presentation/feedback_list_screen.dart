import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../data/feedback_repository.dart';

/// Super admin uchun: foydalanuvchilar qoldirgan barcha fikrlar
/// (yulduz baho + matn), eng yangisidan.
class FeedbackListScreen extends ConsumerWidget {
  const FeedbackListScreen({super.key});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedbackAsync = ref.watch(allFeedbackProvider);

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
                  Text(l10n.feedbackListTitle, style: context.titleStyle),
                ],
              ),
            ),
            Expanded(
              child: feedbackAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.star,
                      title: l10n.noFeedbackFound,
                      accent: AppAccents.events,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      i < item.rating
                                          ? PhosphorIconsFill.star
                                          : PhosphorIconsRegular.star,
                                      size: 16,
                                      color: i < item.rating
                                          ? AppAccents.events
                                          : context.textMuted,
                                    );
                                  }),
                                ),
                                const Spacer(),
                                Text(_formatDate(item.createdAt),
                                    style: context.captionStyle),
                              ],
                            ),
                            if (item.message.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(item.message,
                                  style: context.bodyStyle.copyWith(height: 1.4)),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              item.authorName.isEmpty
                                  ? l10n.unknownUserLabel
                                  : item.authorName,
                              style: context.captionStyle
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => ListView(
                  padding: AppSpacing.listPadding,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [ShimmerList(count: 5)],
                ),
                error: (error, _) => AppErrorView.fromError(
                  error,
                  onRetry: () => ref.invalidate(allFeedbackProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
