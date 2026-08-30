import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kTextScaleKey = 'app_text_scale';

/// Qariyalar va ko'zi past ko'radigan foydalanuvchilar uchun butun
/// ilova bo'ylab matn o'lchamini kattalashtirish darajalari.
enum AppTextScale { small, medium, large, extraLarge }

extension AppTextScaleX on AppTextScale {
  /// MediaQuery.textScaler ga beriladigan ko'paytiruvchi.
  double get factor {
    switch (this) {
      case AppTextScale.small:
        return 0.9;
      case AppTextScale.medium:
        return 1.0;
      case AppTextScale.large:
        return 1.15;
      case AppTextScale.extraLarge:
        return 1.3;
    }
  }

  String get label {
    switch (this) {
      case AppTextScale.small:
        return 'Kichik';
      case AppTextScale.medium:
        return "O'rta";
      case AppTextScale.large:
        return 'Katta';
      case AppTextScale.extraLarge:
        return 'Juda katta';
    }
  }
}

AppTextScale _textScaleFromString(String? value) {
  switch (value) {
    case 'small':
      return AppTextScale.small;
    case 'large':
      return AppTextScale.large;
    case 'extraLarge':
      return AppTextScale.extraLarge;
    default:
      return AppTextScale.medium;
  }
}

String _textScaleToString(AppTextScale scale) {
  switch (scale) {
    case AppTextScale.small:
      return 'small';
    case AppTextScale.medium:
      return 'medium';
    case AppTextScale.large:
      return 'large';
    case AppTextScale.extraLarge:
      return 'extraLarge';
  }
}

class TextScaleNotifier extends StateNotifier<AppTextScale> {
  TextScaleNotifier() : super(AppTextScale.medium) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = _textScaleFromString(prefs.getString(_kTextScaleKey));
  }

  Future<void> select(AppTextScale scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTextScaleKey, _textScaleToString(scale));
  }
}

final textScaleProvider =
    StateNotifierProvider<TextScaleNotifier, AppTextScale>((ref) {
  return TextScaleNotifier();
});
