import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kNotificationsEnabledKey = 'notifications_enabled';

/// Bildirishnomalar yoqilgan/o'chirilganligini eslab qoladi.
///
/// Eslatma: bu faqat ilova ichidagi holatni saqlaydi (push xabar
/// yuborish infratuzilmasi hali yo'q). Real push bildirishnomalar
/// alohida katta ish sifatida kelajakda qo'shiladi.
class NotificationSettingsNotifier extends StateNotifier<bool> {
  NotificationSettingsNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kNotificationsEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsEnabledKey, enabled);
  }
}

final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, bool>((ref) {
  return NotificationSettingsNotifier();
});
