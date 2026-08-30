import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/uz_phone_input_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/data/phone_verification_repository.dart';
import '../../auth/presentation/telegram_verify_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// Telefon raqamni almashtirish: joriy parol bilan tasdiqlash, so'ng
/// yangi raqamni Telegram bot orqali tasdiqlash — ro'yxatdan o'tish
/// oqimidagi mexanizmning o'zi qayta ishlatiladi.
class ChangePhoneScreen extends ConsumerStatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  ConsumerState<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends ConsumerState<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController(text: '+998 ');

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final digits = cleanPhoneDigits(_phoneController.text);
    final phoneE164 = '+$digits';

    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    try {
      // Yangi raqamni Telegram orqali tasdiqlashdan oldin, o'zgartirish
      // haqiqatan ham hisob egasi tomonidan so'ralganini tasdiqlash
      // uchun joriy parol bilan qayta autentifikatsiya qilinadi.
      await authRepo.reauthenticate(_passwordController.text);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
      return;
    }

    final verifyRepo = ref.read(phoneVerificationRepositoryProvider);
    try {
      final token = await verifyRepo.startVerification(phoneE164: phoneE164);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TelegramVerifyScreen(
            phoneE164: phoneE164,
            token: token,
            onVerified: () async {
              await authRepo.changePhoneNumber(digits);
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
        ),
      );
      if (changed == true && mounted) {
        showAppAlert(context, l10n.phoneChangedMessage);
        Navigator.of(context).pop();
      }
    } on PhoneVerificationException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e.message);
    }
  }

  void _showError(String message) {
    showAppAlert(context, message, kind: AppAlertKind.error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.changePhoneTitle, style: context.titleStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.newPhoneLabel, style: context.secondaryStyle),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [UzPhoneInputFormatter()],
                    decoration: const InputDecoration(
                      hintText: '+998 90 123 45 67',
                    ),
                    validator: (value) {
                      final digits = cleanPhoneDigits(value ?? '');
                      return digits.length < 12
                          ? l10n.phoneValidationError
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.currentPasswordLabel, style: context.secondaryStyle),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? PhosphorIconsRegular.eyeSlash
                              : PhosphorIconsRegular.eye,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (value) => (value ?? '').isEmpty
                        ? l10n.passwordValidationError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(l10n.changePhoneTitle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
