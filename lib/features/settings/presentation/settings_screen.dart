import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/router/app_page_route.dart';
import '../../../core/app_version.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/text_scale_provider.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../../core/utils/phone_format.dart';
import '../../../core/widgets/animated_ui.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../../feedback/presentation/feedback_screen.dart';
import '../../home/data/home_repository.dart';
import '../../home/presentation/members_management_screen.dart';
import '../../ads/presentation/ad_management_screen.dart';
import '../../language/data/language_repository.dart';
import '../../language/presentation/language_screen.dart';
import '../../premium/presentation/premium_config_screen.dart';
import '../../premium/presentation/premium_requests_screen.dart';
import '../../assistant/presentation/assistant_chats_list_screen.dart';
import '../../premium/presentation/premium_screen.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../profile/presentation/help_screen.dart';
import '../../qr/presentation/qr_scan_screen.dart';
import '../data/account_deletion_repository.dart';
import '../data/notification_settings_provider.dart';
import 'legal_text_screen.dart';
import 'notification_preferences_screen.dart';
import 'privacy_security_screen.dart';
import '../../../core/widgets/app_alert.dart';

/// 14. SOZLAMALAR ekrani.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmChangeMahalla(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.pillAll),
        icon: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            PhosphorIconsFill.qrCode,
            color: AppColors.primary,
          ),
        ),
        title: Text(l10n.changeMahallaTitle),
        content: Text(l10n.changeMahallaMessage),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smAll,
              ),
            ),
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      AppPageRoute.push(context, const QrScanScreen());
    }
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
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
          child: const Icon(
            PhosphorIconsFill.warning,
            color: AppColors.danger,
          ),
        ),
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmMessage),
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
              shape: const RoundedRectangleBorder(
                borderRadius: AppRadius.smAll,
              ),
            ),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Ilgari shu yerda "tez orada" xabari chiqardi — Maxfiylik
    // siyosatida ma'lumotlar o'chiriladi deb va'da berilganiga
    // qaramay hech narsa sodir bo'lmasdi. Endi haqiqiy so'rov
    // yaratiladi va super adminga boradi.
    final repo = AccountDeletionRepository();
    try {
      if (await repo.hasPendingRequest()) {
        if (!context.mounted) return;
        await showAppAlert(context, l10n.deleteAccountAlreadyPending);
        return;
      }
      await repo.submitRequest();
      if (!context.mounted) return;
      await showAppAlert(context, l10n.deleteAccountRequested,
          kind: AppAlertKind.success);
    } catch (_) {
      if (!context.mounted) return;
      await showAppAlert(context, l10n.unexpectedError,
          kind: AppAlertKind.error);
    }
  }

  void _clearCache(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Ilgari faqat "Kesh tozalandi" deb yozardi, lekin hech narsa
    // tozalanmasdi. Endi haqiqatan ham xotiradagi rasm keshi
    // bo'shatiladi — avatarlar/bannerlar eskirib qolganda yoki ilova
    // ko'p xotira egallaganda yordam beradi.
    //
    // Diskdagi keshni tozalash uchun alohida paket (masalan
    // `flutter_cache_manager`) kerak bo'lardi; ataylab qo'shilmadi —
    // hozir ilova ishga tushishi bilan bog'liq muammo ustida
    // ishlanmoqda va yangi bog'liqlik kiritilmayapti.
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    showAppAlert(context, l10n.cacheClearedMessage);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentThemeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationSettingsProvider);
    final currentTextScale = ref.watch(textScaleProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, 100),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.settingsTitle, style: context.titleStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            // Profil kartasi — Sozlamalarni shaxsiylashtiradi, "Mening
            // ma'lumotlarim"ga tez kirish imkonini beradi.
            profileAsync.when(
              data: (profile) => _ProfileCard(
                profile: profile,
                onTap: () =>
                    AppPageRoute.push(context, const EditProfileScreen()),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.sectionMahalla.toUpperCase(),
                style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.buildings,
                  iconColor: AppAccents.announcements,
                  title: l10n.currentMahalla,
                  subtitle: profileAsync.when(
                    data: (profile) => profile?.mahallaId ?? l10n.notConnected,
                    loading: () => '...',
                    error: (_, __) => l10n.unknownValue,
                  ),
                  trailing: TextButton(
                    onPressed: () => _confirmChangeMahalla(context),
                    child: Text(l10n.changeButton),
                  ),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Premium — hamma uchun ko'rinadi. Obuna faol bo'lsa
            // tugash sanasi, aks holda taklif ko'rsatiladi.
            profileAsync.when(
              data: (profile) {
                final active = profile?.isPremiumActive == true;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.crown,
                          iconColor: const Color(0xFFE0A526),
                          title: l10n.premiumTitle,
                          subtitle: active
                              ? l10n.premiumActiveTitle
                              : l10n.premiumSettingSubtitle,
                          onTap: () =>
                              AppPageRoute.push(context, const PremiumScreen()),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Faqat super admin uchun — premium to'lovlarini tasdiqlash.
            profileAsync.when(
              data: (profile) {
                if (profile?.role.isSuperAdmin != true) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.receipt,
                          iconColor: AppColors.danger,
                          title: l10n.premiumRequestsTitle,
                          onTap: () => AppPageRoute.push(
                              context, const PremiumRequestsScreen()),
                        ),
                        // To'lov rekvizitlari — kartani reliz
                        // chiqarmasdan o'zgartirish uchun.
                        SettingsTile(
                          icon: PhosphorIconsFill.creditCard,
                          iconColor: AppColors.primary,
                          title: l10n.premiumConfigTitle,
                          onTap: () => AppPageRoute.push(
                              context, const PremiumConfigScreen()),
                        ),
                        SettingsTile(
                          icon: PhosphorIconsFill.storefront,
                          iconColor: AppAccents.events,
                          title: l10n.adManagementTitle,
                          onTap: profile?.mahallaId == null
                              ? null
                              : () => AppPageRoute.push(
                                  context,
                                  AdManagementScreen(
                                      mahallaId: profile!.mahallaId!)),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Faqat rais uchun — boshqaruv bo'limi.
            profileAsync.when(
              data: (profile) {
                final canManage = profile?.role.canManageMembers == true &&
                    profile?.mahallaId != null;
                if (!canManage) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sectionManagement.toUpperCase(),
                        style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsCard(
                      children: [
                        SettingsTile(
                          icon: PhosphorIconsFill.usersThree,
                          iconColor: AppAccents.neighbors,
                          title: l10n.membersManagementTitle,
                          onTap: () => AppPageRoute.push(
                              context,
                              MembersManagementScreen(
                                mahallaId: profile!.mahallaId!,
                              )),
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            Text(l10n.sectionGeneral.toUpperCase(),
                style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.translate,
                  iconColor: AppAccents.neighbors,
                  title: l10n.languageSettingTitle,
                  subtitle: currentLanguage.label,
                  subtitleIsValue: true,
                  onTap: () => _showLanguagePicker(context, ref),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.moon,
                  iconColor: AppAccents.announcements,
                  title: l10n.appearanceSettingTitle,
                  subtitle: currentThemeMode.label,
                  subtitleIsValue: true,
                  onTap: () => _showThemePicker(context, ref),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.bell,
                  iconColor: AppAccents.events,
                  title: l10n.notificationsMenuItem,
                  trailing: Switch(
                    value: notificationsEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) => ref
                        .read(notificationSettingsProvider.notifier)
                        .setEnabled(value),
                  ),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.bellRinging,
                  iconColor: AppAccents.requests,
                  title: l10n.notificationPreferencesTitle,
                  subtitle: l10n.notificationPreferencesSubtitle,
                  onTap: () => AppPageRoute.push(
                      context, const NotificationPreferencesScreen()),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.textAa,
                  iconColor: AppAccents.requests,
                  title: l10n.textSizeSettingTitle,
                  subtitle: currentTextScale.label,
                  subtitleIsValue: true,
                  onTap: () => _showTextScalePicker(context, ref),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.sparkle,
                  iconColor: AppColors.primary,
                  title: l10n.assistantScreenTitle,
                  onTap: () => AppPageRoute.push(
                      context, const AssistantChatsListScreen()),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.sectionPrivacy.toUpperCase(),
                style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.shield,
                  iconColor: AppAccents.announcements,
                  title: l10n.privacySecurityTitle,
                  subtitle: l10n.privacySecuritySubtitle,
                  onTap: () =>
                      AppPageRoute.push(context, const PrivacySecurityScreen()),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.trash,
                  iconColor: AppColors.danger,
                  title: l10n.deleteAccountTitle,
                  titleColor: AppColors.danger,
                  onTap: () => _confirmDeleteAccount(context, ref),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.sectionDataStorage.toUpperCase(),
                style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.broom,
                  iconColor: AppAccents.requests,
                  title: l10n.clearCacheTitle,
                  subtitle: l10n.clearCacheSubtitle,
                  onTap: () => _clearCache(context),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.sectionSupport.toUpperCase(),
                style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.question,
                  iconColor: AppAccents.requests,
                  title: l10n.helpMenuItem,
                  onTap: () => AppPageRoute.push(context, const HelpScreen()),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.star,
                  iconColor: AppAccents.events,
                  title: l10n.feedbackTitle,
                  onTap: () =>
                      AppPageRoute.push(context, const FeedbackScreen()),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            Text(l10n.sectionAbout.toUpperCase(), style: context.captionStyle),
            const SizedBox(height: AppSpacing.sm),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: PhosphorIconsFill.info,
                  iconColor: AppAccents.announcements,
                  title: l10n.versionLabel,
                  subtitle: kAppVersion,
                  subtitleIsValue: true,
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.code,
                  iconColor: AppAccents.neighbors,
                  title: l10n.developerTitle,
                  subtitle: l10n.developerSubtitle,
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.fileText,
                  iconColor: AppAccents.requests,
                  title: l10n.termsTitle,
                  onTap: () => AppPageRoute.push(
                      context,
                      LegalTextScreen(
                        title: l10n.termsTitle,
                        body: l10n.termsBody,
                      )),
                ),
                SettingsTile(
                  icon: PhosphorIconsFill.lockKey,
                  iconColor: AppAccents.events,
                  title: l10n.privacyPolicyTitle,
                  onTap: () => AppPageRoute.push(
                      context,
                      LegalTextScreen(
                        title: l10n.privacyPolicyTitle,
                        body: l10n.privacyPolicyBody,
                      )),
                  showDivider: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    // Pastki varaq yopilgach ham foydalanish uchun — ichkaridagi
    // `Consumer`ning o'z `context` parametri (bir xil nom bilan) shu
    // tashqi context'ni "soyalab" qo'yadi, varaq yopilishi bilan u
    // unmount bo'ladi. Tasdiqlash xabari esa Sozlamalar ekranining
    // O'ZIDA (varaqdan tashqarida) ko'rsatilishi kerak.
    final screenContext = context;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(languageProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                        AppSpacing.xl, AppSpacing.xl, AppSpacing.md),
                    child: Text(l10n.languageSettingTitle,
                        style: sheetContext.cardTitleStyle),
                  ),
                  ...AppLanguage.values.map((lang) {
                    final selected = current == lang;
                    return ListTile(
                      // Bayroq — tilni o'qimasdan tanib olish uchun.
                      // Kirill yozuvidagi o'zbek tili ham o'zbek
                      // bayrog'ini oladi: bu bir tilning ikki yozuvi.
                      // Bayroq chizib beriladi (rasm fayli emas) —
                      // `assets/images/flags/` ichidagi fayllarning
                      // kengaytmasi mazmuniga mos emas: `uz.png`
                      // aslida WebP. Chizilgan versiya bunga
                      // bog'liq emas va Tilni tanlash ekranidagi
                      // bilan bir xil manbadan keladi.
                      leading: Container(
                        width: 36,
                        height: 24,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                        ),
                        child: LanguageFlag(language: lang),
                      ),
                      title: Text(
                        lang.label,
                        style: sheetContext.bodyStyle.copyWith(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(lang.shortCode,
                          style: sheetContext.captionStyle),
                      trailing: selected
                          ? const Icon(PhosphorIconsFill.checkCircle,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        final wasDifferent = current != lang;
                        ref.read(languageProvider.notifier).select(lang);
                        Navigator.of(sheetContext).pop();
                        // Til o'zgarishi butun ilova bo'ylab darhol
                        // (animatsiyasiz) qo'llanadi — `MaterialApp`
                        // ildizini `AnimatedSwitcher` bilan o'rash
                        // navigatsiya holatini (Router/Navigator
                        // daraxtini) buzish xavfini keltirib chiqarardi.
                        // Shuning uchun o'zgarish sodir bo'lganini
                        // tasdiqlovchi qisqa xabar bilan cheklanamiz —
                        // ilovaning boshqa joylarida ishlatiladigan
                        // `showAppAlert` naqshi bilan bir xil.
                        if (wasDifferent && screenContext.mounted) {
                          showAppAlert(
                            screenContext,
                            AppLocalizations.of(screenContext)
                                .languageUpdatedMessage,
                            kind: AppAlertKind.success,
                          );
                        }
                      },
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Mavzu tanlash — matnli ro'yxat emas, KO'RINISHNING O'ZI.
  ///
  /// Ilgari bu "Yorug' / Tungi / Tizim" degan uch qatorli ro'yxat edi.
  /// Rang mavzusi — ko'z bilan ko'riladigan narsa, shuning uchun uni
  /// so'z bilan tasvirlash o'rniga kichik namuna ko'rsatiladi (iOS
  /// "Appearance" bo'limidagi kabi): foydalanuvchi tanlamasdan oldin
  /// nima bo'lishini ko'radi.
  void _showThemePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(themeModeProvider);
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.appearanceSettingTitle,
                        style: sheetContext.cardTitleStyle),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemePreviewOption(
                            mode: ThemeMode.light,
                            selected: current == ThemeMode.light,
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .select(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _ThemePreviewOption(
                            mode: ThemeMode.dark,
                            selected: current == ThemeMode.dark,
                            onTap: () => ref
                                .read(themeModeProvider.notifier)
                                .select(ThemeMode.dark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Divider(height: 1, color: sheetContext.borderColor),
                    // "Tizim" alohida kalit sifatida — iOS'dagi
                    // "Automatic" bilan bir xil mantiq: yoqilsa
                    // telefon sozlamasiga ergashadi va yuqoridagi
                    // qo'lda tanlov kuchini yo'qotadi.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(ThemeMode.system.label),
                      subtitle: Text(l10n.appearanceSystemHint,
                          style: sheetContext.captionStyle),
                      value: current == ThemeMode.system,
                      activeThumbColor: AppColors.primary,
                      onChanged: (on) => ref
                          .read(themeModeProvider.notifier)
                          .select(on ? ThemeMode.system : ThemeMode.light),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Matn kattaligi — slayder + JONLI NAMUNA.
  ///
  /// Ilgari bu "Kichik / O'rta / Katta / Juda katta" ro'yxati edi:
  /// har bir variant o'z o'lchamida yozilgan bo'lsa ham, ilova
  /// matni qanday ko'rinishini faqat tanlab, oynani yopib, keyin
  /// ko'rish mumkin edi.
  ///
  /// Endi Samsung "Font size" bo'limidagi kabi: tepada namuna matn
  /// turadi, pastda slayder — surganingiz zahoti namuna o'zgaradi.
  /// Bu ayniqsa keksa foydalanuvchilar uchun muhim, chunki ular aynan
  /// shu sozlamani ko'p ishlatadi.
  void _showTextScalePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: Consumer(
            builder: (context, ref, _) {
              final current = ref.watch(textScaleProvider);
              final index = AppTextScale.values.indexOf(current);
              final factor = current.factor;

              return Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.textSizeSettingTitle,
                        style: sheetContext.cardTitleStyle),
                    const SizedBox(height: AppSpacing.lg),

                    // Namuna — ilovaning haqiqiy matn uslublarida,
                    // tanlangan koeffitsiyent qo'llangan holda.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: sheetContext.surfaceColor,
                        borderRadius: AppRadius.mdAll,
                        border: Border.all(color: sheetContext.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.textSizePreviewTitle,
                            style: sheetContext.cardTitleStyle.copyWith(
                              fontSize: 15 * factor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.textSizePreviewBody,
                            style: sheetContext.secondaryStyle.copyWith(
                              fontSize: 13 * factor,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    Row(
                      children: [
                        Text('A',
                            style: TextStyle(
                                fontSize: 13,
                                color: sheetContext.textSecondary)),
                        Expanded(
                          child: Slider(
                            value: index.toDouble(),
                            min: 0,
                            max: (AppTextScale.values.length - 1).toDouble(),
                            divisions: AppTextScale.values.length - 1,
                            label: current.label,
                            activeColor: AppColors.primary,
                            onChanged: (v) => ref
                                .read(textScaleProvider.notifier)
                                .select(AppTextScale.values[v.round()]),
                          ),
                        ),
                        Text('A',
                            style: TextStyle(
                                fontSize: 24,
                                color: sheetContext.textSecondary)),
                      ],
                    ),
                    Center(
                      child: Text(current.label,
                          style: sheetContext.captionStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Sozlamalar tepasidagi profil kartasi — avatar, ism, telefon;
/// bosilganda "Mening ma'lumotlarim"ga o'tadi.
class _ProfileCard extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onTap;
  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentProfile = profile;
    final fullName = currentProfile == null
        ? ''
        : '${currentProfile.firstName} ${currentProfile.lastName}'.trim();
    final phone = currentProfile?.phone ?? '';

    return AppCard(
      radius: AppRadius.lg,
      onTap: onTap,
      child: Row(
        children: [
          UserAvatar.fromFullName(
            size: 52,
            fullName: fullName,
            photoUrl: currentProfile?.photoUrl,
            seed: currentProfile?.phone,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        fullName,
                        overflow: TextOverflow.ellipsis,
                        style: context.cardTitleStyle.copyWith(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (profile?.verifiedBadge == true) ...[
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(PhosphorIconsFill.sealCheck,
                          size: 16, color: AppColors.primary),
                    ],
                  ],
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(formatPhoneNumber(phone), style: context.secondaryStyle),
                ],
              ],
            ),
          ),
          Icon(PhosphorIconsRegular.caretRight, color: context.textSecondary),
        ],
      ),
    );
  }
}

/// Mavzu namunasi — kichik "telefon ekrani" chizmasi.
///
/// Haqiqiy skrinshot ishlatilmaydi: u ilova o'zgargan sari eskirib
/// qoladi va ikkita qo'shimcha rasm hajm oladi. Bu yerda namuna
/// mavzuning O'Z RANGLARIDAN chiziladi, ya'ni palitra o'zgarsa
/// namuna ham o'zi bilan o'zgaradi.
class _ThemePreviewOption extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePreviewOption({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = mode == ThemeMode.dark;
    final bg = dark ? AppColors.darkBg : AppColors.lightBg;
    final surface = dark ? AppColors.darkSurface : Colors.white;
    final text = dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final muted = dark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    return TapScale(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Column(
        children: [
          Container(
            height: 132,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: selected ? AppColors.primary : context.borderColor,
                width: selected ? 2.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sarlavha lentasi — ilovadagi GirihHeader'ga ishora.
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(height: 8),
                // Ikkita "kartochka" — ro'yxat ko'rinishi.
                for (var i = 0; i < 2; i++) ...[
                  Container(
                    height: 26,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 5,
                          width: 46,
                          decoration: BoxDecoration(
                            color: text,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 4,
                          width: 30,
                          decoration: BoxDecoration(
                            color: muted,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i == 0) const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(mode.label, style: context.bodyStyle),
          const SizedBox(height: 4),
          Icon(
            selected
                ? PhosphorIconsFill.checkCircle
                : PhosphorIconsRegular.circle,
            size: 20,
            color: selected ? AppColors.primary : context.textMuted,
          ),
        ],
      ),
    );
  }
}
