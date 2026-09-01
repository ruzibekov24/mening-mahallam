import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// AI yordamchi bilan gaplashishda yuz beradigan, foydalanuvchiga
/// ko'rsatsa bo'ladigan xatolik.
class AssistantException implements Exception {
  final String message;

  /// `true` faqat serverdan 429 (kunlik xabar limiti) kelganda — bu
  /// tarmoq/parsing xatolaridan farqli holat, chunki premium bo'lmagan
  /// foydalanuvchiga bu yerda Premium ekraniga taklif ko'rsatiladi
  /// (`AssistantScreen`ga qarang). Matnni tekshirish (masalan "limit"
  /// so'zini qidirish) ishonchsiz bo'lardi — server xabari tilga
  /// qarab o'zgarmaydi va kelajakda matn o'zgarishi mumkin, shuning
  /// uchun status kodning o'zi ishlatiladi.
  final bool isRateLimited;

  AssistantException(this.message, {this.isRateLimited = false});

  @override
  String toString() => message;
}

/// Bitta suhbat burilishi (turn) — [AssistantRepository.sendMessage]ga
/// `history` sifatida yuboriladigan oldingi xabarlar shakli.
/// `mahallam-assistant-api`ning `POST /chat` konturaktiga mos: `role` —
/// `"user"` yoki `"model"`.
class AssistantTurn {
  final String role;
  final String text;
  const AssistantTurn({required this.role, required this.text});

  Map<String, dynamic> toJson() => {'role': role, 'text': text};
}

/// "Mening Mahallam" AI yordamchisi bilan gaplashuvchi Worker'ga
/// so'rov yuboradi. Suhbat tarixi bu yerda saqlanmaydi — chaqiruvchi
/// (AssistantScreen) uni xotirada tutadi va har safar `history`
/// sifatida yuboradi.
///
/// DIQQAT: Gemini API kaliti bu yerda YO'Q va bo'lishi ham mumkin emas —
/// u faqat `assistant-worker`ning server tomonidagi maxfiy o'zgaruvchisi
/// sifatida saqlanadi. Aks holda APK ichidan kalitni chiqarib olish
/// mumkin bo'lardi.
class AssistantRepository {
  static const String _baseUrl =
      'https://mahallam-assistant-api.ilyosbek41624.workers.dev';

  final FirebaseAuth _auth;

  AssistantRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// AI yordamchiga xabar yuboradi va javobni qaytaradi.
  ///
  /// [history] — oxirgi suhbat burilishlari (kontekst uchun). Serverda
  /// eng oxirgi ~10 tasi hisobga olinadi, qolgani cheklov uchun
  /// e'tiborga olinmaydi — shuning uchun bu yerda cheklash shart emas.
  /// [locale] — "uz" | "ru" | "en"; berilmasa server "uz" deb oladi.
  Future<String> sendMessage({
    required String message,
    List<AssistantTurn> history = const [],
    String? locale,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AssistantException('Foydalanuvchi tizimga kirmagan');
    }

    late final String idToken;
    try {
      idToken = await user.getIdToken() ?? '';
    } catch (_) {
      throw AssistantException(
        "Tizimga kirish tekshiruvida xatolik. Qayta urinib ko'ring",
      );
    }
    if (idToken.isEmpty) {
      throw AssistantException(
        "Tizimga kirish tekshiruvida xatolik. Qayta urinib ko'ring",
      );
    }

    http.Response response;
    try {
      response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          if (history.isNotEmpty) 'history': history.map((t) => t.toJson()).toList(),
          if (locale != null) 'locale': locale,
        }),
      );
    } catch (_) {
      throw AssistantException(
        'AI yordamchiga ulanib bo\'lmadi. Internet aloqangizni tekshiring',
      );
    }

    if (response.statusCode == 429) {
      throw AssistantException(
        _extractError(response) ??
            "Kunlik AI yordamchi xabarlar limiti tugadi. Ertaga qayta urinib ko'ring",
        isRateLimited: true,
      );
    }

    if (response.statusCode != 200) {
      throw AssistantException(_extractError(response) ??
          "AI yordamchi javob bera olmadi. Birozdan so'ng qayta urinib ko'ring");
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final reply = data['reply'];
      if (reply is! String || reply.isEmpty) {
        throw AssistantException("AI yordamchidan bo'sh javob keldi");
      }
      return reply;
    } on AssistantException {
      rethrow;
    } catch (_) {
      throw AssistantException("AI yordamchi javobini o'qib bo'lmadi");
    }
  }

  String? _extractError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic> && data['error'] is String) {
        return data['error'] as String;
      }
    } catch (_) {
      // body JSON emas — pastdagi umumiy xabar ishlatiladi.
    }
    return null;
  }
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return AssistantRepository();
});
