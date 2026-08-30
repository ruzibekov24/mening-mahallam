import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Profil banneri — foydalanuvchi ism/rasm/unvon orqasida ko'rsatiladigan
/// qopqoq. Ikki turi bor: haqiqiy surat (`image`) yoki chizilgan
/// gradient (`gradient`) — ikkalasidan faqat bittasi to'ldiriladi.
class ProfileBanner {
  final String id;
  final String? image;
  final List<Color>? gradient;
  final bool isPremium;

  /// Rasm muallifi/litsenziyasi kredit qatori (masalan CC BY-SA ostida
  /// olingan Wikimedia Commons suratlari uchun shart) — berilsa, banner
  /// tanlash oynasida ko'rsatiladi.
  final String? attribution;

  const ProfileBanner({
    required this.id,
    this.image,
    this.gradient,
    this.isPremium = false,
    this.attribution,
  }) : assert(image != null || gradient != null);

  BoxDecoration decoration({AlignmentGeometry imageAlignment = Alignment.center}) {
    if (image != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: AssetImage(image!),
          fit: BoxFit.cover,
          alignment: imageAlignment,
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradient!,
      ),
    );
  }
}

/// Barcha mavjud bannerlar — birinchi 3 tasi bepul (haqiqiy o'zbek
/// to'qimachiligi suratlari), qolganlari premium (chizilgan, brend
/// ranglariga asoslangan gradientlar).
///
/// MUHIM: premium bannerlar hozircha faqat QULF belgisini ko'rsatadi —
/// haqiqiy sotib olish (App Store/Play Store IAP) ulanmagan. Buni
/// yoqish uchun alohida ish kerak (RevenueCat yoki platforma-o'ziga
/// xos billing API).
const profileBanners = <ProfileBanner>[
  ProfileBanner(
    id: 'suzani',
    image: 'assets/images/patterns/uzbek_suzani.jpg',
  ),
  ProfileBanner(
    id: 'ikat_stripes',
    image: 'assets/images/patterns/uzbek_ikat_stripes.jpg',
  ),
  ProfileBanner(
    id: 'ikat_robe',
    image: 'assets/images/patterns/uzbek_ikat_robe.jpg',
  ),
  ProfileBanner(
    id: 'abstract_blue',
    image: 'assets/images/patterns/abstract_blue.png',
  ),
  ProfileBanner(
    id: 'abstract_orange',
    image: 'assets/images/patterns/abstract_orange.png',
  ),
  ProfileBanner(
    id: 'abstract_green',
    image: 'assets/images/patterns/abstract_green.png',
  ),
  ProfileBanner(
    id: 'abstract_purple',
    image: 'assets/images/patterns/abstract_purple.png',
  ),
  ProfileBanner(
    id: 'tashkent',
    image: 'assets/images/patterns/city_tashkent.jpg',
  ),
  ProfileBanner(
    id: 'samarkand',
    image: 'assets/images/patterns/city_samarkand.jpg',
  ),
  ProfileBanner(
    id: 'bukhara',
    image: 'assets/images/patterns/city_bukhara.jpg',
  ),
  ProfileBanner(
    // Fayl nomi `city_khiva.jpg` — ro'yxatda esa `city_khorezm.jpg`
    // deb yozilgan edi va bunday fayl umuman yo'q. Natijada bu banner
    // tanlanganda profil qopqog'i bo'sh/kulrang chiqardi. `id` ataylab
    // o'zgartirilmadi: uni tanlab qo'ygan foydalanuvchilarda saqlangan
    // qiymat `khorezm` bo'lib qolgan.
    id: 'khorezm',
    image: 'assets/images/patterns/city_khiva.jpg',
  ),
  ProfileBanner(
    id: 'syrdarya',
    image: 'assets/images/patterns/city_syrdarya.jpg',
  ),
  ProfileBanner(
    id: 'valley',
    image: 'assets/images/patterns/valley.jpg',
  ),

  // --- Yangi bepul bannerlar ---------------------------------------
  // Ataylab "shahar emas" mavzular: mahallalarning ko'pchiligi
  // viloyatda, va oldingi ro'yxatda deyarli faqat shahar manzaralari
  // bor edi.
  ProfileBanner(
    id: 'mahalla_gate',
    image: 'assets/images/patterns/mahalla_gate.jpg',
  ),
  ProfileBanner(
    id: 'cotton_field',
    image: 'assets/images/patterns/cotton_field.jpg',
  ),
  ProfileBanner(
    id: 'chimgan',
    image: 'assets/images/patterns/chimgan_mountains.jpg',
  ),
  ProfileBanner(
    id: 'bread_tandyr',
    image: 'assets/images/patterns/bread_tandyr.jpg',
  ),

  // --- Premium bannerlar (suratlar) --------------------------------
  // Ilgari premium bannerlar faqat CHIZILGAN GRADIENTLAR edi — ya'ni
  // pullik variant bepulidan koʻra kambag'alroq ko'rinardi. Endi
  // premiumda o'zbek me'morchiligi va hunarmandchiligining eng
  // to'yingan suratlari turadi; gradientlar ro'yxat oxirida,
  // qo'shimcha variant sifatida qoldirildi.
  ProfileBanner(
    id: 'registan_night',
    image: 'assets/images/patterns/premium_registan_night.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'suzani_gold',
    image: 'assets/images/patterns/premium_suzani_gold.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'ikat_silk',
    image: 'assets/images/patterns/premium_ikat_silk.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'khiva_dawn',
    image: 'assets/images/patterns/premium_khiva_dawn.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'ceramic_rishtan',
    image: 'assets/images/patterns/premium_ceramic_rishtan.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'girih_brass',
    image: 'assets/images/patterns/premium_girih_brass.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'bukhara_carpet',
    image: 'assets/images/patterns/premium_bukhara_carpet.jpg',
    isPremium: true,
  ),
  ProfileBanner(
    id: 'chaikhana',
    image: 'assets/images/patterns/premium_chaikhana.jpg',
    isPremium: true,
  ),

  // --- Premium gradientlar -----------------------------------------
  ProfileBanner(
    id: 'aurora_blue',
    gradient: [Color(0xFF0F2A6B), AppColors.primary, Color(0xFF6690FF)],
    isPremium: true,
  ),
  ProfileBanner(
    id: 'sunset_amber',
    gradient: [Color(0xFF7A2E00), Color(0xFFF2994A), Color(0xFFFFD08A)],
    isPremium: true,
  ),
  ProfileBanner(
    id: 'emerald',
    gradient: [Color(0xFF0B3D24), Color(0xFF27AE60), Color(0xFF8CE6B0)],
    isPremium: true,
  ),
  ProfileBanner(
    id: 'violet_dusk',
    gradient: [Color(0xFF2E1065), Color(0xFF9254DE), Color(0xFFD8B4FE)],
    isPremium: true,
  ),
];

ProfileBanner bannerById(String? id) {
  return profileBanners.firstWhere(
    (b) => b.id == id,
    orElse: () => profileBanners.first,
  );
}
