import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../data/premium_repository.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// Premium obuna ekrani — imkoniyatlar ro'yxati, narx, karta orqali
/// to'lash oqimi va amaldagi holat.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final configAsync = ref.watch(premiumConfigProvider);
    final requestAsync = ref.watch(myPremiumRequestProvider);

    final profile = profileAsync.valueOrNull;
    final config = configAsync.valueOrNull ?? PremiumConfig.fallback;
    final request = requestAsync.valueOrNull;
    final isPremium = profile?.isPremiumActive == true;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Row(
              children: [
                const LiquidGlassBackButton(),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(l10n.premiumTitle, style: context.titleStyle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            if (isPremium)
              _ActiveCard(until: profile!.premiumUntil!, l10n: l10n)
            else
              _HeroCard(price: config.monthlyPrice, l10n: l10n),

            const SizedBox(height: AppSpacing.xl),
            Text(l10n.premiumBenefitsTitle, style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                children: [
                  _Benefit(
                      icon: PhosphorIconsFill.infinity,
                      text: l10n.premiumBenefitUnlimited),
                  _Benefit(
                      icon: PhosphorIconsFill.megaphoneSimple,
                      text: l10n.premiumBenefitNoAds),
                  _Benefit(
                      icon: PhosphorIconsFill.arrowFatLineUp,
                      text: l10n.premiumBenefitPriority),
                  _Benefit(
                      icon: PhosphorIconsFill.images,
                      text: l10n.premiumBenefitImages),
                  _Benefit(
                      icon: PhosphorIconsFill.palette,
                      text: l10n.premiumBenefitBanners),
                  _Benefit(
                      icon: PhosphorIconsFill.crown,
                      text: l10n.premiumBenefitBadge),
                  _Benefit(
                      icon: PhosphorIconsFill.tag,
                      text: l10n.premiumBenefitAdDiscount),
                  _Benefit(
                      icon: PhosphorIconsFill.headset,
                      text: l10n.premiumBenefitSupport),
                  _Benefit(
                      icon: PhosphorIconsFill.userCircleGear,
                      text: l10n.premiumBenefitAvatar),
                  _Benefit(
                      icon: PhosphorIconsFill.gif,
                      text: l10n.premiumBenefitAnimatedAvatar),
                  _Benefit(
                      icon: PhosphorIconsFill.sparkle,
                      text: l10n.premiumBenefitEarlyAccess,
                      showDivider: false),
                ],
              ),
            ),

            if (!isPremium) ...[
              const SizedBox(height: AppSpacing.xl),
              if (request != null && request.isAwaitingPayment)
                _PaymentPanel(request: request, config: config, l10n: l10n)
              else if (request != null && request.isAwaitingApproval)
                _WaitingApprovalCard(l10n: l10n)
              else
                _PlanPicker(config: config, profile: profile, l10n: l10n),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int price;
  final AppLocalizations l10n;
  const _HeroCard({required this.price, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2F5BFF), Color(0xFF1B3FCC)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/patterns/premium_medal.png',
            width: 56,
            height: 56,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.premiumHeroTitle,
            style: context.titleStyle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.premiumHeroSubtitle,
            style: context.bodyStyle
                .copyWith(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatSum(price),
                style: context.titleStyle.copyWith(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.premiumPerMonth,
                style: context.secondaryStyle
                    .copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveCard extends StatelessWidget {
  final DateTime until;
  final AppLocalizations l10n;
  const _ActiveCard({required this.until, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final days = until.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0A526), Color(0xFFC07E12)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(PhosphorIconsFill.crown, color: Colors.white, size: 34),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.premiumActiveTitle,
              style: context.titleStyle.copyWith(color: Colors.white)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.premiumActiveUntil(_formatDate(until), days),
            style: context.bodyStyle
                .copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool showDivider;
  const _Benefit({
    required this.icon,
    required this.text,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFE0A526)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(text, style: context.bodyStyle)),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: context.borderColor),
      ],
    );
  }
}

/// Muddat tanlash + "Premium olish" tugmasi.
///
/// Ilgari faqat 1 oylik variant bor edi va tugma darhol so'rov
/// yaratardi. Endi foydalanuvchi 1 / 3 / 6 / 12 oydan birini
/// tanlaydi — uzoqroq muddat oyiga arzonroq tushadi.
class _PlanPicker extends ConsumerStatefulWidget {
  final PremiumConfig config;
  final UserProfile? profile;
  final AppLocalizations l10n;
  const _PlanPicker({
    required this.config,
    required this.profile,
    required this.l10n,
  });

  @override
  ConsumerState<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends ConsumerState<_PlanPicker> {
  bool _busy = false;

  // Standart tanlov — 3 oylik: birinchi chegirmali variant, ya'ni
  // foydalanuvchiga eng ko'p uchraydigan mantiqiy o'rta yo'l.
  int _selectedMonths = 3;

  Future<void> _start() async {
    final profile = widget.profile;
    if (profile == null) return;

    final plan =
        PremiumPlan.all.firstWhere((p) => p.months == _selectedMonths);

    setState(() => _busy = true);
    try {
      await ref.read(premiumRepositoryProvider).createRequest(
            fullName: '${profile.firstName} ${profile.lastName}'.trim(),
            phone: profile.phone,
            amount: plan.price(widget.config.monthlyPrice),
            months: plan.months,
          );
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, widget.l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final monthly = widget.config.monthlyPrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.premiumChoosePlan, style: context.captionStyle),
        const SizedBox(height: AppSpacing.sm),
        ...PremiumPlan.all.map(
          (plan) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _PlanTile(
              plan: plan,
              monthlyPrice: monthly,
              selected: plan.months == _selectedMonths,
              l10n: l10n,
              onTap: () => setState(() => _selectedMonths = plan.months),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _busy ? null : _start,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(PhosphorIconsFill.crown, size: 20),
            label: Text(l10n.premiumBuyAction),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              backgroundColor: AppColors.primary,
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bitta tarif qatori: muddat, narx, oyiga qancha tushishi va
/// chegirma nishoni.
class _PlanTile extends StatelessWidget {
  final PremiumPlan plan;
  final int monthlyPrice;
  final bool selected;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.monthlyPrice,
    required this.selected,
    required this.l10n,
    required this.onTap,
  });

  static String _money(int value) {
    // "89100" -> "89 100"
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final price = plan.price(monthlyPrice);
    final perMonth = plan.pricePerMonth(monthlyPrice);

    return TapScale(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.surfaceColor,
          borderRadius: AppRadius.smAll,
          border: Border.all(
            color: selected ? AppColors.primary : context.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? PhosphorIconsFill.checkCircle
                  : PhosphorIconsRegular.circle,
              size: 22,
              color: selected ? AppColors.primary : context.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.premiumPlanMonths(plan.months),
                        style: context.cardTitleStyle,
                      ),
                      if (plan.discountPercent > 0) ...[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E8E3E),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${plan.discountPercent}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.premiumPerMonthAmount(_money(perMonth)),
                    style: context.captionStyle
                        .copyWith(color: context.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  l10n.premiumPriceValue(_money(price)),
                  style: context.cardTitleStyle,
                ),
                if (plan.discountPercent > 0)
                  Text(
                    _money(plan.fullPrice(monthlyPrice)),
                    style: context.captionStyle.copyWith(
                      color: context.textMuted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// To'lov paneli — karta rekvizitlari, sanoq va tasdiqlash tugmasi.
class _PaymentPanel extends ConsumerStatefulWidget {
  final PremiumRequest request;
  final PremiumConfig config;
  final AppLocalizations l10n;
  const _PaymentPanel({
    required this.request,
    required this.config,
    required this.l10n,
  });

  @override
  ConsumerState<_PaymentPanel> createState() => _PaymentPanelState();
}

class _PaymentPanelState extends ConsumerState<_PaymentPanel> {
  Timer? _ticker;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Qolgan vaqtni har soniyada yangilab turamiz.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    showAppAlert(context, message);
  }

  Future<void> _confirmPaid() async {
    setState(() => _busy = true);
    try {
      await ref.read(premiumRepositoryProvider).markAsPaid(widget.request.id);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, widget.l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openTelegram() async {
    final uri = Uri.parse('https://t.me/${widget.config.adminTelegram}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final left = widget.request.expiresAt.difference(DateTime.now());
    final expired = left.isNegative;
    final mm = left.inMinutes.clamp(0, 999).toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).clamp(0, 59).toString().padLeft(2, '0');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.clock,
                  size: 18,
                  color: expired ? AppColors.danger : AppAccents.events),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  expired
                      ? l10n.premiumPaymentExpired
                      : l10n.premiumPaymentTimeLeft('$mm:$ss'),
                  style: context.bodyStyle.copyWith(
                    color: expired ? AppColors.danger : null,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.premiumTransferHint, style: context.secondaryStyle),
          const SizedBox(height: AppSpacing.md),

          _CopyRow(
            label: l10n.premiumCardNumber,
            value: widget.config.formattedCard,
            onTap: () => _copy(
                widget.config.cardNumber.replaceAll(RegExp(r'\D'), ''),
                l10n.premiumCardCopied),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CopyRow(
            label: l10n.premiumCardHolder,
            value: widget.config.cardHolder,
            onTap: () =>
                _copy(widget.config.cardHolder, l10n.premiumHolderCopied),
          ),
          const SizedBox(height: AppSpacing.sm),
          _CopyRow(
            label: l10n.premiumAmount,
            value: _formatSum(widget.request.amount),
            onTap: () => _copy(
                widget.request.amount.toString(), l10n.premiumAmountCopied),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_busy || expired) ? null : _confirmPaid,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                backgroundColor: AppColors.primary,
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.premiumIPaidAction),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openTelegram,
              icon: const Icon(PhosphorIconsFill.paperPlaneTilt, size: 18),
              label: Text(l10n.premiumContactAdmin),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape:
                    const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.premiumTelegramHint,
              style: context.captionStyle.copyWith(color: context.textMuted)),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.isDarkMode
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: AppRadius.smAll,
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.captionStyle),
                  const SizedBox(height: 2),
                  Text(value,
                      style: context.bodyStyle
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            Icon(PhosphorIconsRegular.copy, size: 18, color: context.textMuted),
          ],
        ),
      ),
    );
  }
}

class _WaitingApprovalCard extends StatelessWidget {
  final AppLocalizations l10n;
  const _WaitingApprovalCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          const Icon(PhosphorIconsFill.hourglassMedium,
              size: 22, color: AppAccents.events),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.premiumWaitingTitle,
                    style: context.bodyStyle
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(l10n.premiumWaitingSubtitle,
                    style: context.secondaryStyle),
              ],
            ),
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

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}.'
    '${dt.month.toString().padLeft(2, '0')}.${dt.year}';
