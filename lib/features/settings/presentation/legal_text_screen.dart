import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/liquid_glass.dart';

/// "Foydalanish shartlari" va "Maxfiylik siyosati" uchun umumiy
/// ko'rinishdagi statik matn ekrani.
///
/// MUHIM: `body` matni dastlabki (namunaviy) versiya — haqiqiy
/// nashrdan oldin huquqshunos tomonidan tasdiqlanishi tavsiya
/// etiladi (l10n fayllaridagi `termsBody`/`privacyPolicyBody`ga
/// qarang).
class LegalTextScreen extends StatelessWidget {
  final String title;
  final String body;

  const LegalTextScreen({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: Text(title, style: context.titleStyle)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              body,
              style: context.bodyStyle.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
