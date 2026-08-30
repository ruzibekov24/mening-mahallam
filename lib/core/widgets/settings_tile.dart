import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'animated_ui.dart';

/// Sozlamalar uslubidagi qator ro'yxatini o'rovchi karta.
///
/// Auditdan oldin `_SettingsCard`/`_SettingsTile` `settings_screen.dart`
/// va `privacy_security_screen.dart`da bayt-ma-bayt bir xil ko'chirilgan
/// edi. Endi manba bitta.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }
}

/// Sozlamalar ekranidagi bitta qator: chapda rangli ikonka, o'rtada
/// sarlavha + ixtiyoriy tavsif, o'ngda trailing (switch, matn yoki
/// o'q ikonkasi).
class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;

  /// Tavsif emas, JORIY QIYMAT ko'rsatilayotganini bildiradi
  /// (masalan "Til — O'zbekcha"). Bunday qatorlarda qiymat brend
  /// rangida chiziladi: shunda foydalanuvchi tanlangan variantni
  /// tushuntirish matnidan bir qarashda ajratadi.
  final bool subtitleIsValue;

  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.subtitleIsValue = false,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 13,
          ),
          decoration: showDivider
              ? BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: context.borderColor, width: 0.5),
                  ),
                )
              : null,
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.bodyStyle.copyWith(
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: subtitleIsValue
                            ? context.captionStyle.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              )
                            : context.captionStyle,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(PhosphorIconsRegular.caretRight,
                    size: 18, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
