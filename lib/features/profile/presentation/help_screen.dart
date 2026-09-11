import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/app_alert.dart';

/// "Yordam" ekrani — FAQ ro'yxati va aloqa ma'lumotlari.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _call(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri(scheme: 'tel', path: '+998902400405');
    if (!await launchUrl(uri)) {
      if (context.mounted) {
        showAppAlert(context, l10n.callFailedMessage);
      }
    }
  }

  Future<void> _openTelegram(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final uri = Uri.parse('https://t.me/mahallam_support_bot');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        showAppAlert(context, l10n.telegramFailedMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final faqItems = [
      (l10n.faqQ1, l10n.faqA1),
      (l10n.faqQ2, l10n.faqA2),
      (l10n.faqQ3, l10n.faqA3),
      (l10n.faqQ4, l10n.faqA4),
      (l10n.faqQ5, l10n.faqA5),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Row(
              children: [
                const LiquidGlassBackButton(),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(l10n.helpMenuItem, style: context.titleStyle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(l10n.faqTitle, style: context.sectionStyle),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (final (question, answer) in faqItems)
                      ExpansionTile(
                        title: Text(question, style: context.cardTitleStyle),
                        childrenPadding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            answer,
                            style: context.secondaryStyle.copyWith(height: 1.4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(l10n.contactUsTitle, style: context.sectionStyle),
            const SizedBox(height: AppSpacing.md),
            AppListCard(
              icon: PhosphorIconsFill.phone,
              accent: AppAccents.requests,
              title: l10n.callUs,
              subtitle: '+998 90 240 04 05',
              onTap: () => _call(context),
              trailing: Icon(PhosphorIconsRegular.caretRight,
                  size: 18, color: context.textSecondary),
            ),
            AppListCard(
              icon: PhosphorIconsFill.telegramLogo,
              accent: AppAccents.announcements,
              title: l10n.telegramUs,
              subtitle: '@mahallam_support_bot',
              onTap: () => _openTelegram(context),
              margin: EdgeInsets.zero,
              trailing: Icon(PhosphorIconsRegular.caretRight,
                  size: 18, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
