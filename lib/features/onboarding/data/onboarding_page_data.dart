import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Onboarding yuqorisidagi "preview" ro'yxatidagi bitta qator.
class PreviewItem {
  final IconData icon;
  final String label;

  /// GPT'da generatsiya qilingan rangli 3D belgi — berilsa, oddiy
  /// Material ikonkasi o'rniga shu ishlatiladi.
  final String? imagePath;

  const PreviewItem({
    required this.icon,
    required this.label,
    this.imagePath,
  });
}

List<PreviewItem> onboardingPreviewItems(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    PreviewItem(
      icon: Icons.campaign_rounded,
      label: l10n.previewAnnouncements,
      imagePath: 'assets/images/onboarding_icons/announcements.png',
    ),
    PreviewItem(
      icon: Icons.event_rounded,
      label: l10n.previewEvents,
      imagePath: 'assets/images/onboarding_icons/events.png',
    ),
    PreviewItem(
      icon: Icons.chat_bubble_rounded,
      label: l10n.previewRequests,
      imagePath: 'assets/images/onboarding_icons/requests.png',
    ),
    PreviewItem(
      icon: Icons.groups_rounded,
      label: l10n.previewNeighbors,
      imagePath: 'assets/images/onboarding_icons/neighbors.png',
    ),
  ];
}

/// Bitta onboarding "bosqichi"ning kontenti — onboardingPreviewItems
/// bilan индекс bo'yicha bir xil tartibda (1:1 mos).
class OnboardingPageData {
  /// Fon surati — haqiqiy, litsenziyalangan (CC0, Met Museum / Wikimedia
  /// Commons) o'zbek to'qimachilik namunasi (`assets/images/patterns/`).
  /// Sof rangli gradient o'rniga — ilova o'z madaniy kontekstiga
  /// bog'langan, hech qanday umumiy "shablon" fonga o'xshamaydi.
  final String image;

  /// Surat ustidagi rangli parda (matn o'qilishi uchun pastda quyuqroq)
  /// — bosqichning o'z aksent rangi bilan mos.
  final Color tint;

  /// Surat qaysi qismi ko'rsatilishini boshqaradi (portret suratlarda
  /// bosh/asos kabi keraksiz qismlarni chetlab o'tish uchun).
  final Alignment imageAlignment;

  final String title;
  final String description;

  const OnboardingPageData({
    required this.image,
    required this.tint,
    required this.title,
    required this.description,
    this.imageAlignment = Alignment.center,
  });
}

/// 5 ta bosqich: 0-Xush kelibsiz (tanishtiruv, `onboardingPreviewItems`da
/// mos qatori yo'q), 1-E'lonlar, 2-Tadbirlar, 3-Murojaatlar, 4-Qo'shnilar
/// — preview ro'yxati bilan indeks 1 surilgan holda mos keladi
/// (`onboarding_screen.dart`dagi `_GlassPreviewStack` shuni hisobga oladi).
List<OnboardingPageData> onboardingPages(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return [
    OnboardingPageData(
      image: 'assets/images/onboarding_backgrounds/welcome.png',
      tint: const Color(0xFF0752EB),
      title: l10n.onboardingWelcomeTitle,
      description: l10n.onboardingWelcomeDescription,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_backgrounds/announcements.png',
      tint: const Color(0xFF2F5BFF),
      title: l10n.onboardingAnnouncementsTitle,
      description: l10n.onboardingAnnouncementsDescription,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_backgrounds/events.png',
      tint: const Color(0xFFF2994A),
      title: l10n.onboardingEventsTitle,
      description: l10n.onboardingEventsDescription,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_backgrounds/requests.png',
      tint: const Color(0xFF27AE60),
      title: l10n.onboardingRequestsTitle,
      description: l10n.onboardingRequestsDescription,
    ),
    OnboardingPageData(
      image: 'assets/images/onboarding_backgrounds/neighbors.png',
      tint: const Color(0xFF9254DE),
      title: l10n.onboardingNeighborsTitle,
      description: l10n.onboardingNeighborsDescription,
    ),
  ];
}