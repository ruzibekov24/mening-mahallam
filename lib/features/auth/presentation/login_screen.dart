import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/uz_phone_input_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// 5. KIRISH (LOGIN) ekrani.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+998 ');
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signIn(
            phone: cleanPhoneDigits(_phoneController.text),
            password: _passwordController.text,
          );
      if (!mounted) return;

      // Foydalanuvchi allaqachon biror mahallaga bog'langanmi degan
      // tekshiruv (va Home/QR skanerlashga yo'naltirish) ATAYLAB shu
      // yerda takrorlanmaydi — `app_router.dart`dagi `redirect` MANA SHU
      // BITTA joyda (yagona haqiqat manbai) hal qiladi, keshdan
      // qaytarib olish bilan birga. Agar bu yerda ikkinchi marta
      // (mustaqil, keshsiz) tekshirilsa, ikkalasi bir-biridan
      // farqli natija berishi mumkin — masalan bu yerdagi `.get()`
      // vaqtinchalik xato bersa, foydalanuvchi mahallasi bor bo'lsa
      // ham QR skanerlashga yuborilardi. `splash`ga o'tish shunchaki
      // routerni qaytadan ishga tushiradi.
      context.go(AppRoutes.splash);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError(l10n.unexpectedError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

    const bannerHeight = 220.0;

    return Scaffold(
      body: Stack(
        children: [
          // Yuqoridagi gradient banner — pastki chegarasi to'lqin
          // shaklida, ichida esa yumshoq topologik chiziqlar bor
          // (referensdagi "Welcome"/"wwater" uslubiga o'xshab).
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: bannerHeight,
            child: ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      Color.lerp(AppColors.primary, const Color(0xFF7B5CFA), 0.55)!,
                    ],
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _TopoLinesPainter()),
                    ),
                    Positioned(
                      top: -40,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 90,
                      left: -40,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: bannerHeight - 190),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: AppRadius.lgAll,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Image.asset('assets/images/logo.png',
                          fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.loginTitle,
                            style: context.displayStyle.copyWith(fontSize: 26),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(l10n.loginSubtitle, style: context.secondaryStyle),
                          const SizedBox(height: AppSpacing.xxl),

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
                          const SizedBox(height: AppSpacing.xs),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              child: Text(l10n.forgotPassword),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          SizedBox(
                            height: 54,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: AppRadius.mdAll,
                                boxShadow: AppShadows.accent(
                                    AppColors.primary, isDark),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : Text(l10n.loginButton),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          Row(
                            children: [
                              Expanded(
                                  child: Divider(
                                      color: secondaryColor
                                          .withValues(alpha: 0.3))),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md),
                                child: Text(l10n.orDivider,
                                    style: context.captionStyle),
                              ),
                              Expanded(
                                  child: Divider(
                                      color: secondaryColor
                                          .withValues(alpha: 0.3))),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),

                          Center(
                            child: Wrap(
                              children: [
                                Text(
                                  l10n.noAccountQuestion,
                                  style: context.secondaryStyle,
                                ),
                                GestureDetector(
                                  onTap: () => context.go(AppRoutes.register),
                                  child: Text(
                                    l10n.registerButton,
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
                  const SizedBox(height: AppSpacing.xl),
                ],
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
/// Bannerning pastki chegarasini yumshoq to'lqin shaklida kesadi
/// (referensdagi "Welcome"/"wwater" ekranlaridagi uslub).
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 46);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 46,
      size.width,
      size.height - 10,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Banner ichida yumshoq, tasodifiy bo'lmagan topologik chiziqlar —
/// referensdagi xira "contour line" naqshiga o'xshab, fonni
/// mazmunliroq qiladi.
class _TopoLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var i = 0; i < 5; i++) {
      final path = Path();
      final baseY = size.height * (0.15 + i * 0.16);
      path.moveTo(-20, baseY);
      path.quadraticBezierTo(
        size.width * 0.3,
        baseY - 30 - i * 6,
        size.width * 0.55,
        baseY + 10,
      );
      path.quadraticBezierTo(
        size.width * 0.8,
        baseY + 40 + i * 4,
        size.width + 20,
        baseY - 15,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TopoLinesPainter oldDelegate) => false;
}