import 'package:shared_preferences/shared_preferences.dart';

/// Ilova bo'ylab qo'llanma (tur) ko'rsatilgan-ko'rsatilmaganini
/// eslab qoladi — foydalanuvchi bir marta ko'rgach, qayta login
/// qilganda ham qayta chiqmaydi.
class TutorialService {
  TutorialService._();

  static const _completedKey = 'app_tour_completed_v1';

  static Future<bool> hasCompletedTour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey) ?? false;
  }

  static Future<void> markTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completedKey, true);
  }
}
