import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../l10n/app_localizations.dart';
import '../data/report_repository.dart';

/// Shikoyat qilish oynasini pastdan chiqaradi — sabab tanlash va
/// ixtiyoriy izoh kiritish, so'ng [ReportRepository.createReport]
/// chaqiradi.
///
/// [targetSnippet] — ko'rib chiquvchiga kontekst berish uchun qisqa
/// matn (xabar matni, e'lon sarlavhasi, foydalanuvchi ismi va h.k.).
Future<void> showReportSheet(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetType targetType,
  required String targetId,
  required String targetSnippet,
  String? mahallaId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(
      targetType: targetType,
      targetId: targetId,
      targetSnippet: targetSnippet,
      mahallaId: mahallaId,
    ),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  final ReportTargetType targetType;
  final String targetId;
  final String targetSnippet;
  final String? mahallaId;

  const _ReportSheet({
    required this.targetType,
    required this.targetId,
    required this.targetSnippet,
    required this.mahallaId,
  });

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _detailsController = TextEditingController();
  ReportReason? _reason;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l10n, ReportReason reason) {
    switch (reason) {
      case ReportReason.spam:
        return l10n.reportReasonSpam;
      case ReportReason.haqoratOmuhandaslik:
        return l10n.reportReasonHaqoratOmuhandaslik;
      case ReportReason.aldash:
        return l10n.reportReasonAldash;
      case ReportReason.nomunosib:
        return l10n.reportReasonNomunosib;
      case ReportReason.boshqa:
        return l10n.reportReasonBoshqa;
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (_reason == null) {
      showAppAlert(context, l10n.reportChooseReasonError,
          kind: AppAlertKind.error);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(reportRepositoryProvider).createReport(
            targetType: widget.targetType,
            targetId: widget.targetId,
            targetSnippet: widget.targetSnippet,
            mahallaId: widget.mahallaId,
            reason: _reason!,
            details: _detailsController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppAlert(context, l10n.reportSubmittedMessage,
          kind: AppAlertKind.success);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      showAppAlert(context, l10n.reportErrorMessage, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: AppRadius.lgAll,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(PhosphorIconsFill.flag,
                          color: AppColors.danger, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.reportSheetTitle, style: context.titleStyle),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.reportReasonLabel, style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: ReportReason.values.map((reason) {
                    final isActive = reason == _reason;
                    return GestureDetector(
                      onTap: () => setState(() => _reason = reason),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.danger
                              : AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: AppRadius.pillAll,
                        ),
                        child: Text(
                          _reasonLabel(l10n, reason),
                          style: context.captionStyle.copyWith(
                            color: isActive ? Colors.white : AppColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.reportDetailsLabel, style: context.captionStyle),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _detailsController,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(hintText: l10n.reportDetailsHint),
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.smAll),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.reportSubmitAction),
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
