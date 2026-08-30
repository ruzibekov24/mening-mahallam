/// Firestore'da saqlangan xom raqamni (masalan `998901234567`)
/// o'qilishi oson formatga aylantiradi: `+998 90 123 45 67`.
/// 12 xonali bo'lmagan qiymatlar o'zgarishsiz qaytariladi (masalan
/// hali to'liq kiritilmagan yoki noto'g'ri formatdagi eski yozuvlar).
String formatPhoneNumber(String rawDigits) {
  if (rawDigits.length != 12) return rawDigits;
  return '+${rawDigits.substring(0, 3)} '
      '${rawDigits.substring(3, 5)} '
      '${rawDigits.substring(5, 8)} '
      '${rawDigits.substring(8, 10)} '
      '${rawDigits.substring(10, 12)}';
}
