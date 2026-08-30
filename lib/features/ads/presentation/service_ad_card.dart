import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/phone_format.dart';
import '../../../l10n/app_localizations.dart';
import '../data/service_ad_repository.dart';

/// Kichik, bir qatorli xizmat reklamasi.
///
/// Ataylab past profilli: baland kartochka emas, rasm yo'q, animatsiya
/// yo'q. Premium foydalanuvchida [currentServiceAdProvider] `null`
/// qaytargani uchun widget o'zini butunlay yashiradi — ya'ni bo'sh joy
/// ham qoldirmaydi.
class ServiceAdCard extends ConsumerWidget {
  const ServiceAdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ad = ref.watch(currentServiceAdProvider);
    if (ad == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: ad.phone.isEmpty
            ? null
            : () => launchUrl(Uri.parse('tel:${ad.phone}')),
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.isDarkMode
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: AppRadius.smAll,
            border: Border.all(color: context.borderColor),
          ),
          child: Row(
            children: [
              Icon(PhosphorIconsFill.storefront,
                  size: 18, color: context.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            ad.title,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyStyle
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        // "Reklama" belgisi — foydalanuvchi buni oddiy
                        // kontentdan ajrata olishi shart.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: context.textMuted.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.adLabel,
                            style: context.captionStyle.copyWith(
                                fontSize: 9.5, color: context.textMuted),
                          ),
                        ),
                      ],
                    ),
                    if (ad.description.isNotEmpty)
                      Text(
                        ad.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.captionStyle
                            .copyWith(color: context.textMuted),
                      ),
                  ],
                ),
              ),
              if (ad.phone.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(PhosphorIconsFill.phone,
                    size: 16, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reklama tafsilotlari (nomi, tavsifi, telefon) — kartochka bosilganda
/// emas, "Xizmatlar" ekranida to'liqroq ko'rsatish uchun.
class ServiceAdDetailTile extends StatelessWidget {
  final ServiceAd ad;
  const ServiceAdDetailTile({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(PhosphorIconsFill.storefront),
      title: Text(ad.title),
      subtitle: Text(
        [ad.ownerName, if (ad.phone.isNotEmpty) formatPhoneNumber(ad.phone)]
            .where((e) => e.isNotEmpty)
            .join(' · '),
      ),
      trailing: ad.phone.isEmpty
          ? null
          : IconButton(
              icon: const Icon(PhosphorIconsFill.phone),
              onPressed: () => launchUrl(Uri.parse('tel:${ad.phone}')),
            ),
    );
  }
}
