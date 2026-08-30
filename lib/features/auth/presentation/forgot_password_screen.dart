import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/uz_phone_input_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/phone_verification_repository.dart';
import 'telegram_verify_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// "Parolni unutdim" oqimining birinchi qadami: telefon raqamni
/// kiritish. Keyin TelegramVerifyScreen'ga o'tadi, u yerda
/// tasdiqlangach _NewPasswordScreen ochiladi.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+998 ');
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final digits = cleanPhoneDigits(_phoneController.text);
    final phoneE164 = '+$digits';

    final repo = ref.read(phoneVerificationRepositoryProvider);
    try {
      final token = await repo.startVerification(phoneE164: phoneE164);
      if (!mounted) return;
      setState(() => _isLoading = false);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TelegramVerifyScreen(
            phoneE164: phoneE164,
            token: token,
            onVerified: () async {
              if (!context.mounted) return;
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (_) => _NewPasswordScreen(
                    phoneE164: phoneE164,
                    token: token,
                  ),
                ),
              );
            },
          ),
        ),
      );
    } on PhoneVerificationException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.lgAll,
                  ),
                  child: const Icon(PhosphorIconsFill.lockKeyOpen,
                      color: AppColors.primary, size: 30),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.forgotPasswordTitle, style: context.displayStyle),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.forgotPasswordSubtitle,
                  style: context.secondaryStyle.copyWith(height: 1.4),
                ),
                const SizedBox(height: AppSpacing.xxl),

                Text(l10n.phoneLabel, style: context.captionStyle),
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
                    if (digits.length < 12) {
                      return l10n.phoneValidationError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendCode,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(l10n.sendCodeButton),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Parolni unutdim" oqimining oxirgi qadami: telefon Telegram
/// orqali allaqachon tasdiqlangan, endi foydalanuvchi yangi parol
/// kiritadi. [token] Telegram tasdig'ini isbotlaydi va
/// `reset-password` Edge Function'ga uzatiladi.
class _NewPasswordScreen extends ConsumerStatefulWidget {
  final String phoneE164;
  final String token;
  const _NewPasswordScreen({required this.phoneE164, required this.token});

  @override
  ConsumerState<_NewPasswordScreen> createState() =>
      _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<_NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isLoading = true);
    try {
      await ref.read(phoneVerificationRepositoryProvider).resetPassword(
            token: widget.token,
            newPassword: _passwordController.text,
          );
      if (!mounted) return;
      showAppAlert(context, l10n.passwordResetSuccess);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on PhoneVerificationException catch (e) {
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    } catch (_) {
      showAppAlert(context, l10n.unexpectedError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xs),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.newPasswordTitle, style: context.displayStyle),
                const SizedBox(height: AppSpacing.xs),
                Text(l10n.newPasswordSubtitle, style: context.secondaryStyle),
                const SizedBox(height: AppSpacing.xxl),

                Text(l10n.newPasswordLabel, style: context.captionStyle),
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
                        () => _obscurePassword = !_obscurePassword,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if ((value ?? '').length < 6) {
                      return l10n.passwordValidationError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xxl),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(l10n.savePasswordButton),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
