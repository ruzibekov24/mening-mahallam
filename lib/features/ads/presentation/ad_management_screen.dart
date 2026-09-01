import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/confirm_delete.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../core/widgets/uz_phone_input_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/service_ad_repository.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// Super admin uchun — mahalladagi xizmat reklamalarini boshqarish.
class AdManagementScreen extends ConsumerWidget {
  final String mahallaId;
  const AdManagementScreen({super.key, required this.mahallaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final adsAsync = ref.watch(allServiceAdsProvider(mahallaId));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(PhosphorIconsFill.plus),
        label: Text(l10n.adAddAction),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm, AppSpacing.xs, AppSpacing.xl, AppSpacing.xs),
              child: Row(
                children: [
                  const LiquidGlassBackButton(),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child:
                        Text(l10n.adManagementTitle, style: context.titleStyle),
                  ),
                ],
              ),
            ),
            Expanded(
              child: adsAsync.when(
                data: (ads) {
                  if (ads.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.storefront,
                      title: l10n.adEmptyTitle,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: ads.length,
                    itemBuilder: (context, i) => _AdCard(
                      ad: ads[i],
                      mahallaId: mahallaId,
                      l10n: l10n,
                    ),
                  );
                },
                loading: () => const ShimmerList(count: 4),
                error: (e, _) => AppErrorView.fromError(
                  e,
                  onRetry: () =>
                      ref.invalidate(allServiceAdsProvider(mahallaId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // Bu ekran Navigator.push bilan ochiladi — orqasida
      // MainShell foni YO'Q. Shaffof qoldirilsa ekran qop-qora
      // bo'lib ko'rinardi. Rang berilmasa mavzudagi
      // `scaffoldBackgroundColor` ishlaydi (dark mode ham).
      builder: (_) => _AdEditorSheet(mahallaId: mahallaId),
    );
  }
}

class _AdCard extends ConsumerWidget {
  final ServiceAd ad;
  final String mahallaId;
  final AppLocalizations l10n;
  const _AdCard({
    required this.ad,
    required this.mahallaId,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(serviceAdRepositoryProvider);
    final active = ad.isActive;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(ad.title,
                    style:
                        context.bodyStyle.copyWith(fontWeight: FontWeight.w600)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (active ? AppAccents.requests : context.textMuted)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  active ? l10n.adStatusActive : l10n.adStatusExpired,
                  style: context.captionStyle.copyWith(
                    color: active ? AppAccents.requests : context.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (ad.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(ad.description, style: context.secondaryStyle),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              ad.ownerName,
              if (ad.phone.isNotEmpty) formatPhoneNumber(ad.phone),
            ].where((e) => e.isNotEmpty).join(' · '),
            style: context.captionStyle.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.adActiveUntil(_formatDate(ad.activeUntil)),
            style: context.captionStyle.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final ok = await confirmDelete(context, itemTitle: ad.title);
                    if (ok) await repo.deleteAd(mahallaId, ad.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: Text(l10n.deleteButton),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: () => repo.extendAd(mahallaId, ad.id),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: Text(l10n.adExtendAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdEditorSheet extends ConsumerStatefulWidget {
  final String mahallaId;
  const _AdEditorSheet({required this.mahallaId});

  @override
  ConsumerState<_AdEditorSheet> createState() => _AdEditorSheetState();
}

class _AdEditorSheetState extends ConsumerState<_AdEditorSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _owner = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _phone.dispose();
    _owner.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (_title.text.trim().isEmpty) {
      showAppAlert(context, l10n.adTitleRequired, kind: AppAlertKind.error);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(serviceAdRepositoryProvider).createAd(
            mahallaId: widget.mahallaId,
            title: _title.text.trim(),
            description: _description.text.trim(),
            phone: _phone.text.replaceAll(RegExp(r'\D'), ''),
            ownerName: _owner.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.adAddAction, style: context.titleStyle),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: l10n.adTitleLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _description,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.adDescriptionLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _owner,
                decoration: InputDecoration(labelText: l10n.adOwnerLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [UzPhoneInputFormatter()],
                decoration: InputDecoration(labelText: l10n.phoneLabel),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    backgroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(l10n.adSaveAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.'
    '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
