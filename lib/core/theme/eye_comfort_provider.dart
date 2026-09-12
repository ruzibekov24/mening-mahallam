import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kEyeComfortKey = 'app_eye_comfort_enabled';

/// "Ko'z himoyasi" (Samsungdagi "Eye comfort shield" bilan bir xil
/// g'oya) — yoqilsa, butun ilova ekraniga yumshoq, issiq (kamroq
/// ko'k) rang filtri qo'llanadi. Telefon o'zining tizim darajasidagi
/// "Night Light"/"Eye comfort"idan farqli — bu FAQAT shu ilova
/// ichida ishlaydi, chunki ilova tizim darajasidagi filtrni
/// yoqolmaydi/o'zgartira olmaydi.
class EyeComfortNotifier extends StateNotifier<bool> {
  EyeComfortNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kEyeComfortKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEyeComfortKey, value);
  }
}

final eyeComfortProvider =
    StateNotifierProvider<EyeComfortNotifier, bool>((ref) {
  return EyeComfortNotifier();
});
