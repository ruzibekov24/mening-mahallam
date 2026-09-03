import 'package:shared_preferences/shared_preferences.dart';

/// Lentaga ketma-ket juda tez-tez post joylashning oldini oladi.
/// Bu qattiq xavfsizlik chegarasi emas (faqat qurilmada saqlanadi,
/// Firestore Rules darajasida emas — buning uchun Cloud Function
/// kerak bo'lardi, loyihada Blaze plan yo'q), balki oddiy foydalanuvchi
/// xatosi/spamini kamaytiruvchi UX himoyasi.
const _kLastPostAtKey = 'feed_last_post_at_ms';
const postCooldown = Duration(seconds: 30);

/// Cooldown hali tugamagan bo'lsa, qolgan vaqtni qaytaradi;
/// post joylash mumkin bo'lsa `null` qaytaradi.
Future<Duration?> remainingPostCooldown() async {
  final prefs = await SharedPreferences.getInstance();
  final lastMs = prefs.getInt(_kLastPostAtKey);
  if (lastMs == null) return null;
  final elapsed = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(lastMs),
  );
  if (elapsed >= postCooldown) return null;
  return postCooldown - elapsed;
}

Future<void> markPostedNow() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_kLastPostAtKey, DateTime.now().millisecondsSinceEpoch);
}
