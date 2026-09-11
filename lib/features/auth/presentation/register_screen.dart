import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/girih_header.dart';
import '../../../core/widgets/uz_phone_input_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../data/phone_verification_repository.dart';
import 'telegram_verify_screen.dart';
import '../../../core/widgets/app_alert.dart';
import '../../../core/widgets/liquid_glass.dart';

/// 6. RO'YXATDAN O'TISH (REGISTER) ekrani.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+998 ');
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final digits = cleanPhoneDigits(_phoneController.text);
    final phoneE164 = '+$digits';
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;

    final repo = ref.read(phoneVerificationRepositoryProvider);
    try {
      final token = await repo.startVerification(phoneE164: phoneE164);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TelegramVerifyScreen(
            phoneE164: phoneE164,
            token: token,
            onVerified: () async {
              await ref.read(authRepositoryProvider).registerWithVerifiedPhone(
                    firstName: firstName,
                    lastName: lastName,
                    phone: digits,
                    password: password,
                  );
              if (context.mounted) Navigator.of(context).pop(true);
            },
          ),
        ),
      );
      if (verified == true && mounted) {
        context.go(AppRoutes.qrScan);
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
    final l10n = AppLocalizations.of(context);
    final isDark = context.isDarkMode;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    const bannerHeight = 130.0;

    return Scaffold(
      body: Stack(
        children: [
          // Login ekrani bilan bir xil umumiy sarlavha lentasi —
          // alohida to'lqin/topo chizig'i o'rniga `GirihHeader`.
          SizedBox(
            height: bannerHeight,
            width: double.infinity,
            child: GirihHeader(
              image: 'assets/images/patterns/auth_gate.jpg',
              child: const SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    LiquidGlassBackButton(onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.login);
                      }
                    }),
                    const SizedBox(height: AppSpacing.xxxl),
                    Text(
                      l10n.registerTitle,
                      style: context.displayStyle.copyWith(fontSize: 26),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(l10n.registerSubtitle, style: context.secondaryStyle),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(l10n.firstNameLabel, style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _shadowedField(
                      isDark: isDark,
                      child: TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(hintText: 'Ilyos'),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? l10n.firstNameValidationError
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.lastNameLabel, style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _shadowedField(
                      isDark: isDark,
                      child: TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        decoration:
                            const InputDecoration(hintText: 'Ruzibekov'),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? l10n.lastNameValidationError
                            : null,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.phoneLabel, style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _shadowedField(
                      isDark: isDark,
                      child: TextFormField(
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
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.passwordLabel, style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    _shadowedField(
                      isDark: isDark,
                      child: TextFormField(
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
                              color: secondaryColor,
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
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(l10n.continueButton),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Wrap(
                        children: [
                          Text(
                            l10n.haveAccountQuestion,
                            style: context.secondaryStyle,
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.login),
                            child: Text(
                              l10n.loginButton,
                              style: context.secondaryStyle.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shadowedField({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdAll,
        boxShadow: AppShadows.card(isDark),
      ),
      child: child,
    );
  }
}
