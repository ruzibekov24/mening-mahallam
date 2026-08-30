import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/settings_tile.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/data/home_repository.dart';
import '../../notifications/data/notification_repository.dart';

/// Bildirishnoma turlari bo'yicha sozlash ekrani — har bir tur uchun
/// alohida yoqish/o'chirish. Bu yerdagi tanlov faqat SERVER push
/// yuborishini boshqaradi (`NotificationRepository.sendToUser`/
/// `sendToMahalla`) — ilova ichidagi bildirishnomalar ro'yxati va
/// Sozlamalar ekranidagi umumiy "Bildirishnomalar" kaliti
/// (`notification_settings_provider.dart`, qurilma darajasidagi
/// ko'rsatish o'chirgichi) bunga bog'liq emas. Ikkalasi birga
/// ishlaydi: qurilma kaliti o'chiq bo'lsa, hech qanday push
/// ko'rsatilmaydi (bu yerdagi sozlamalardan qat'iy nazar);
/// yoqilgan bo'lsa, aynan shu ekrandagi tanlovlar qaysi TURDAGI
/// bildirishnomalar serverdan umuman yuborilishini belgilaydi.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xs, AppSpacing.xl, AppSpacing.xxxl),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(PhosphorIconsRegular.arrowLeft),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(l10n.notificationPreferencesTitle,
                    style: context.titleStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            profileAsync.when(
              data: (profile) {
                if (profile == null) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        l10n.notificationPreferencesSectionHeader
                            .toUpperCase(),
                        style: context.captionStyle),
                    const SizedBox(height: AppSpacing.sm),
                    SettingsCard(
                      children: [
                        _PrefTile(
                          icon: PhosphorIconsFill.megaphone,
                          iconColor: AppAccents.announcements,
                          title: l10n.notificationTypeAnnouncementLabel,
                          typeKey: NotificationType.newAnnouncement.storageValue,
                          enabled: profile.isNotificationEnabled(
                              NotificationType.newAnnouncement.storageValue),
                          onChanged: (value) => ref
                              .read(homeRepositoryProvider)
                              .updateNotificationPref(
                                typeKey: NotificationType
                                    .newAnnouncement.storageValue,
                                enabled: value,
                              ),
                        ),
                        _PrefTile(
                          icon: PhosphorIconsFill.calendarPlus,
                          iconColor: AppAccents.events,
                          title: l10n.notificationTypeEventLabel,
                          typeKey: NotificationType.newEvent.storageValue,
                          enabled: profile.isNotificationEnabled(
                              NotificationType.newEvent.storageValue),
                          onChanged: (value) => ref
                              .read(homeRepositoryProvider)
                              .updateNotificationPref(
                                typeKey:
                                    NotificationType.newEvent.storageValue,
                                enabled: value,
                              ),
                        ),
                        _PrefTile(
                          icon: PhosphorIconsFill.chartBar,
                          iconColor: AppAccents.neighbors,
                          title: l10n.notificationTypePollLabel,
                          typeKey: NotificationType.newPoll.storageValue,
                          enabled: profile.isNotificationEnabled(
                              NotificationType.newPoll.storageValue),
                          onChanged: (value) => ref
                              .read(homeRepositoryProvider)
                              .updateNotificationPref(
                                typeKey:
                                    NotificationType.newPoll.storageValue,
                                enabled: value,
                              ),
                        ),
                        _PrefTile(
                          icon: PhosphorIconsFill.chatCircleText,
                          iconColor: AppAccents.requests,
                          title: l10n.notificationTypeMessageLabel,
                          typeKey: NotificationType.newMessage.storageValue,
                          enabled: profile.isNotificationEnabled(
                              NotificationType.newMessage.storageValue),
                          onChanged: (value) => ref
                              .read(homeRepositoryProvider)
                              .updateNotificationPref(
                                typeKey:
                                    NotificationType.newMessage.storageValue,
                                enabled: value,
                              ),
                        ),
                        _PrefTile(
                          icon: PhosphorIconsFill.clipboardText,
                          iconColor: AppColors.primary,
                          title: l10n.notificationTypeRequestStatusLabel,
                          typeKey: NotificationType
                              .requestStatusChanged.storageValue,
                          enabled: profile.isNotificationEnabled(
                              NotificationType
                                  .requestStatusChanged.storageValue),
                          onChanged: (value) => ref
                              .read(homeRepositoryProvider)
                              .updateNotificationPref(
                                typeKey: NotificationType
                                    .requestStatusChanged.storageValue,
                                enabled: value,
                              ),
                          showDivider: false,
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String typeKey;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _PrefTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.typeKey,
    required this.enabled,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      trailing: Switch(
        value: enabled,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
      showDivider: showDivider,
    );
  }
}
