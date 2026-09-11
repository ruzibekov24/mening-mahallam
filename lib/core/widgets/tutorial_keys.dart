import 'package:flutter/material.dart';

/// Ilova bo'ylab (turli ekranlarda) joylashgan elementlarni
/// qo'llanma (tur) bilan "nishonga olish" uchun umumiy `GlobalKey`lar.
///
/// Nima uchun markazlashgan: qo'llanma bosqichlari `MainShell`da
/// e'lon qilinadi, lekin nishonlanadigan elementlar turli ekranlarda
/// (Home, Profile) — konstruktor orqali key uzatish har bir oraliq
/// widget'ni o'zgartirishni talab qilardi. Bitta statik ro'yxat
/// orqali har ikkala tomon (nishon va bosqich ta'rifi) mustaqil
/// shu yerga murojaat qiladi.
class TutorialKeys {
  TutorialKeys._();

  static final map = GlobalKey(debugLabel: 'tutorial-map');
  static final navFeed = GlobalKey(debugLabel: 'tutorial-nav-feed');
  static final navRequests = GlobalKey(debugLabel: 'tutorial-nav-requests');
  static final navNeighbors = GlobalKey(debugLabel: 'tutorial-nav-neighbors');
  static final navProfile = GlobalKey(debugLabel: 'tutorial-nav-profile');
  static final settingsMenuItem =
      GlobalKey(debugLabel: 'tutorial-settings-item');
}
