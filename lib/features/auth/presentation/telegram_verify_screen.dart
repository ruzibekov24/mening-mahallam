import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../data/auth_repository.dart';
import '../data/phone_verification_repository.dart';

/// Telefon raqamni Telegram bot orqali tasdiqlash ekrani. Eski SMS
/// kod kiritish ekrani (OtpVerificationScreen) o'rnini bosadi:
/// foydalanuvchi kod kiritmaydi, shunchaki Telegram'ga o'tib "Start"
/// bosadi, ilova esa fonda holatni kuzatib, tasdiqlangach avtomatik
/// davom etadi.
///
/// Register va "parolni unutdim" oqimlari ikkalasi ham shu ekranni
/// ishlatadi — [onVerified] callback orqali chaqiruvchi ekranga
/// signal beriladi.
class TelegramVerifyScreen extends ConsumerStatefulWidget {
  /// "+998901234567" formatida, foydalanuvchiga ko'rsatish uchun.
  final String phoneE164;
  final String token;
  final Future<void> Function() onVerified;

  const TelegramVerifyScreen({
    super.key,
    required this.phoneE164,
    required this.token,
    required this.onVerified,
  });

  @override
  ConsumerState<TelegramVerifyScreen> createState() =>
      _TelegramVerifyScreenState();
}

class _TelegramVerifyScreenState extends ConsumerState<TelegramVerifyScreen> {
  StreamSubscription<VerificationStatus>? _subscription;
  bool _isOpeningTelegram = false;
  bool _isCompleting = false;
  String? _errorText;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _startPolling() {
    final repo = ref.read(phoneVerificationRepositoryProvider);
    _subscription = repo.pollStatus(widget.token).listen((status) async {
      if (!mounted) return;
      switch (status) {
        case VerificationStatus.verified:
          setState(() => _isCompleting = true);
          try {
            await widget.onVerified();
          } catch (e) {
            if (mounted) {
              setState(() {
                _isCompleting = false;
                // Haqiqiy xato matnini ko'rsatamiz (masalan Firebase'ning
                // aniq kodi) — avval bu yerda doim bir xil umumiy xabar
                // ko'rsatilardi, shuning uchun production'da ro'yxatdan
                // o'tish nega muvaffaqiyatsiz tugaganini bilib bo'lmasdi.
                _errorText = switch (e) {
                  AuthException(:final message) => message,
                  PhoneVerificationException(:final message) => message,
                  _ => 'Xatolik yuz berdi. Qayta urinib ko\'ring',
                };
              });
            }
          }
          break;
        case VerificationStatus.expired:
          setState(() => _expired = true);
          break;
        case VerificationStatus.notFound:
        case VerificationStatus.pending:
          break;
      }
    });
  }

  Future<void> _openTelegram() async {
    setState(() {
      _isOpeningTelegram = true;
      _errorText = null;
    });
    try {
      final repo = ref.read(phoneVerificationRepositoryProvider);
      await repo.openTelegramBot(widget.token);
    } on PhoneVerificationException catch (e) {
      if (mounted) setState(() => _errorText = e.message);
    } finally {
      if (mounted) setState(() => _isOpeningTelegram = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF2AABEE).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsFill.telegramLogo,
                    size: 44, color: Color(0xFF2AABEE)),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Raqamingizni tasdiqlang',
                style: context.titleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${widget.phoneE164} raqamini tasdiqlash uchun Telegram '
                'botimizni oching va "Start" tugmasini bosing',
                style: context.secondaryStyle.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              if (_isCompleting) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.md),
                Text('Tasdiqlandi! Davom etilmoqda...',
                    style: context.bodyStyle),
              ] else if (_expired) ...[
                Text(
                  'Havola muddati tugadi. Iltimos, ortga qaytib qayta '
                  'urinib ko\'ring',
                  style: context.bodyStyle.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isOpeningTelegram ? null : _openTelegram,
                    icon: const Icon(PhosphorIconsFill.paperPlaneTilt, size: 18),
                    label: Text(
                      _isOpeningTelegram
                          ? 'Ochilmoqda...'
                          : 'Telegram\'da tasdiqlash',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Tasdiqlanishini kutmoqdamiz...',
                  style: context.captionStyle,
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  _errorText!,
                  style: context.bodyStyle.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
