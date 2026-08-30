import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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

            return Column(
              children: [
                _BackHeader(
                  title: l10n.requestDetailTitle,
                  // O'chirish "..." menyu ichida — orqaga qaytish
                  // tugmasi bilan yonma-yon to'g'ridan-to'g'ri chiqindi
                  // ikonkasi bo'lsa, ikkalasini adashtirish xavfi bor
                  // edi (xavfli joy).
                  trailing: !canDelete
                      ? null
                      : PopupMenuButton<void>(
                          icon: const Icon(
                              PhosphorIconsBold.dotsThreeVertical),
                          shape: const RoundedRectangleBorder(
                              borderRadius: AppRadius.smAll),
                          itemBuilder: (context) => [
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
                          Text(request.priority.label,
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
                              return ClipRRect(
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
