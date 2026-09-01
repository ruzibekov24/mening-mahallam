import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/announcements_providers.dart';
import '../data/event_repository.dart';
import 'new_event_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// Bitta tadbirning to'liq tafsilotlari — sarlavha, sana/vaqt,
/// joylashuv, ishtirokchilar, to'liq tavsif. `request_detail_screen.dart`
/// bilan bir xil naqsh.
class EventDetailScreen extends ConsumerWidget {
  final String mahallaId;
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.mahallaId,
    required this.eventId,
  });

  String _formatDateTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return l10n.todayAt(time);
    return '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year} • $time';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final eventAsync = ref.watch(eventRepositoryProvider).watchEventById(
          mahallaId: mahallaId,
          eventId: eventId,
        );

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<MahallaEvent?>(
          stream: eventAsync,
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
            final event = snapshot.data;
            if (event == null) {
              return Column(
                children: [
                  const _BackHeader(title: ''),
                  Expanded(child: AppErrorView(message: l10n.eventNotFound)),
                ],
              );
            }

            final profile = ref.watch(currentUserProfileProvider).valueOrNull;
            final canManage =
                profile?.role.canPost == true && profile?.mahallaId != null;
            final gradient = AppAccents.bannerGradients[
                event.id.hashCode.abs() % AppAccents.bannerGradients.length];

            return Column(
              children: [
                _BackHeader(
                  title: l10n.eventDetailTitle,
                  trailing: PopupMenuButton<void>(
                    icon: const Icon(PhosphorIconsBold.dotsThreeVertical),
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () async {
                          await Future.delayed(const Duration(milliseconds: 1));
                          if (!context.mounted) return;
                          Share.share(
                            '${event.title}\n${_formatDateTime(context, event.dateTime)}'
                            '${event.location.isNotEmpty ? '\n${event.location}' : ''}',
                          );
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
                                builder: (_) => NewEventScreen(
                                  mahallaId: mahallaId,
                                  existing: event,
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
                              itemTitle: event.title,
                            );
                            if (!confirmed || !context.mounted) return;
                            await ref.read(eventRepositoryProvider).deleteEvent(
                                  mahallaId: mahallaId,
                                  eventId: eventId,
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
                      Hero(
                        tag: 'event-banner-${event.id}',
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          padding: AppSpacing.card,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: gradient,
                            ),
                          ),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            event.title,
                            style: context.titleStyle.copyWith(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                            AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(PhosphorIconsRegular.calendar,
                                    size: 16, color: context.textSecondary),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _formatDateTime(context, event.dateTime),
                                  style: context.secondaryStyle,
                                ),
                              ],
                            ),
                            if (event.location.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(PhosphorIconsRegular.mapPin,
                                      size: 16, color: context.textSecondary),
                                  const SizedBox(width: AppSpacing.xs),
                                  Expanded(
                                    child: Text(event.location,
                                        style: context.secondaryStyle),
                                  ),
                                ],
                              ),
                            ],
                            if (event.participantsCount > 0) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  Icon(PhosphorIconsFill.usersThree,
                                      size: 16, color: gradient.last),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    l10n.participantsCount(
                                        event.participantsCount),
                                    style: context.secondaryStyle.copyWith(
                                      color: gradient.last,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (event.description.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                event.description,
                                style: context.bodyStyle.copyWith(height: 1.5),
                              ),
                            ],
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
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(PhosphorIconsRegular.arrowLeft),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(title, style: context.titleStyle)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
