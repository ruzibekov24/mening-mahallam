import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../map/presentation/mahalla_map_screen.dart';
import '../data/requests_labels.dart';
import '../data/requests_repository.dart';
import 'new_request_flow_screen.dart';
import 'request_detail_screen.dart';
import 'request_styles.dart';
import 'requests_management_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// 12. MUROJAATLAR ekrani.
class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key});

  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  RequestStatus? _selectedStatus; // null = hammasi

  Future<void> _openNewRequestFlow() async {
    final l10n = AppLocalizations.of(context);
    final profile = await ref.read(currentUserProfileProvider.future);
    final mahallaId = profile?.mahallaId;

    if (!mounted) return;

    if (mahallaId == null || mahallaId.isEmpty) {
      showAppAlert(context, l10n.mustVerifyMahallaFirst, kind: AppAlertKind.error);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewRequestFlowScreen(mahallaId: mahallaId),
      ),
    );
  }

  void _openManagementPanel(String mahallaId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RequestsManagementScreen(mahallaId: mahallaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(myRequestsProvider);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            GirihHeader(
              color: AppAccents.requests,
              image: 'assets/images/patterns/abstract_green.png',
              watermarkIcon: PhosphorIconsFill.chatCircleDots,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.requestsTitle,
                      style: context.titleStyle.copyWith(color: Colors.white)),
                  Row(
                    children: [
                      profileAsync.when(
                        data: (profile) {
                          final mahallaId = profile?.mahallaId;
                          if (mahallaId == null) return const SizedBox.shrink();
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.sm),
                            child: IconButton.filledTonal(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MahallaMapScreen(mahallaId: mahallaId),
                                ),
                              ),
                              icon: const Icon(PhosphorIconsRegular.mapTrifold,
                                  size: 20),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      _NewRequestButton(
                        label: l10n.newButton,
                        onTap: _openNewRequestFlow,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Faqat xodim/rais uchun — Boshqaruv paneliga o'tish banneri.
            profileAsync.when(
              data: (profile) {
                if (profile?.role.canManageRequests != true ||
                    profile?.mahallaId == null) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
                  child: _ManagementBanner(
                    label: l10n.managementPanelBanner,
                    onTap: () => _openManagementPanel(profile!.mahallaId!),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: AppSpacing.sm),
            requestsAsync.when(
              data: (requests) {
                final counts = <RequestStatus?, int>{
                  null: requests.length,
                  for (final status in RequestStatus.values)
                    status: requests.where((r) => r.status == status).length,
                };
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        AppFilterChip(
                          label: l10n.filterAll,
                          count: counts[null]!,
                          isActive: _selectedStatus == null,
                          onTap: () => setState(() => _selectedStatus = null),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        for (final status in RequestStatus.values) ...[
                          AppFilterChip(
                            label: statusLabel(l10n, status),
                            count: counts[status]!,
                            isActive: _selectedStatus == status,
                            onTap: () =>
                                setState(() => _selectedStatus = status),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(myRequestsProvider),
                child: requestsAsync.when(
                  data: (requests) {
                    final filtered = _selectedStatus == null
                        ? requests
                        : requests
                            .where((r) => r.status == _selectedStatus)
                            .toList();

                    if (filtered.isEmpty) {
                      return AppEmptyView(
                        icon: PhosphorIconsFill.tray,
                        title: _selectedStatus == null
                            ? l10n.noRequestsAtAll
                            : l10n.noRequestsWithStatus(
                                statusLabel(l10n, _selectedStatus!)),
                        subtitle: _selectedStatus == null
                            ? l10n.noRequestsHint
                            : null,
                        actionLabel: _selectedStatus == null
                            ? l10n.newRequestTitle
                            : null,
                        // Ekranning o'z usuli ishlatiladi — u mahalla
                        // tanlanganini tekshiradi va tanlanmagan bo'lsa
                        // tushunarli xabar ko'rsatadi.
                        onAction:
                            _selectedStatus == null ? _openNewRequestFlow : null,
                        accent: AppAccents.requests,
                        scrollable: true,
                      );
                    }

                    return ListView.builder(
                      padding: AppSpacing.listPadding,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final request = filtered[index];
                        final mahallaId = profileAsync.value?.mahallaId;
                        return _RequestCard(
                          request: request,
                          onTap: mahallaId == null
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RequestDetailScreen(
                                        mahallaId: mahallaId,
                                        requestId: request.id,
                                      ),
                                    ),
                                  );
                                },
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
                    onRetry: () => ref.invalidate(myRequestsProvider),
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

class _ManagementBanner extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ManagementBanner({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: AppRadius.smAll,
      child: InkWell(
        borderRadius: AppRadius.smAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsFill.shieldCheck,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: context.secondaryStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight,
                  size: 18, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewRequestButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NewRequestButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.smAll,
        boxShadow: AppShadows.accent(AppColors.primary, context.isDarkMode),
      ),
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.smAll,
        child: InkWell(
          borderRadius: AppRadius.smAll,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(PhosphorIconsBold.plus, size: 16, color: Colors.white),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  label,
                  style: context.secondaryStyle.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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

class _RequestCard extends StatelessWidget {
  final MahallaRequest request;
  final VoidCallback? onTap;
  const _RequestCard({required this.request, this.onTap});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: request.priority.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs, vertical: 3),
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
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    request.type == RequestType.maxfiy
                        ? PhosphorIconsRegular.lockSimple
                        : PhosphorIconsRegular.globe,
                    size: 13,
                    color: context.textSecondary,
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
          if (request.imageUrls.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: request.imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: Image.network(
                    request.imageUrls[index],
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        width: 52,
                        height: 52,
                        color: context.textSecondary.withValues(alpha: 0.15),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      width: 52,
                      height: 52,
                      color: context.textSecondary.withValues(alpha: 0.15),
                      child: Icon(PhosphorIconsRegular.imageBroken,
                          size: 18, color: context.textSecondary),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (request.type == RequestType.ommaviy &&
              request.joinedCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(PhosphorIconsFill.usersThree,
                    size: 13, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  l10n.joinedCount(request.joinedCount),
                  style: context.captionStyle.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
