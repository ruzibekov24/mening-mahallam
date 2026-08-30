import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_alert.dart';
import '../data/premium_repository.dart';

/// Super admin uchun: premium to'lov rekvizitlarini tahrirlash.
///
/// Ilgari karta raqami faqat `PremiumConfig.fallback` ichida, ya'ni
/// APK ichida qattiq yozilgan edi. Uni o'zgartirish uchun har safar
/// yangi reliz chiqarib, hamma foydalanuvchi yangilashini kutish
/// kerak bo'lardi — karta bloklansa yoki almashsa, to'lovlar shu
/// vaqtgacha to'xtab qolardi.
///
/// Endi qiymatlar `appConfig/premium` hujjatida saqlanadi va shu
/// yerdan bir necha soniyada o'zgartiriladi. Koddagi zaxira qiymat
/// esa faqat hujjat hali yaratilmagan bo'lsa ishlaydi.
class PremiumConfigScreen extends ConsumerStatefulWidget {
  const PremiumConfigScreen({super.key});

  @override
  ConsumerState<PremiumConfigScreen> createState() =>
      _PremiumConfigScreenState();
}

class _PremiumConfigScreenState extends ConsumerState<PremiumConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumber = TextEditingController();
  final _cardHolder = TextEditingController();
  final _price = TextEditingController();
  final _telegram = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ref.read(premiumRepositoryProvider).fetchConfig();
    if (!mounted) return;
    setState(() {
      _cardNumber.text = config.cardNumber;
      _cardHolder.text = config.cardHolder;
      _price.text = config.monthlyPrice.toString();
      _telegram.text = config.adminTelegram;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardHolder.dispose();
    _price.dispose();
    _telegram.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    try {
      await ref.read(premiumRepositoryProvider).saveConfig(
            PremiumConfig(
              cardNumber: _cardNumber.text.replaceAll(RegExp(r'\s'), ''),
              cardHolder: _cardHolder.text.trim(),
              monthlyPrice: int.parse(_price.text.trim()),
              adminTelegram:
                  _telegram.text.trim().replaceAll(RegExp(r'^@'), ''),
            ),
          );
      if (!mounted) return;
      await showAppAlert(context, l10n.premiumConfigSaved,
          kind: AppAlertKind.success);
      navigator.pop();
    } catch (_) {
      if (!mounted) return;
      await showAppAlert(context, l10n.unexpectedError,
          kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumConfigTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(PhosphorIconsFill.info,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.premiumConfigHint,
                            style: context.secondaryStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.premiumCardNumberLabel,
                    ),
                    validator: (v) {
                      final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                      return digits.length == 16
                          ? null
                          : l10n.premiumCardNumberInvalid;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _cardHolder,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.premiumCardHolderLabel,
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? l10n.premiumCardHolderInvalid
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.premiumPriceLabel,
                      suffixText: l10n.currencySom,
                    ),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      return (n != null && n > 0)
                          ? null
                          : l10n.premiumPriceInvalid;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _telegram,
                    decoration: InputDecoration(
                      labelText: l10n.premiumTelegramLabel,
                      prefixText: '@',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.smAll,
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.saveButton),
                  ),
                ],
              ),
            ),
    );
  }
}
