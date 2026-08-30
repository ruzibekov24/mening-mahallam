import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// E'lon/tadbir/murojaatni o'chirishdan oldin so'raladigan umumiy
/// tasdiqlash oynasi. `itemTitle` — o'chirilayotgan narsaning sarlavhasi
/// (xabarda ko'rsatish uchun). `true` qaytarsa — foydalanuvchi tasdiqladi.
Future<bool> confirmDelete(BuildContext context, {required String itemTitle}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
      icon: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(PhosphorIconsFill.trash, color: AppColors.danger),
      ),
      title: Text(l10n.deleteItemConfirmTitle),
      content: Text(l10n.deleteItemConfirmMessage(itemTitle)),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          ),
          child: Text(l10n.deleteButton),
        ),
      ],
    ),
  );
  return confirmed == true;
}
