import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_providers.dart';
import '../../home/data/home_repository.dart';
import '../data/requests_labels.dart';
import '../data/requests_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// Xodim/rais uchun Boshqaruv paneli — mahalladagi barcha (maxfiy +
/// ommaviy) murojaatlarni ko'rish va holatini o'zgartirish imkoniyati.
class RequestsManagementScreen extends ConsumerStatefulWidget {
  final String mahallaId;
  const RequestsManagementScreen({super.key, required this.mahallaId});

  @override
  ConsumerState<RequestsManagementScreen> createState() =>
      _RequestsManagementScreenState();
}

class _RequestsManagementScreenState
    extends ConsumerState<RequestsManagementScreen> {
  RequestStatus? _filterStatus;

  Future<void> _openStatusSheet(MahallaRequest request) async {
    final l10n = AppLocalizations.of(context);
    final newStatus = await showModalBottomSheet<RequestStatus>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
                child: Text(l10n.changeStatusTitle, style: context.sectionStyle),
              ),
              ...RequestStatus.values.map((status) {
                return ListTile(
                  title: Text(statusLabel(l10n, status)),
                  trailing: request.status == status
                      ? const Icon(PhosphorIconsFill.checkCircle,
                          color: AppColors.primary)
                      : null,
                  onTap: () => Navigator.of(sheetContext).pop(status),
                );
              }),
            ],
          ),
        );
      },
    );

    if (newStatus == null || newStatus == request.status) return;

    try {
      await ref.read(requestsRepositoryProvider).updateRequestStatus(
            mahallaId: widget.mahallaId,
            requestId: request.id,
            newStatus: newStatus,
            authorUid: request.authorUid,
            requestTitle: request.title,
          );
      if (!mounted) return;
      showAppAlert(context, l10n.statusChangedMessage(statusLabel(l10n, newStatus)));
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.statusChangeError, kind: AppAlertKind.error);
    }
  }

  /// Murojaatni mahalla xodimlaridan biriga biriktirish uchun tanlov
  /// varag'i — `staffMembersProvider` orqali (Home ekranidagi bilan
  /// bir xil manba) mahalla xodimlari/raisi ro'yxatini ko'rsatadi.
  Future<void> _openAssignSheet(MahallaRequest request) async {
    final staffAsync = ref.read(staffMembersProvider(widget.mahallaId));
    final result = await showModalBottomSheet<String?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
                child: Text(AppLocalizations.of(context).assignStaffTitle,
                    style: sheetContext.sectionStyle),
              ),
              staffAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(AppLocalizations.of(context).noStaffFoundLabel,
                          style: sheetContext.secondaryStyle),
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request.assignedToUid != null)
                        ListTile(
                          leading: const Icon(PhosphorIconsRegular.xCircle,
                              color: AppColors.danger),
                          title: Text(
                              AppLocalizations.of(context).cancelAssignmentAction),
                          onTap: () => Navigator.of(sheetContext).pop(''),
                        ),
                      ...members.map((member) {
                        final fullName =
                            '${member.firstName} ${member.lastName}'.trim();
                        return ListTile(
                          leading: UserAvatar(
                            size: 32,
                            firstName: member.firstName,
                            lastName: member.lastName,
                            photoUrl: member.photoUrl,
                            seed: member.uid,
                          ),
                          title: Text(fullName),
                          subtitle: Text(member.role.label),
                          trailing: request.assignedToUid == member.uid
                              ? const Icon(PhosphorIconsFill.checkCircle,
                                  color: AppColors.primary)
                              : null,
                          onTap: () => Navigator.of(sheetContext).pop(member.uid),
                        );
                      }),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );

    // `null` — sheet yopildi (hech narsa tanlanmadi). `''` — biriktirishni
    // bekor qilish tanlandi (staffUid `null`ga o'rnatiladi).
    if (result == null) return;
    try {
      await ref.read(requestsRepositoryProvider).assignRequest(
            mahallaId: widget.mahallaId,
            requestId: request.id,
            staffUid: result.isEmpty ? null : result,
          );
      if (!mounted) return;
      showAppAlert(context, AppLocalizations.of(context).requestAssignedMessage);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, AppLocalizations.of(context).statusChangeError,
          kind: AppAlertKind.error);
    }
  }

  /// Murojaatning bajarish muddatini (SLA) belgilash uchun sana tanlash.
  Future<void> _pickDueDate(MahallaRequest request) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: request.dueAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    try {
      await ref.read(requestsRepositoryProvider).setRequestDueDate(
            mahallaId: widget.mahallaId,
            requestId: request.id,
            dueAt: picked,
          );
      if (!mounted) return;
      showAppAlert(context, AppLocalizations.of(context).dueDateSetMessage);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, AppLocalizations.of(context).statusChangeError,
          kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(allRequestsForManagementProvider);

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
                  Text(l10n.managementPanelTitle, style: context.titleStyle),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Holat bo'yicha filtr chip'lari
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                children: [
                  AppFilterChip(
                    label: l10n.allFilter,
                    isActive: _filterStatus == null,
                    onTap: () => setState(() => _filterStatus = null),
                  ),
                  ...RequestStatus.values.map((status) {
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: AppFilterChip(
                        label: statusLabel(l10n, status),
                        isActive: _filterStatus == status,
                        onTap: () => setState(() => _filterStatus = status),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(allRequestsForManagementProvider),
                child: requestsAsync.when(
                  data: (requests) {
                    final filtered = _filterStatus == null
                        ? requests
                        : requests
                            .where((r) => r.status == _filterStatus)
                            .toList();

                    if (filtered.isEmpty) {
                      return AppEmptyView(
                        icon: PhosphorIconsFill.tray,
                        title: l10n.noRequestsFound,
                        accent: AppAccents.requests,
                        scrollable: true,
                      );
                    }

                    return ListView.builder(
                      padding: AppSpacing.listPadding,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final request = filtered[index];
                        return _ManagementRequestCard(
                          request: request,
                          onTap: () => _openStatusSheet(request),
                          onAssign: () => _openAssignSheet(request),
                          onSetDueDate: () => _pickDueDate(request),
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
                    onRetry: () =>
                        ref.invalidate(allRequestsForManagementProvider),
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

extension on RequestStatus {
  Color get manageColor {
    switch (this) {
      case RequestStatus.yangi:
        return const Color(0xFFE65100);
      case RequestStatus.jarayonda:
        return const Color(0xFF1565C0);
      case RequestStatus.yakunlandi:
        return const Color(0xFF2E7D32);
    }
  }
}

extension on RequestPriority {
  Color get manageColor {
    switch (this) {
      case RequestPriority.past:
        return AppAccents.requests;
      case RequestPriority.ortacha:
        return AppAccents.events;
      case RequestPriority.yuqori:
        return AppColors.danger;
    }
  }
}

class _ManagementRequestCard extends ConsumerWidget {
  final MahallaRequest request;
  final VoidCallback onTap;
  final VoidCallback onAssign;
  final VoidCallback onSetDueDate;

  const _ManagementRequestCard({
    required this.request,
    required this.onTap,
    required this.onAssign,
    required this.onSetDueDate,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final authorAsync = ref.watch(chatUserBriefProvider(request.authorUid));
    final statusColor = request.status.manageColor;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      radius: AppRadius.sm,
      padding: EdgeInsets.zero,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: statusColor, width: 3)),
        ),
        child: Padding(
          padding: AppSpacing.card,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.14),
                          borderRadius: AppRadius.xsAll,
                        ),
                        child: Text(
                          statusLabel(l10n, request.status),
                          style: context.captionStyle.copyWith(color: statusColor),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        request.type == RequestType.maxfiy
                            ? PhosphorIconsRegular.lockSimple
                            : PhosphorIconsRegular.globe,
                        size: 13,
                        color: context.textSecondary,
                      ),
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(left: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: request.priority.manageColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  Text(_formatDate(request.createdAt), style: context.captionStyle),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(request.title, style: context.cardTitleStyle),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  request.plainTextDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.secondaryStyle,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              authorAsync.when(
                data: (member) {
                  final fullName = member == null
                      ? l10n.unknownUserLabel
                      : '${member.firstName} ${member.lastName}'.trim();
                  return Row(
                    children: [
                      UserAvatar(
                        size: 20,
                        firstName: member?.firstName ?? '',
                        lastName: member?.lastName ?? '',
                        photoUrl: member?.photoUrl,
                        seed: request.authorUid,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(fullName, style: context.captionStyle),
                    ],
                  );
                },
                loading: () => const SizedBox(
                    height: 20, child: ShimmerBox(height: 20, width: 100)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              if (request.assignedToUid != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Consumer(builder: (context, ref, _) {
                  final assigneeAsync = ref.watch(
                      chatUserBriefProvider(request.assignedToUid!));
                  return assigneeAsync.when(
                    data: (member) {
                      final fullName = member == null
                          ? l10n.unknownUserLabel
                          : '${member.firstName} ${member.lastName}'.trim();
                      return Row(
                        children: [
                          Icon(PhosphorIconsRegular.userSwitch,
                              size: 13, color: context.textSecondary),
                          const SizedBox(width: AppSpacing.xs),
                          Text(l10n.assignedToLabel(fullName),
                              style: context.captionStyle),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                }),
              ],
              if (request.dueAt != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(PhosphorIconsRegular.clockCountdown,
                        size: 13,
                        color: request.isOverdue
                            ? AppColors.danger
                            : context.textSecondary),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${l10n.dueDateLabel(_formatDate(request.dueAt!))}'
                      '${request.isOverdue ? l10n.dueDateOverdueSuffix : ''}',
                      style: context.captionStyle.copyWith(
                        color: request.isOverdue
                            ? AppColors.danger
                            : context.textSecondary,
                        fontWeight:
                            request.isOverdue ? FontWeight.w600 : null,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(PhosphorIconsRegular.handTap,
                      size: 13, color: context.textSecondary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(l10n.tapToChangeStatus, style: context.captionStyle),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TapScale(
                      onTap: onAssign,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  context.textSecondary.withValues(alpha: 0.3)),
                          borderRadius: AppRadius.xsAll,
                        ),
                        child: Text(l10n.assignAction, style: context.captionStyle),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TapScale(
                      onTap: onSetDueDate,
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color:
                                  context.textSecondary.withValues(alpha: 0.3)),
                          borderRadius: AppRadius.xsAll,
                        ),
                        child: Text(l10n.setDueDateAction,
                            style: context.captionStyle),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
