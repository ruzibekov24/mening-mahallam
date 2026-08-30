import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// Tizimga kirgan holda parolni almashtirish — joriy parolni bilgan
/// foydalanuvchi uchun. ("Parolni unutdim" oqimidan farqli — u
/// Telegram orqali tasdiqlashni talab qiladi va alohida ekranda.)
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      // Firebase parolni yangilashdan oldin "yangi" sessiya talab
      // qiladi — shuning uchun avval joriy parol bilan qayta
      // autentifikatsiya qilinadi.
      await repo.reauthenticate(_currentController.text);
      await repo.changePassword(_newController.text);
      if (!mounted) return;
      showAppAlert(context, l10n.passwordResetSuccess);
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      showAppAlert(context, e.message, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.changePasswordTitle, style: context.titleStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PasswordField(
                    label: l10n.currentPasswordLabel,
                    controller: _currentController,
                    obscure: _obscureCurrent,
                    onToggleObscure: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                    validator: (value) => (value ?? '').isEmpty
                        ? l10n.passwordValidationError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PasswordField(
                    label: l10n.newPasswordLabel,
                    controller: _newController,
                    obscure: _obscureNew,
                    onToggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: (value) => (value ?? '').length < 6
                        ? l10n.passwordValidationError
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _PasswordField(
                    label: l10n.confirmPasswordLabel,
                    controller: _confirmController,
                    obscure: _obscureNew,
                    onToggleObscure: () =>
                        setState(() => _obscureNew = !_obscureNew),
                    validator: (value) => value != _newController.text
                        ? l10n.passwordMismatchError
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
                          : Text(l10n.savePasswordButton),
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

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggleObscure,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.secondaryStyle),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? PhosphorIconsRegular.eyeSlash
                    : PhosphorIconsRegular.eye,
                size: 20,
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
