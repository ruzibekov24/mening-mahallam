import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../data/notification_repository.dart';

extension on NotificationType {
  IconData get icon {
    switch (this) {
      case NotificationType.requestStatusChanged:
        return PhosphorIconsFill.chatCircleDots;
      case NotificationType.newAnnouncement:
        return PhosphorIconsFill.megaphone;
      case NotificationType.newEvent:
        return PhosphorIconsFill.calendarCheck;
      case NotificationType.newPoll:
        return PhosphorIconsFill.chartBar;
      case NotificationType.newMessage:
        return PhosphorIconsFill.chatDots;
      case NotificationType.premiumPaymentSubmitted:
      case NotificationType.premiumApproved:
      case NotificationType.premiumRejected:
        return PhosphorIconsFill.crown;
      case NotificationType.accountDeletionRequested:
        return PhosphorIconsFill.userMinus;
    }
  }

  Color get color {
    switch (this) {
      case NotificationType.requestStatusChanged:
        return AppAccents.requests;
      case NotificationType.newAnnouncement:
        return AppAccents.announcements;
      case NotificationType.newEvent:
        return AppAccents.events;
      case NotificationType.newPoll:
        return AppAccents.neighbors;
      case NotificationType.newMessage:
        return AppColors.primary;
      case NotificationType.premiumPaymentSubmitted:
      case NotificationType.premiumApproved:
      case NotificationType.premiumRejected:
        return const Color(0xFFE0A526);
      case NotificationType.accountDeletionRequested:
        return AppColors.danger;
    }
  }
}

/// Bildirishnomalar ro'yxati — o'qilmaganlar ajratib ko'rsatiladi,
/// bosilganda o'qilgan deb belgilanadi.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notificationsAsync = ref.watch(myNotificationsProvider);

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
                    child: Text(l10n.notificationsMenuItem,
                        style: context.titleStyle),
                  ),
                  notificationsAsync.maybeWhen(
                    data: (items) => items.any((n) => !n.isRead)
                        ? TextButton(
                            onPressed: () => ref
                                .read(notificationRepositoryProvider)
                                .markAllAsRead(),
                            child: Text(l10n.markAllAsReadAction),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(myNotificationsProvider),
                child: notificationsAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return AppEmptyView(
                        icon: PhosphorIconsFill.bellSlash,
                        title: l10n.noNotificationsYet,
                        subtitle: l10n.noNotificationsHint,
                        scrollable: true,
                      );
                    }
                    return ListView.builder(
                      padding: AppSpacing.listPadding,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final notification = items[index];
                        return StaggeredEntrance(
                          index: index,
                          child: _NotificationTile(notification: notification),
                        );
                      },
                    );
                  },
                  loading: () => ListView(
                    padding: AppSpacing.listPadding,
                    physics: const NeverScrollableScrollPhysics(),
                    children: const [ShimmerList(count: 6)],
                  ),
                  error: (error, _) => AppErrorView.fromError(
                    error,
                    onRetry: () => ref.invalidate(myNotificationsProvider),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = notification.type.color;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      borderColor: notification.isRead ? null : AppColors.primary,
      onTap: notification.isRead
          ? null
          : () => ref
              .read(notificationRepositoryProvider)
              .markAsRead(notification.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(notification.type.icon, size: 18, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: context.cardTitleStyle),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  notification.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.secondaryStyle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _timeAgo(l10n, notification.createdAt),
                  style: context.captionStyle,
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  String _timeAgo(AppLocalizations l10n, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.lastSeenJustNow;
    if (diff.inMinutes < 60) return l10n.lastSeenMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.lastSeenHoursAgo(diff.inHours);
    return l10n.lastSeenDaysAgo(diff.inDays);
  }
}
