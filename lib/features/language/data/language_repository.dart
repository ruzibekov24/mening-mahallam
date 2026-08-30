import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ilova qo'llab-quvvatlaydigan tillar.
enum AppLanguage { uzbekLatin, uzbekCyrillic, russian }

extension AppLanguageX on AppLanguage {
  String get label {
    switch (this) {
      case AppLanguage.uzbekLatin:
        return "O'zbekcha";
      case AppLanguage.uzbekCyrillic:
        return 'Ўзбекча';
      case AppLanguage.russian:
        return 'Русский';
    }
  }

  /// Bayroq o'rnini bosuvchi qisqa kod (haqiqiy bayroq rasmlari
  /// bo'lmagani uchun, rangli doira ichida ko'rsatiladi).
  String get shortCode {
    switch (this) {
      case AppLanguage.uzbekLatin:
        return "O'Z";
      case AppLanguage.uzbekCyrillic:
        return 'ЎЗ';
      case AppLanguage.russian:
        return 'РУ';
    }
  }

  /// Flutter lokalizatsiya tizimi ishlatadigan Locale qiymati.
  /// Lotin va Кирилл ikkalasi ham "uz" tilining sub-teglari:
  /// Lotin = uz, Кирилл = uz_Cyrl (ISO 15924 skript kodi).
  Locale get locale {
    switch (this) {
      case AppLanguage.uzbekLatin:
        return const Locale('uz');
      case AppLanguage.uzbekCyrillic:
        return const Locale.fromSubtags(
          languageCode: 'uz',
          scriptCode: 'Cyrl',
        );
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }

  String get storageValue => name;

  static AppLanguage fromStorage(String? value) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.storageValue == value,
      orElse: () => AppLanguage.uzbekLatin,
    );
  }
}

const _kLanguageKey = 'app_language';

class LanguageRepository {
  Future<AppLanguage> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return AppLanguageX.fromStorage(prefs.getString(_kLanguageKey));
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguageKey, language.storageValue);
  }
}

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository();
});

/// Joriy tanlangan til (ilova ishga tushganda saqlangan qiymatdan o'qiladi).
class LanguageNotifier extends StateNotifier<AppLanguage> {
  final LanguageRepository _repository;

  LanguageNotifier(this._repository) : super(AppLanguage.uzbekLatin) {
    _load();
  }

  Future<void> _load() async {
    state = await _repository.loadLanguage();
  }

  Future<void> select(AppLanguage language) async {
    state = language;
    await _repository.saveLanguage(language);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier(ref.watch(languageRepositoryProvider));
});