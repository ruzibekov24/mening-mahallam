/// Oddiy so'z-filtri — post/izoh/hikoya matnida eng ko'p uchraydigan
/// so'kinish so'zlarini aniqlaydi. Bu to'liq moderatsiya emas (Cloud
/// Function/ML asosidagi filtrlash Blaze plan talab qiladi va
/// loyihada yo'q) — faqat eng oddiy, ochiq holatlarni oldindan
/// to'sib, qolganini mavjud "shikoyat qilish" (`report_repository.dart`)
/// oqimiga qoldiradi.
library;

const List<String> _bannedWords = [
  // O'zbekcha/ruscha eng keng tarqalgan so'kinish so'zlari — ataylab
  // qisqa ro'yxat, chunki uzun ro'yxat yolg'on-musbat hollarni
  // (masalan so'zning bir qismi sifatida) ko'paytiradi.
  'blyad',
  'блять',
  'бляд',
  'сука',
  'suka',
  'пидор',
  'pidor',
  'хуй',
  'huy',
  'xуй',
  'ебан',
  'eban',
  'ебать',
  'жопа',
  'jopa',
  'кучук ит',
];

/// Matnda taqiqlangan so'zlardan biri bor-yo'qligini tekshiradi.
/// Katta-kichik harflarga sezgir emas, so'z chegaralaridan qat'i
/// nazar oddiy `contains` bilan (yolg'on-musbat xavfi kam, chunki
/// ro'yxat qisqa va o'ziga xos so'zlardan iborat).
bool containsBannedWords(String text) {
  final lower = text.toLowerCase();
  return _bannedWords.any((word) => lower.contains(word));
}
