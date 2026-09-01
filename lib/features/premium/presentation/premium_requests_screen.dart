import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/shimmer.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../notifications/data/notification_repository.dart';
import '../data/premium_repository.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// Super admin uchun — to'lov qilgan foydalanuvchilarni tasdiqlash.
class PremiumRequestsScreen extends ConsumerWidget {
  const PremiumRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(pendingPremiumRequestsProvider);

    return Scaffold(
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
                    child: Text(l10n.premiumRequestsTitle,
                        style: context.titleStyle),
                  ),
                ],
              ),
            ),

            // Qo'lda berish — to'lov so'rovisiz.
            //
            // Bu shu uchun kerakki: birinchidan, super admin premiumni
            // sinab ko'rishi (o'ziga yoqishi) kerak, ikkinchidan, real
            // hayotda to'lov ilovadan tashqarida (naqd, boshqa karta)
            // bo'lishi mumkin.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: _ManualGrantCard(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: requestsAsync.when(
                data: (requests) {
                  if (requests.isEmpty) {
                    return AppEmptyView(
                      icon: PhosphorIconsFill.crown,
                      title: l10n.premiumRequestsEmpty,
                      scrollable: true,
                    );
                  }
                  return ListView.builder(
                    padding: AppSpacing.listPadding,
                    itemCount: requests.length,
                    itemBuilder: (context, index) =>
                        _RequestCard(request: requests[index], l10n: l10n),
                  );
                },
                loading: () => const ShimmerList(count: 4),
                error: (e, _) => AppErrorView.fromError(
                  e,
                  onRetry: () => ref.invalidate(pendingPremiumRequestsProvider),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  final PremiumRequest request;
  final AppLocalizations l10n;
  const _RequestCard({required this.request, required this.l10n});

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, widget.l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final l10n = widget.l10n;
    final repo = ref.read(premiumRepositoryProvider);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.crown,
                  size: 20, color: Color(0xFFE0A526)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  r.fullName.isEmpty ? l10n.defaultUserName : r.fullName,
                  style: context.bodyStyle.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(_formatSum(r.amount), style: context.bodyStyle),
            ],
          ),
          if (r.phone.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(formatPhoneNumber(r.phone), style: context.secondaryStyle),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.premiumRequestMonths(r.months),
            style: context.captionStyle.copyWith(color: context.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _busy ? null : () => _run(() => repo.rejectRequest(r)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: Text(l10n.premiumRejectAction),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _busy ? null : () => _run(() => repo.approveRequest(r)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.premiumApproveAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatSum(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return "${buf.toString()} so'm";
}

/// Premiumni QO'LDA berish paneli (faqat super admin ekranida).
///
/// Ikki tugma: "O'zimga berish" — super admin obunani sinab ko'rishi
/// uchun, va telefon raqami bo'yicha boshqa foydalanuvchiga berish —
/// to'lov ilovadan tashqarida bo'lgan hollar uchun.
class _ManualGrantCard extends ConsumerStatefulWidget {
  const _ManualGrantCard();

  @override
  ConsumerState<_ManualGrantCard> createState() => _ManualGrantCardState();
}

class _ManualGrantCardState extends ConsumerState<_ManualGrantCard> {
  final _phoneController = TextEditingController();
  int _months = 1;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _toast(String message, {bool error = false}) {
    showAppAlert(context, message, kind: AppAlertKind.error);
  }

  Future<void> _grantToSelf() async {
    final l10n = AppLocalizations.of(context);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      await ref
          .read(premiumRepositoryProvider)
          .grantPremium(uid, months: _months);
      ref.invalidate(currentUserProfileProvider);
      if (mounted) _toast(l10n.premiumGrantedSelf(_months));
    } catch (_) {
      if (mounted) _toast(l10n.unexpectedError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Telefon raqami bo'yicha foydalanuvchini topadi — `_grantByPhone`
  /// bilan bir xil ("oxirgi 9 raqam" solishtirish) mantiq, faqat topilgan
  /// hujjatning o'zini qaytaradi, chunki chaqiruvchi (grant/revoke) bu
  /// yerdan keyin turlicha davom etadi.
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findUserByPhone() async {
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 9) return null;
    final tail = raw.substring(raw.length - 9);
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    final match = snapshot.docs.where((d) {
      final phone =
          (d.data()['phone'] as String? ?? '').replaceAll(RegExp(r'\D'), '');
      return phone.length >= 9 && phone.endsWith(tail);
    }).toList();
    return match.isEmpty ? null : match.first;
  }

  Future<void> _revokeByPhone() async {
    final l10n = AppLocalizations.of(context);
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 9) {
      _toast(l10n.phoneValidationError, error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final doc = await _findUserByPhone();
      if (doc == null) {
        if (mounted) _toast(l10n.premiumGrantUserNotFound, error: true);
        return;
      }

      final name = [
        doc.data()['firstName'] as String? ?? '',
        doc.data()['lastName'] as String? ?? '',
      ].where((p) => p.isNotEmpty).join(' ');
      final displayName = name.isEmpty ? raw.substring(raw.length - 9) : name;

      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
          title: Text(l10n.premiumRevokeConfirmTitle),
          content: Text(l10n.premiumRevokeConfirmMessage(displayName)),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.premiumRevokeAction,
                  style: const TextStyle(color: AppColors.danger)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await ref.read(premiumRepositoryProvider).revokePremium(doc.id);

      if (mounted) {
        _phoneController.clear();
        _toast(l10n.premiumRevokedFrom(displayName));
      }
    } catch (_) {
      if (mounted) _toast(l10n.unexpectedError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _grantByPhone() async {
    final l10n = AppLocalizations.of(context);
    final raw = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (raw.length < 9) {
      _toast(l10n.phoneValidationError, error: true);
      return;
    }

    setState(() => _busy = true);
    try {
      final doc = await _findUserByPhone();
      if (doc == null) {
        if (mounted) _toast(l10n.premiumGrantUserNotFound, error: true);
        return;
      }

      await ref
          .read(premiumRepositoryProvider)
          .grantPremium(doc.id, months: _months);

      await NotificationRepository().sendToUser(
        uid: doc.id,
        type: NotificationType.premiumApproved,
        title: 'Premium faollashtirildi',
        body: '$_months oylik premium obunangiz ochildi. Rahmat!',
      );

      if (mounted) {
        _phoneController.clear();
        final name = [
          doc.data()['firstName'] as String? ?? '',
          doc.data()['lastName'] as String? ?? '',
        ].where((p) => p.isNotEmpty).join(' ');
        _toast(l10n.premiumGrantedTo(
            name.isEmpty ? raw.substring(raw.length - 9) : name, _months));
      }
    } catch (_) {
      if (mounted) _toast(l10n.unexpectedError, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsFill.handCoins,
                  size: 18, color: Color(0xFFE0A526)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child:
                    Text(l10n.premiumGrantTitle, style: context.cardTitleStyle),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Muddat tanlash — premium tariflari bilan bir xil ro'yxat.
          Wrap(
            spacing: AppSpacing.sm,
            children: PremiumPlan.all.map((plan) {
              final selected = plan.months == _months;
              return ChoiceChip(
                label: Text(l10n.premiumPlanMonths(plan.months)),
                selected: selected,
                onSelected: _busy
                    ? null
                    : (_) => setState(() => _months = plan.months),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _grantToSelf,
              icon: const Icon(PhosphorIconsFill.crown, size: 18),
              label: Text(l10n.premiumGrantSelfAction),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(height: 1, color: context.borderColor),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.premiumGrantPhoneLabel,
              prefixText: '+998 ',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _grantByPhone,
                  style: FilledButton.styleFrom(
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l10n.premiumGrantAction),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _revokeByPhone,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll),
                  ),
                  child: Text(l10n.premiumRevokeAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
