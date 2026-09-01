import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/rich_text_editor_field.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/announcement_repository.dart';
import '../data/announcements_providers.dart';
import 'announcement_styles.dart';
import 'announcement_widgets.dart';
import 'new_announcement_screen.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// Bitta e'lonning to'liq tafsilotlari — sarlavha, to'liq matn, rasm,
/// reaksiyalar. `request_detail_screen.dart` bilan bir xil naqsh.
class AnnouncementDetailScreen extends ConsumerWidget {
  final String mahallaId;
  final String announcementId;

  const AnnouncementDetailScreen({
    super.key,
    required this.mahallaId,
    required this.announcementId,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final announcementAsync =
        ref.watch(announcementRepositoryProvider).watchAnnouncementById(
              mahallaId: mahallaId,
              announcementId: announcementId,
            );

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<Announcement?>(
          stream: announcementAsync,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Column(
                children: [
                  const _BackHeader(title: ''),
                  Expanded(
                    child: ListView(
                      padding: AppSpacing.listPadding,
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [ShimmerListTile(), ShimmerListTile()],
                    ),
                  ),
                ],
              );
            }
            final announcement = snapshot.data;
            if (announcement == null) {
              return Column(
                children: [
                  const _BackHeader(title: ''),
                  Expanded(
                    child: AppErrorView(message: l10n.announcementNotFound),
                  ),
                ],
              );
            }

            final profile = ref.watch(currentUserProfileProvider).valueOrNull;
            final canManage =
                profile?.role.canPost == true && profile?.mahallaId != null;
            final color = announcement.category.color;

            return Column(
              children: [
                _BackHeader(
                  title: l10n.announcementDetailTitle,
                  trailing: PopupMenuButton<void>(
                    icon: const Icon(PhosphorIconsBold.dotsThreeVertical),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 1));
                          if (!context.mounted) return;
                          Share.share('${announcement.title}\n\n'
                              '${announcement.plainTextPreview}');
                        },
                        child: Row(
                          children: [
                            Icon(PhosphorIconsRegular.shareNetwork,
                                size: 18, color: context.textSecondary),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.shareAction, style: context.bodyStyle),
                          ],
                        ),
                      ),
                      if (canManage) ...[
                        PopupMenuItem(
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 1));
                            if (!context.mounted) return;
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => NewAnnouncementScreen(
                                  mahallaId: mahallaId,
                                  existing: announcement,
                                ),
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
                            await Future.delayed(
                                const Duration(milliseconds: 1));
                            if (!context.mounted) return;
                            final confirmed = await confirmDelete(
                              context,
                              itemTitle: announcement.title,
                            );
                            if (!confirmed || !context.mounted) return;
                            await ref
                                .read(announcementRepositoryProvider)
                                .deleteAnnouncement(
                                  mahallaId: mahallaId,
                                  announcementId: announcementId,
                                );
                            if (context.mounted) {
                              showAppAlert(context, l10n.itemDeletedMessage);
                              Navigator.of(context).pop();
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
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (announcement.imageUrl != null &&
                          announcement.imageUrl!.isNotEmpty)
                        Hero(
                          tag: 'announcement-image-${announcement.id}',
                          child: CachedNetworkImage(
                            imageUrl: announcement.imageUrl!,
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 220,
                              color: color.withValues(alpha: 0.08),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 220,
                              color: color.withValues(alpha: 0.08),
                              child: Icon(PhosphorIconsRegular.imageBroken,
                                  color: color.withValues(alpha: 0.4)),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                            AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.14),
                                borderRadius: AppRadius.xsAll,
                              ),
                              child: Text(
                                categoryLabel(l10n, announcement.category),
                                style:
                                    context.captionStyle.copyWith(color: color),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(announcement.title, style: context.titleStyle),
                            const SizedBox(height: AppSpacing.xs),
                            Text(_formatDate(announcement.createdAt),
                                style: context.secondaryStyle),
                            const SizedBox(height: AppSpacing.lg),
                            RichTextViewer(
                              rawContent: announcement.body,
                              plainStyle:
                                  context.bodyStyle.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ReactionRow(announcement: announcement),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _BackHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
      child: Row(
        children: [
          const LiquidGlassBackButton(),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(title, style: context.titleStyle)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
