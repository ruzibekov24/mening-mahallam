import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/supabase_config.dart';

/// Telegram bot orqali telefon tasdiqlash uchun ishlatiladigan
/// wrapper. Firebase Phone Auth (SMS) o'rniga: foydalanuvchi
/// Telegram botga yo'naltiriladi, u yerda "/start" bosilishi bilan
/// backend (Supabase Edge Function) raqamni tasdiqlangan deb
/// belgilaydi, ilova esa buni pollingda kuzatib turadi.
///
/// Register va "parolni unutdim" oqimlari ikkalasi ham shu
/// repository'ni ishlatadi.

/// Bot username'i — deep link yasashda ishlatiladi.
const String _telegramBotUsername = 'MahallamOTP_bot';

class PhoneVerificationException implements Exception {
  final String message;
  PhoneVerificationException(this.message);
}

enum VerificationStatus { pending, verified, expired, notFound }

class PhoneVerificationRepository {
  final http.Client _client;
  PhoneVerificationRepository({http.Client? client})
      : _client = client ?? http.Client();

  /// [phoneE164] — "+998901234567" formatida bo'lishi shart.
  /// Backend'da yangi tasdiqlash yozuvi (token) ochadi va uni
  /// qaytaradi. Bu token keyin deep link va status so'rovlarida
  /// ishlatiladi.
  Future<String> startVerification({required String phoneE164}) async {
    try {
      final response = await _client.post(
        Uri.parse(SupabaseConfig.functionUrl('start-verification')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
        },
        body: jsonEncode({'phone': phoneE164}),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        throw PhoneVerificationException(
          (body['error'] as String?) ?? 'Tasdiqlash boshlanmadi',
        );
      }

      return body['token'] as String;
    } on PhoneVerificationException {
      rethrow;
    } catch (_) {
      throw PhoneVerificationException(
        'Internet aloqasini tekshiring va qayta urinib ko\'ring',
      );
    }
  }

  /// Telegram botni shu [token] bilan ochadi. Foydalanuvchi botda
  /// "/start" bosgach, backend token orqali qaysi raqam ekanini
  /// biladi.
  Future<void> openTelegramBot(String token) async {
    final uri = Uri.parse('https://t.me/$_telegramBotUsername?start=$token');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      throw PhoneVerificationException(
        'Telegram ilovasi topilmadi. Iltimos, Telegram\'ni o\'rnating',
      );
    }
  }

  /// Bir martalik holat tekshiruvi.
  Future<VerificationStatus> checkStatus(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(
          '${SupabaseConfig.functionUrl('check-verification')}?token=$token',
        ),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
        },
      );

      if (response.statusCode != 200) return VerificationStatus.notFound;

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      switch (body['status'] as String?) {
        case 'verified':
          return VerificationStatus.verified;
        case 'expired':
          return VerificationStatus.expired;
        case 'pending':
          return VerificationStatus.pending;
        default:
          return VerificationStatus.notFound;
      }
    } catch (_) {
      // Tarmoq xatosi — pending deb hisoblab, keyingi pollingda
      // qayta urinamiz (foydalanuvchini bekorga xato bilan
      // to'xtatmaslik uchun).
      return VerificationStatus.pending;
    }
  }

  /// Telefon Telegram orqali tasdiqlangandan keyin chaqiriladi —
  /// [token] shu tasdiqni isbotlaydi, backend uni `phone_verifications`
  /// jadvalida tekshirib, tasdiqlangan bo'lsa Firebase Admin SDK orqali
  /// parolni yangilaydi va tokenni bir martalik qilib belgilaydi.
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _client.post(
        Uri.parse(SupabaseConfig.functionUrl('reset-password')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.anonKey}',
          'apikey': SupabaseConfig.anonKey,
        },
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw PhoneVerificationException(
          (body['error'] as String?) ?? 'Parolni tiklab bo\'lmadi',
        );
      }
    } on PhoneVerificationException {
      rethrow;
    } catch (_) {
      throw PhoneVerificationException(
        'Internet aloqasini tekshiring va qayta urinib ko\'ring',
      );
    }
  }

  /// [token] tasdiqlanguncha har [interval]da so'rab turadi.
  /// Tasdiqlangan yoki muddati tugagan zahoti stream yopiladi.
  Stream<VerificationStatus> pollStatus(
    String token, {
    Duration interval = const Duration(seconds: 2),
  }) {
    late final StreamController<VerificationStatus> controller;
    Timer? timer;

    Future<void> tick() async {
      final status = await checkStatus(token);
      controller.add(status);
      if (status == VerificationStatus.verified ||
          status == VerificationStatus.expired) {
        timer?.cancel();
        await controller.close();
      }
    }

    controller = StreamController<VerificationStatus>(
      onListen: () {
        tick();
        timer = Timer.periodic(interval, (_) => tick());
      },
      onCancel: () {
        timer?.cancel();
      },
    );

    return controller.stream;
  }
}

final phoneVerificationRepositoryProvider =
    Provider<PhoneVerificationRepository>((ref) {
  return PhoneVerificationRepository();
});