# Roadmap

## v1.0 — Publish (2026-09-01)

Birinchi ommaviy relizi. Asosiy modullar tayyor: auth, e'lonlar, tadbirlar,
murojaatlar, so'rovnomalar, qo'shnilar, chat, xarita, QR orqali qo'shilish,
premium, bildirishnomalar. Reja: **indin** (relizdan keyin dizayn/nashr
sanasi yangilanadi).

## v1.1.0 — Sifat va izchillik (tayyor, release)

Yangi funksiya yo'q — maqsad: dizayn tizimini (design tokens, `AppCard`,
`UserAvatar`) qolgan ekranlarga to'liq qo'llash va o'lik kodni tozalash.
Asos: [`FRONTEND_AUDIT.md`](../FRONTEND_AUDIT.md).

- [x] O'lik `otp_verification_screen.dart` faylini olib tashlash
- [x] `new_request_flow_screen.dart`, `new_announcement_screen.dart`,
      `new_event_screen.dart`, `language_screen.dart`, `splash_screen.dart`
      — token/spacing/radius izchilligini tekshirish va tuzatish
      (audit hujjatida "tegilmagan" deb belgilangan, lekin tekshiruvda
      aksariyati allaqachon tayyor chiqdi — faqat `new_event_screen.dart`da
      1 ta kichik tuzatish kerak bo'ldi)
- [x] `onboarding_screen.dart` uchun bosqichlarga alohida illyustratsiya
      (tekshiruvda audit hujjatidan keyingi sessiyada allaqachon
      qilinganligi aniqlandi — haqiqiy, litsenziyalangan CC0/Met Museum
      rasmlari `assets/images/onboarding_backgrounds/` va
      `onboarding_icons/` da mavjud va ekranda to'liq ishlatiladi)
- [x] `flutter analyze` bo'yicha qolgan warning/info'larni tozalash
      (170 → 5 ta, qolgani ataylab tegilmagan: 3 tasi xavfsiz `mounted`
      naqshi, 2 tasi `Radio` API eskirishi — alohida refaktoring talab
      qiladi)

## v2.0 — Katta yangilanish (rejalashtirish bosqichida, `v2-dev` branch)

Hali aniq qamrov belgilanmagan — g'oyalar to'planmoqda. Nomzod
yo'nalishlar (tasdiqlanmagan):

- Premium modulini kengaytirish (mahalla uchun yangi pullik imkoniyatlar)
- So'rovnoma/e'lonlar uchun kengaytirilgan statistika
- Push-bildirishnoma stsenariylarini boyitish

## Jamoa

Hozircha loyiha bitta kishi (Ilyosbek) tomonidan yuritilmoqda. Jamoa
yig'ilganda:

- Yangi a'zolar uchun kirish nuqtasi: shu fayl + [`README.md`](../README.md)
  + [`FRONTEND_AUDIT.md`](../FRONTEND_AUDIT.md)
- Dizayn qoidalari: `lib/core/theme/app_tokens.dart` — yangi kod faqat
  shu yerdagi konstantalardan foydalanishi kerak
- Git strategiyasi: `main` — publish holati, `v1.1-dev`/`v2-dev` —
  faol ishlanayotgan versiyalar, alohida branch'larda tayyorlanadi va
  tayyor bo'lgandagina `main`ga qo'shiladi
