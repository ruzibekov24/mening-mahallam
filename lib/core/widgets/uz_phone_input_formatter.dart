import 'package:flutter/services.dart';

/// Foydalanuvchi kiritayotganda raqamni "+998 90 123 45 67"
/// ko'rinishiga avtomatik formatlab boradi.
class UzPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Agar foydalanuvchi 998 bilan boshlamasa, avtomatik qo'shamiz
    if (digits.isNotEmpty && !digits.startsWith('998')) {
      digits = '998$digits';
    }
    if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }

    final buffer = StringBuffer('+');
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 4 || i == 7 || i == 9) {
        if (i != digits.length - 1) buffer.write(' ');
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Faqat "998XXXXXXXXX" ko'rinishidagi toza raqamni qaytaradi
/// (Firebase'ga yuborish uchun).
String cleanPhoneDigits(String formatted) {
  return formatted.replaceAll(RegExp(r'[^0-9]'), '');
}
