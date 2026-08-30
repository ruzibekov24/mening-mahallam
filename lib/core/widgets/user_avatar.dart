import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Ilova bo'ylab **yagona** foydalanuvchi avatari.
///
/// Auditdan oldin ikkita bir-biriga zid tizim bor edi:
///   • "o'zim" — `Container` doira, to'la `AppColors.primary` fon, oq matn,
///     2 ta bosh harf (profil, sozlamalar, profilni tahrirlash);
///   • "boshqalar" — `CircleAvatar`, rol rangi 15% shaffoflikda, rangli
///     matn, 1 ta bosh harf (qo'shnilar, asosiy, a'zolar boshqaruvi).
///
/// Natijada bir xil odam qaysi ekranda ochilishiga qarab butunlay
/// boshqacha ko'rinardi. Bu widget ikkalasini almashtiradi.
///
/// Dizayn qarori (Nextdoor uslubi): rasm bo'lmasa — bosh harflar +
/// **foydalanuvchi identifikatoriga bog'liq barqaror gradient**. Ya'ni
/// bitta odam har doim bitta rangda ko'rinadi, lekin ro'yxatdagi turli
/// odamlar turli rangda — bu ro'yxatni "jonli" qiladi va odamlarni
/// bir-biridan tez ajratishga yordam beradi.
class UserAvatar extends StatelessWidget {
  /// Avatar diametri (radius emas — piksel o'lchami).
  final double size;

  /// Ism — bosh harf va gradient uchun ishlatiladi.
  final String firstName;

  /// Familiya — ikkinchi bosh harf uchun. Bo'sh bo'lsa bitta harf chiqadi.
  final String lastName;

  /// Profil rasmi. `null` yoki bo'sh bo'lsa — bosh harflar ko'rsatiladi.
  /// Rasm yuklanmasa ham (tarmoq xatosi) bosh harflarga qaytadi.
  final String? photoUrl;

  /// Gradient uchun barqaror urug'. Odatda foydalanuvchi UID'si.
  /// Berilmasa ism+familiya ishlatiladi — bu ham barqaror, lekin
  /// ismdoshlar bir xil rangda chiqadi.
  final String? seed;

  /// Avatar atrofidagi ingichka halqa — rolni ko'rsatish uchun
  /// (rais/xodim). `null` bo'lsa halqa chizilmaydi.
  final Color? ringColor;

  /// Pastki-o'ng burchakdagi yashil "onlayn" nuqtasi.
  final bool isOnline;

  const UserAvatar({
    super.key,
    required this.size,
    required this.firstName,
    this.lastName = '',
    this.photoUrl,
    this.seed,
    this.ringColor,
    this.isOnline = false,
  });

  /// To'liq ism bitta satr bo'lganda ("Ali Valiyev") qulay konstruktor.
  factory UserAvatar.fromFullName({
    Key? key,
    required double size,
    required String fullName,
    String? photoUrl,
    String? seed,
    Color? ringColor,
    bool isOnline = false,
  }) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return UserAvatar(
      key: key,
      size: size,
      firstName: parts.isNotEmpty ? parts.first : '',
      lastName: parts.length > 1 ? parts[1] : '',
      photoUrl: photoUrl,
      seed: seed ?? fullName,
      ringColor: ringColor,
      isOnline: isOnline,
    );
  }

  /// Bosh harflar — Unicode xavfsiz (`characters` orqali), ya'ni kirill
  /// va qo'shma belgilar bilan ham to'g'ri ishlaydi.
  ///
  /// Auditdan oldin bu mantiq uchta faylda, ikki xil algoritm bilan
  /// takrorlangan edi — ikkitasi `characters`, bittasi `[0]` ishlatardi.
  String get _initials {
    final a = firstName.trim();
    final b = lastName.trim();
    final first = a.isNotEmpty ? a.characters.first.toUpperCase() : '';
    final second = b.isNotEmpty ? b.characters.first.toUpperCase() : '';
    final result = '$first$second';
    return result.isEmpty ? '?' : result;
  }

  /// Avatar foni uchun gradient juftliklari.
  ///
  /// Ranglar brend palitrasi atrofida tanlangan — hammasi bir xil
  /// to'yinganlik va yorqinlikda, shuning uchun ro'yxatda yonma-yon
  /// turganda uyg'un ko'rinadi va oq matn hammasida o'qiladi.
  static const _gradients = <List<Color>>[
    [Color(0xFF2F5BFF), Color(0xFF6690FF)], // ko'k
    [Color(0xFF9254DE), Color(0xFFC49CFF)], // binafsha
    [Color(0xFF27AE60), Color(0xFF6FCF97)], // yashil
    [Color(0xFFF2994A), Color(0xFFFFC080)], // to'q sariq
    [Color(0xFF00A3A3), Color(0xFF5FD6D6)], // firuza
    [Color(0xFFE8557E), Color(0xFFFF9BB3)], // pushti
    [Color(0xFF5A67D8), Color(0xFF9BA5F0)], // indigo
    [Color(0xFFD98E04), Color(0xFFF5C453)], // oltin
  ];

  /// Urug'dan barqaror indeks — bir xil urug' har doim bir xil gradient
  /// beradi (ilova qayta ishga tushganda ham o'zgarmaydi).
  List<Color> get _gradient {
    final key = (seed?.isNotEmpty == true)
        ? seed!
        : '${firstName.trim()}${lastName.trim()}';
    if (key.isEmpty) return _gradients.first;

    // Oddiy, barqaror hash — `hashCode` platformalar orasida
    // kafolatlanmagani uchun qo'lda hisoblaymiz.
    var hash = 0;
    for (final unit in key.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return _gradients[hash % _gradients.length];
  }

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Bosh harf o'lchami avatarga proporsional — 96px avatarda 30px,
    // 40px avatarda 15px. Har bir ekranda qo'lda tanlash o'rniga.
    final fontSize = size * 0.36;
    final gradient = _gradient;

    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: _hasPhoto
          // `Image.network` ishlatamiz (`backgroundImage` emas), chunki
          // faqat u `errorBuilder`/`loadingBuilder` beradi. Auditdan
          // oldin rasm yuklanmasa butunlay bo'sh doira qolardi.
          ? Image.network(
              photoUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsText(fontSize),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                // Yuklanayotganda ham bosh harflar ko'rinib turadi —
                // bo'sh doira "singan" tuyulmaydi.
                return _initialsText(fontSize);
              },
            )
          : _initialsText(fontSize),
    );

    if (ringColor != null) {
      avatar = Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: 2),
        ),
        child: avatar,
      );
    }

    if (!isOnline) return avatar;

    // Onlayn nuqtasi — avatar o'lchamiga proporsional, iOS/WhatsApp
    // uslubida pastki-o'ng burchakda, fon rangida halqa bilan.
    final dotSize = (size * 0.28).clamp(10.0, 16.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.isDarkMode
                    ? AppColors.darkSurface
                    : AppColors.lightSurface,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialsText(double fontSize) {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1.0,
          // Gradient ustida oq matn har doim o'qilishi uchun juda
          // yumshoq soya.
          shadows: const [
            Shadow(color: Color(0x33000000), blurRadius: 2),
          ],
        ),
      ),
    );
  }
}
