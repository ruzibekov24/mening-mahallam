import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/announcements_providers.dart';
import '../data/event_repository.dart';
import 'new_event_screen.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

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
                            const SizedBox(height: AppSpacing.sm),
                            _RemindMeButton(event: event),
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
                            // Qatnashish belgisi — faqat rais shu
                            // tadbirda yoqqan bo'lsa ko'rinadi
                            // (`new_event_screen.dart`dagi svitch).
                            // O'chirilgan tadbirlarda hech narsa
                            // ko'rsatilmaydi — bo'sh "0 qatnashuvchi"
                            // yozuvi bilan foydalanuvchini
                            // chalg'itmaslik uchun.
                            if (event.rsvpEnabled) ...[
                              const SizedBox(height: AppSpacing.sm),
                              _RsvpButton(
                                mahallaId: mahallaId,
                                event: event,
                                accent: gradient.last,
                              ),
                            ] else if (event.participantsCount > 0) ...[
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

/// Tadbir boshlanishidan 1 soat oldin mahalliy bildirishnoma
/// rejalashtirish/bekor qilish tugmasi. Holat (yoqilgan/o'chirilgan)
/// qurilmada `shared_preferences`da saqlanadi — bu faqat mahalliy
/// eslatma, serverga yozilmaydi (har bir qurilma o'zi boshqaradi).
class _RemindMeButton extends StatefulWidget {
  final MahallaEvent event;
  const _RemindMeButton({required this.event});

  @override
  State<_RemindMeButton> createState() => _RemindMeButtonState();
}

class _RemindMeButtonState extends State<_RemindMeButton> {
  bool? _isSet;

  String get _prefsKey => 'event_reminder_${widget.event.id}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _isSet = prefs.getBool(_prefsKey) ?? false);
  }

  Future<void> _toggle() async {
    final l10n = AppLocalizations.of(context);
    final prefs = await SharedPreferences.getInstance();
    final next = !(_isSet ?? false);
    if (next) {
      await PushNotificationService.instance.scheduleEventReminder(
        eventId: widget.event.id,
        title: l10n.eventReminderNotificationTitle,
        body: widget.event.title,
        eventDateTime: widget.event.dateTime,
      );
    } else {
      await PushNotificationService.instance
          .cancelEventReminder(widget.event.id);
    }
    await prefs.setBool(_prefsKey, next);
    if (!mounted) return;
    setState(() => _isSet = next);
    showAppAlert(
      context,
      next ? l10n.reminderSetMessage : l10n.reminderCancelledMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isSet = _isSet ?? false;
    return TapScale(
      onTap: _isSet == null ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: 6),
        decoration: BoxDecoration(
          color: isSet ? AppColors.primary.withValues(alpha: 0.1) : null,
          border: isSet
              ? null
              : Border.all(color: context.textSecondary.withValues(alpha: 0.3)),
          borderRadius: AppRadius.xsAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSet ? PhosphorIconsFill.bellRinging : PhosphorIconsRegular.bell,
              size: 15,
              color: isSet ? AppColors.primary : context.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.remindMeAction,
              style: context.captionStyle.copyWith(
                color: isSet ? AppColors.primary : context.textSecondary,
                fontWeight: isSet ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Boraman" tugmasi — faqat `event.rsvpEnabled == true` bo'lganda
/// ko'rinadi (`event_detail_screen.dart` yuqorisiga qarang). Bosilganda
/// joriy foydalanuvchini qatnashuvchilar ro'yxatiga qo'shadi/olib
/// tashlaydi va hisoblagichni ko'rsatadi — `_RemindMeButton` bilan bir
/// xil vizual uslubda, lekin serverga yoziladi (mahalliy eslatma emas,
/// boshqa a'zolar ham ko'radi).
class _RsvpButton extends ConsumerWidget {
  final String mahallaId;
  final MahallaEvent event;
  final Color accent;

  const _RsvpButton({
    required this.mahallaId,
    required this.event,
    required this.accent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final isAttending = myUid != null && event.isAttendingBy(myUid);

    return Row(
      children: [
        TapScale(
          onTap: myUid == null
              ? null
              : () {
                  final repo = ref.read(eventRepositoryProvider);
                  if (isAttending) {
                    repo.leaveEvent(mahallaId: mahallaId, eventId: event.id);
                  } else {
                    repo.joinEvent(mahallaId: mahallaId, eventId: event.id);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: isAttending ? accent : null,
              border: isAttending ? null : Border.all(color: accent),
              borderRadius: AppRadius.xsAll,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isAttending
                      ? PhosphorIconsFill.checkCircle
                      : PhosphorIconsRegular.plusCircle,
                  size: 15,
                  color: isAttending ? Colors.white : accent,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  isAttending ? l10n.rsvpJoinedLabel : l10n.rsvpJoinAction,
                  style: context.captionStyle.copyWith(
                    color: isAttending ? Colors.white : accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (event.participantsCount > 0) ...[
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.participantsCount(event.participantsCount),
            style: context.secondaryStyle,
          ),
        ],
      ],
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
