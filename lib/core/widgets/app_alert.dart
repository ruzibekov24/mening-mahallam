import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Xabar turi — ikonka va rangni belgilaydi.
enum AppAlertKind { success, error, info }

/// Ilova ichidagi xabarlar uchun YAGONA usul.
///
/// Ilgari hamma xabar `SnackBar` orqali ekran PASTIDAN chiqardi.
/// Uchta muammosi bor edi:
///
///   * pastki navigatsiya paneli ustiga tushib, uni to'sib qo'yardi;
///   * bir necha soniyada o'zi yo'qolardi — foydalanuvchi o'qishga
///     ulgurmasligi mumkin edi, ayniqsa uzun matnda va ayniqsa
///     keksalar uchun;
///   * "parolingiz yangilandi" kabi MUHIM tasdiqlar ham xuddi
///     ahamiyatsiz eslatmalar bilan bir xil ko'rinardi.
///
/// Endi xabar ekran MARKAZIDA, "OK" tugmasi bilan chiqadi: u o'zi
/// yo'qolmaydi va foydalanuvchi o'qiganini bilib turamiz.
Future<void> showAppAlert(
  BuildContext context,
  String message, {
  AppAlertKind kind = AppAlertKind.info,
  String? title,
}) {
  final l10n = AppLocalizations.of(context);

  final (IconData icon, Color color) = switch (kind) {
    AppAlertKind.success => (PhosphorIconsFill.checkCircle, AppAccents.requests),
    AppAlertKind.error => (PhosphorIconsFill.warningCircle, AppColors.danger),
    AppAlertKind.info => (PhosphorIconsFill.info, AppColors.primary),
  };

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 26),
      ),
      title: title == null
          ? null
          : Text(title, textAlign: TextAlign.center),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: dialogContext.bodyStyle,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              shape:
                  const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            ),
            child: Text(l10n.okButton),
          ),
        ),
      ],
    ),
  );
}
