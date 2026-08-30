import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../l10n/app_localizations.dart';
import '../data/mahalla_repository.dart';
import '../../../core/widgets/app_alert.dart';

/// 8. QR NATIJA (Mahalla topildi) ekrani.
class QrResultScreen extends ConsumerStatefulWidget {
  final MahallaInfo mahalla;

  const QrResultScreen({super.key, required this.mahalla});

  @override
  ConsumerState<QrResultScreen> createState() => _QrResultScreenState();
}

class _QrResultScreenState extends ConsumerState<QrResultScreen> {
  bool _isConfirming = false;

  Future<void> _confirm() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isConfirming = true);
    try {
      await ref
          .read(mahallaRepositoryProvider)
          .attachUserToMahalla(widget.mahalla.id);
      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      showAppAlert(context, l10n.confirmError, kind: AppAlertKind.error);
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            children: [
              const Spacer(),

              // Skanerlangan QR ko'rinishi (dekorativ)
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? AppColors.darkSurface
                      : const Color(0xFFF0F4F8),
                  borderRadius: AppRadius.mdAll,
                ),
                child: const Icon(
                  PhosphorIconsFill.qrCode,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              AppCard(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(PhosphorIconsBold.check,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(l10n.mahallaFoundLabel, style: context.secondaryStyle),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(widget.mahalla.name, style: context.titleStyle),
                    if (widget.mahalla.district.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(widget.mahalla.district, style: context.secondaryStyle),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _isConfirming ? null : _confirm,
                child: _isConfirming
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(l10n.confirmButton),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go(AppRoutes.qrScan),
                child: Text(l10n.rescanButton),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}