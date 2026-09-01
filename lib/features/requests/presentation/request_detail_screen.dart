import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/rich_text_editor_field.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../chat/data/chat_providers.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/neighbor_profile_screen.dart';
import '../data/requests_labels.dart';
import '../data/requests_repository.dart';
import 'request_styles.dart';
import '../../../core/widgets/app_alert.dart';

/// Bitta murojaatning to'liq tafsilotlari — sarlavha, tavsif,
/// rasmlar, holat va (ommaviy bo'lsa) qo'shilish tugmasi.
class RequestDetailScreen extends ConsumerWidget {
  final String mahallaId;
  final String requestId;

  const RequestDetailScreen({
    super.key,
    required this.mahallaId,
    required this.requestId,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;

    final requestAsync = ref.watch(requestsRepositoryProvider).watchRequestById(
          mahallaId: mahallaId,
          requestId: requestId,
        );

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<MahallaRequest?>(
          stream: requestAsync,
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
            final request = snapshot.data;
            if (request == null) {
              return Column(
                children: [
                  const _BackHeader(title: ''),
                  Expanded(
                    child: AppErrorView(message: l10n.requestNotFound),
                  ),
                ],
              );
            }

            final myUid = FirebaseAuth.instance.currentUser?.uid;
            final profile = ref.watch(currentUserProfileProvider).valueOrNull;
            final canDelete = profile?.role.canManageRequests == true ||
                request.authorUid == myUid;
            // Xodim/rais/super admin murojaat "maxfiy" bo'lsa ham
            // yuboruvchini bilishi kerak — masalan uyiga borish yoki
            // qo'ng'iroq qilish uchun. Oddiy fuqaro uchun bu ko'rinmaydi.
            final canSeeAuthor = profile?.role.canManageRequests == true ||
                profile?.role.isSuperAdmin == true;
            // Biriktirish/muddat belgilash — holat o'zgartirish bilan
            // bir xil ruxsat darajasi (faqat xodim/rais/super admin).
            final canManage = profile?.role.canManageRequests == true;

            // Muddati o'tgan va biriktirilgan murojaatlar uchun
            // imkoniyat sifatida (fon jarayonisiz) bildirishnoma
            // tekshiruvi — ekran ochilganda bir marta ishga tushadi.
            return _OverdueCheckEffect(
              mahallaId: mahallaId,
              request: request,
              child: Column(
              children: [
                _BackHeader(
                  title: l10n.requestDetailTitle,
                  // Share doim ko'rinadi, o'chirish esa faqat egasi/
                  // xodim-rais uchun — "..." menyu ichida, orqaga
                  // qaytish tugmasi bilan yonma-yon to'g'ridan-to'g'ri
                  // chiqindi ikonkasi bo'lsa, ikkalasini adashtirish
                  // xavfi bor edi (xavfli joy).
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
                              '${request.title}\n\n${request.plainTextDescription}');
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
                      if (canDelete)
                        PopupMenuItem(
                          onTap: () async {
                            await Future.delayed(
                                const Duration(milliseconds: 1));
                            if (!context.mounted) return;
                            final confirmed = await confirmDelete(
                              context,
                              itemTitle: request.title,
                            );
                            if (!confirmed || !context.mounted) return;
                            await ref
                                .read(requestsRepositoryProvider)
                                .deleteRequest(
                                  mahallaId: mahallaId,
                                  requestId: requestId,
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
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.sm, AppSpacing.xl, AppSpacing.xxl),
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 5),
                            decoration: BoxDecoration(
                              color: request.status.badgeBg(isDark),
                              borderRadius: AppRadius.xsAll,
                            ),
                            child: Text(
                              statusLabel(l10n, request.status),
                              style: context.captionStyle
                                  .copyWith(color: request.status.badgeText),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            request.type == RequestType.maxfiy
                                ? PhosphorIconsRegular.lockSimple
                                : PhosphorIconsRegular.globe,
                            size: 15,
                            color: context.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(typeLabel(l10n, request.type),
                              style: context.secondaryStyle),
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: request.priority.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(priorityLabel(l10n, request.priority),
                              style: context.secondaryStyle),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(request.title, style: context.titleStyle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_formatDate(request.createdAt),
                          style: context.secondaryStyle),
                      if (canSeeAuthor) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RequestAuthorCard(authorUid: request.authorUid),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      RichTextViewer(
                        rawContent: request.description,
                        plainStyle: context.bodyStyle.copyWith(height: 1.5),
                      ),

                      if (request.imageUrls.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: request.imageUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final image = ClipRRect(
                                borderRadius: AppRadius.smAll,
                                child: Image.network(
                                  request.imageUrls[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: context.surfaceColor,
                                    );
                                  },
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    height: 100,
                                    color: context.surfaceColor,
                                    child: Icon(PhosphorIconsRegular.imageBroken,
                                        color: context.textSecondary),
                                  ),
                                ),
                              );
                              // Faqat BIRINCHI rasm Hero bilan o'raladi —
                              // ro'yxat kartasidagi thumbnail'dan shu
                              // yerga "uchib" keladi. Boshqa galereya
                              // rasmlarini ham Hero'ga o'rasak, Flutter
                              // noto'g'ri flight animatsiyasi hosil
                              // qiladi (bir nechta Hero bir vaqtda uchib
                              // ketishga urinadi).
                              if (index == 0) {
                                return Hero(
                                  tag: 'request-image-${request.id}-0',
                                  child: image,
                                );
                              }
                              return image;
                            },
                          ),
                        ),
                      ],

                      // Ommaviy murojaatlarga qo'shilish — "men ham shu
                      // muammoni ko'taryapman" degan ma'noda.
                      if (request.type == RequestType.ommaviy) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _JoinSection(
                          mahallaId: mahallaId,
                          request: request,
                        ),
                      ],

                      const SizedBox(height: AppSpacing.xl),
                      _AssignmentAndDueSection(
                        mahallaId: mahallaId,
                        request: request,
                        canManage: canManage,
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      _CommentsSection(
                        mahallaId: mahallaId,
                        requestId: requestId,
                      ),

                      const SizedBox(height: AppSpacing.xl),
                      _SimilarRequestsSection(
                        mahallaId: mahallaId,
                        request: request,
                      ),
                    ],
                  ),
                ),
              ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Murojaat "maxfiy" bo'lsa ham xodim/rais/super admin uchun
/// yuboruvchi kimligini ko'rsatadi — bosilganda to'liq profilga
/// o'tadi (masalan qo'ng'iroq qilish uchun).
class _RequestAuthorCard extends ConsumerWidget {
  final String authorUid;
  const _RequestAuthorCard({required this.authorUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final briefAsync = ref.watch(chatUserBriefProvider(authorUid));

    return briefAsync.when(
      data: (member) {
        final fullName = member == null
            ? l10n.unknownUserLabel
            : '${member.firstName} ${member.lastName}'.trim();
        return AppCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          onTap: member == null
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => NeighborProfileScreen(member: member),
                    ),
                  ),
          child: Row(
            children: [
              UserAvatar(
                size: 36,
                firstName: member?.firstName ?? '',
                lastName: member?.lastName ?? '',
                photoUrl: member?.photoUrl,
                seed: authorUid,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.requestAuthorLabel, style: context.captionStyle),
                    Text(fullName,
                        style: context.cardTitleStyle
                            .copyWith(fontSize: 14)),
                  ],
                ),
              ),
              if (member != null)
                Icon(PhosphorIconsRegular.caretRight,
                    size: 16, color: context.textSecondary),
            ],
          ),
        );
      },
      loading: () => const ShimmerBox(height: 52, borderRadius: AppRadius.mdAll),
      error: (_, __) => const SizedBox.shrink(),
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

class _JoinSection extends ConsumerStatefulWidget {
  final String mahallaId;
  final MahallaRequest request;

  const _JoinSection({
    required this.mahallaId,
    required this.request,
  });

  @override
  ConsumerState<_JoinSection> createState() => _JoinSectionState();
}

class _JoinSectionState extends ConsumerState<_JoinSection> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(requestsRepositoryProvider);

    return AppCard(
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.usersThree,
              size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.joinedCount(widget.request.joinedCount),
              style: context.cardTitleStyle,
            ),
          ),
          TapScale(
            onTap: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    final myUidStr = _currentUid();
                    final alreadyJoined =
                        widget.request.joinedUids.contains(myUidStr);
                    try {
                      if (alreadyJoined) {
                        await repo.leaveRequest(
                          mahallaId: widget.mahallaId,
                          requestId: widget.request.id,
                        );
                      } else {
                        await repo.joinRequest(
                          mahallaId: widget.mahallaId,
                          requestId: widget.request.id,
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            child: Builder(builder: (context) {
              final myUidStr = _currentUid();
              final alreadyJoined =
                  widget.request.joinedUids.contains(myUidStr);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: alreadyJoined ? Colors.transparent : AppColors.primary,
                  border: alreadyJoined
                      ? Border.all(
                          color: context.textSecondary.withValues(alpha: 0.4))
                      : null,
                  borderRadius: AppRadius.smAll,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        alreadyJoined
                            ? l10n.leaveRequestAction
                            : l10n.joinRequestAction,
                        style: context.secondaryStyle.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              alreadyJoined ? context.textSecondary : Colors.white,
                        ),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// UserProfile modeli uid saqlamaydi, shuning uchun joriy
/// foydalanuvchi uid'ini FirebaseAuth orqali to'g'ridan-to'g'ri
/// olamiz.
String? _currentUid() => FirebaseAuth.instance.currentUser?.uid;

/// Ko'rinmas "yon effekt" widget'i — murojaat muddati o'tgan va
/// biriktirilgan bo'lsa, birinchi marta build bo'lganda (ekran
/// ochilganda) bildirishnoma tekshiruvini ishga tushiradi. Alohida
/// fon jarayoni yo'qligi sababli bu eng oddiy to'g'ri yechim: ekran
/// ochilganda bir martalik tekshiruv, `overdueNotifiedAt` maydoni esa
/// qayta yuborilishning oldini oladi.
class _OverdueCheckEffect extends ConsumerStatefulWidget {
  final String mahallaId;
  final MahallaRequest request;
  final Widget child;

  const _OverdueCheckEffect({
    required this.mahallaId,
    required this.request,
    required this.child,
  });

  @override
  ConsumerState<_OverdueCheckEffect> createState() =>
      _OverdueCheckEffectState();
}

class _OverdueCheckEffectState extends ConsumerState<_OverdueCheckEffect> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _maybeCheck();
  }

  @override
  void didUpdateWidget(covariant _OverdueCheckEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) _checked = false;
    _maybeCheck();
  }

  void _maybeCheck() {
    if (_checked) return;
    _checked = true;
    ref
        .read(requestsRepositoryProvider)
        .checkAndNotifyOverdue(widget.mahallaId, widget.request);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Murojaatga biriktirilgan xodim va bajarish muddatini (SLA)
/// ko'rsatadi; [canManage] bo'lsa, ularni belgilash/o'zgartirish
/// tugmalari ham chiqadi.
class _AssignmentAndDueSection extends ConsumerWidget {
  final String mahallaId;
  final MahallaRequest request;
  final bool canManage;

  const _AssignmentAndDueSection({
    required this.mahallaId,
    required this.request,
    required this.canManage,
  });

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }

  Future<void> _openAssignSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final staffAsync = ref.read(staffMembersProvider(mahallaId));
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
                child:
                    Text(l10n.assignStaffTitle, style: sheetContext.sectionStyle),
              ),
              staffAsync.when(
                data: (members) {
                  if (members.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(l10n.noStaffFoundLabel,
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
                          title: Text(l10n.cancelAssignmentAction),
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

    if (result == null) return;
    if (!context.mounted) return;
    try {
      await ref.read(requestsRepositoryProvider).assignRequest(
            mahallaId: mahallaId,
            requestId: request.id,
            staffUid: result.isEmpty ? null : result,
          );
      if (!context.mounted) return;
      showAppAlert(context, AppLocalizations.of(context).requestAssignedMessage);
    } catch (_) {
      if (!context.mounted) return;
      showAppAlert(context, AppLocalizations.of(context).statusChangeError,
          kind: AppAlertKind.error);
    }
  }

  Future<void> _pickDueDate(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: request.dueAt ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    try {
      await ref.read(requestsRepositoryProvider).setRequestDueDate(
            mahallaId: mahallaId,
            requestId: request.id,
            dueAt: picked,
          );
      if (!context.mounted) return;
      showAppAlert(context, AppLocalizations.of(context).dueDateSetMessage);
    } catch (_) {
      if (!context.mounted) return;
      showAppAlert(context, AppLocalizations.of(context).statusChangeError,
          kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (request.assignedToUid == null && request.dueAt == null && !canManage) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (request.assignedToUid != null)
            Consumer(builder: (context, ref, _) {
              final assigneeAsync =
                  ref.watch(chatUserBriefProvider(request.assignedToUid!));
              return assigneeAsync.when(
                data: (member) {
                  final fullName = member == null
                      ? AppLocalizations.of(context).unknownUserLabel
                      : '${member.firstName} ${member.lastName}'.trim();
                  return Row(
                    children: [
                      Icon(PhosphorIconsRegular.userSwitch,
                          size: 16, color: context.textSecondary),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(l10n.assignedToLabel(fullName),
                            style: context.secondaryStyle),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                    height: 18, child: ShimmerBox(height: 18, width: 120)),
                error: (_, __) => const SizedBox.shrink(),
              );
            }),
          if (request.dueAt != null) ...[
            if (request.assignedToUid != null)
              const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(PhosphorIconsRegular.clockCountdown,
                    size: 16,
                    color:
                        request.isOverdue ? AppColors.danger : context.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${l10n.dueDateLabel(_formatDate(request.dueAt!))}'
                    '${request.isOverdue ? l10n.dueDateOverdueSuffix : ''}',
                    style: context.secondaryStyle.copyWith(
                      color: request.isOverdue
                          ? AppColors.danger
                          : context.textSecondary,
                      fontWeight:
                          request.isOverdue ? FontWeight.w600 : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (canManage) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TapScale(
                    onTap: () => _openAssignSheet(context, ref),
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: context.textSecondary.withValues(alpha: 0.3)),
                        borderRadius: AppRadius.xsAll,
                      ),
                      child:
                          Text(l10n.assignAction, style: context.captionStyle),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TapScale(
                    onTap: () => _pickDueDate(context, ref),
                    child: Container(
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: context.textSecondary.withValues(alpha: 0.3)),
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
        ],
      ),
    );
  }
}

/// Murojaat ostidagi izohlar bo'limi — oddiy ro'yxat + pastda yozish
/// maydoni (chat pufakchasi naqshidan farqli, chunki bu yerda "mening
/// tomonim" tushunchasi kam ahamiyatga ega — asosiysi kim va qachon
/// yozgani).
class _CommentsSection extends ConsumerStatefulWidget {
  final String mahallaId;
  final String requestId;

  const _CommentsSection({required this.mahallaId, required this.requestId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    try {
      await ref.read(requestsRepositoryProvider).addComment(
            mahallaId: widget.mahallaId,
            requestId: widget.requestId,
            text: text,
          );
      _controller.clear();
    } catch (_) {
      if (mounted) {
        showAppAlert(context, AppLocalizations.of(context).unexpectedError,
            kind: AppAlertKind.error);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatTime(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final commentsAsync = ref.watch(
        requestCommentsProvider('${widget.mahallaId}:${widget.requestId}'));
    final myUid = _currentUid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.commentsTitle, style: context.sectionStyle),
        const SizedBox(height: AppSpacing.sm),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(l10n.noCommentsYet,
                    style: context.secondaryStyle),
              );
            }
            return Column(
              children: comments.map((comment) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _CommentBubble(
                    mahallaId: widget.mahallaId,
                    requestId: widget.requestId,
                    comment: comment,
                    isMine: comment.authorUid == myUid,
                    formattedTime: _formatTime(comment.createdAt),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: ShimmerListTile(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkSurface
                      : AppColors.lightBorder,
                  borderRadius: AppRadius.pillAll,
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: l10n.commentHint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  style: context.bodyStyle,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _isSending ? null : _send,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(PhosphorIconsFill.paperPlaneRight,
                          size: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentBubble extends ConsumerWidget {
  final String mahallaId;
  final String requestId;
  final RequestComment comment;
  final bool isMine;
  final String formattedTime;

  const _CommentBubble({
    required this.mahallaId,
    required this.requestId,
    required this.comment,
    required this.isMine,
    required this.formattedTime,
  });

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmDelete(context, itemTitle: comment.text);
    if (!confirmed || !context.mounted) return;
    await ref.read(requestsRepositoryProvider).deleteComment(
          mahallaId: mahallaId,
          requestId: requestId,
          commentId: comment.id,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authorAsync = ref.watch(chatUserBriefProvider(comment.authorUid));

    return GestureDetector(
      // Uzoq bosish orqali ham o'chirish mumkin — trailing ikonka
      // qo'shimcha imkoniyat, ikkalasi bir xil natijaga olib keladi.
      onLongPress: !isMine ? null : () => _confirmAndDelete(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.primary.withValues(alpha: 0.1)
              : (context.isDarkMode
                  ? AppColors.darkSurface
                  : AppColors.lightBorder),
          borderRadius: AppRadius.smAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                authorAsync.when(
                  data: (member) {
                    final fullName = member == null
                        ? AppLocalizations.of(context).unknownUserLabel
                        : '${member.firstName} ${member.lastName}'.trim();
                    return Expanded(
                      child: Text(
                        fullName,
                        style: context.captionStyle
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                      height: 14, child: ShimmerBox(height: 14, width: 80)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                Text(formattedTime, style: context.captionStyle),
                // Faqat o'zining komentariyasi bo'lsa ko'rinadi.
                if (isMine) ...[
                  const SizedBox(width: AppSpacing.xxs),
                  TapScale(
                    onTap: () => _confirmAndDelete(context, ref),
                    child: Icon(PhosphorIconsRegular.trash,
                        size: 14, color: context.textSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(comment.text, style: context.bodyStyle),
          ],
        ),
      ),
    );
  }
}

/// Joriy murojaatga o'xshash — bir xil mahalla va turdagi (`type`)
/// boshqa murojaatlar ro'yxati. Bosilganda xuddi shu
/// [RequestDetailScreen]ni rekursiv ravishda ochadi.
class _SimilarRequestsSection extends ConsumerWidget {
  final String mahallaId;
  final MahallaRequest request;

  const _SimilarRequestsSection({
    required this.mahallaId,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final similarAsync = ref.watch(similarRequestsProvider(
        '$mahallaId:${request.id}:${request.type.firestoreValue}'));

    return similarAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.similarRequestsTitle, style: context.sectionStyle),
            const SizedBox(height: AppSpacing.sm),
            ...items.map((other) {
              return AppListCard(
                icon: other.type == RequestType.maxfiy
                    ? PhosphorIconsRegular.lockSimple
                    : PhosphorIconsRegular.globe,
                accent: other.status.badgeText,
                title: other.title,
                subtitle: other.plainTextDescription.isEmpty
                    ? null
                    : other.plainTextDescription,
                onTap: () => AppPageRoute.push(
                  context,
                  RequestDetailScreen(
                    mahallaId: mahallaId,
                    requestId: other.id,
                  ),
                ),
              );
            }),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: ShimmerListTile(),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
