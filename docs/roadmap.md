# Roadmap

## v1.0 — Publish (2026-09-01)

Birinchi ommaviy relizi. Asosiy modullar tayyor: auth, e'lonlar, tadbirlar,
murojaatlar, so'rovnomalar, qo'shnilar, chat, xarita, QR orqali qo'shilish,
premium, bildirishnomalar. Reja: **indin** (relizdan keyin dizayn/nashr
sanasi yangilanadi).

## v1.1 — Sifat va izchillik (jarayonda, `v1.1-dev` branch)

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
- [ ] `onboarding_screen.dart` uchun bosqichlarga alohida illyustratsiya
      (yangi vizual asset talab qiladi — alohida ish)
- [ ] `flutter analyze` bo'yicha qolgan warning/info'larni tozalash

## v1.5 — Jamoat faolligi, xavfsizlik, to'liqlik (rejalashtirish bosqichida, `v1.5-dev` branch)

Yangi to'lov infratuzilmasisiz — mavjud arxitekturani to'ldirish va
kengaytirish.

- [ ] Report (shikoyat) mexanizmi — hozir faqat `block` bor, foydalanuvchi/
      kontent ustidan shikoyat qilish yo'q
- [ ] Bildirishnoma turlarini to'liq ulash — `newEvent`/`newPoll`/
      `newMessage` enum'da e'lon qilingan, lekin repository'larda
      chaqirilmagan
- [ ] E'lonlarga reaksiya/izoh qo'shish
- [ ] So'rovnomani yaxshilash — ko'p tanlovli, anonim, tugash muddati
- [ ] Qidiruvni kengaytirish — `services/` va `polls/` ni qo'shish
- [ ] Ingliz tili (`l10n/`ga 4-til)
- [ ] Xizmatlar (`services/`) bo'limiga reyting/sharh (to'lovsiz)

## v2.0 — Katta yangilanish: to'lov integratsiyasi (rejalashtirish bosqichida, `v2-dev` branch)

Markazida real to'lov shlyuzi turadi (hozir premium/e'lon to'lovi qo'lda,
admin tasdiqlaydi — kodda ochiq izoh bilan qayd etilgan).

- [ ] Click/Payme (va/yoki Play Billing) integratsiyasi — premium va
      xizmat e'lonlari uchun
- [ ] Murojaatlar oqimini chuqurlashtirish — xodimga biriktirish, izoh/
      thread, SLA/muddat, eskalatsiya
- [ ] Guruh chat (hozir faqat 1:1)
- [ ] Xarita boyitish — xizmat ko'rsatuvchilar uchun pinlar
- [ ] Web admin panel asosi — ko'p mahallani boshqaruvchi super-adminlar
      uchun (hozir admin funksiyalari faqat mobil ilova ichida tarqoq)
- [ ] Xizmatlar bozorini peer-to-peer qilish + to'lov orqali buyurtma

## v3.0 — Uzoq muddatli, tasdiqlanmagan g'oyalar

- Usage analytics / BI dashboard (hozir kod bazasida hech qanday
  analitika yo'q)
- AI-yordamchi (murojaat kategoriyalash, FAQ-bot)
- Kommunal xizmat integratsiyasi (davlat tizimlariga bog'liq, yuqori
  murakkablik/huquqiy tomon — faqat imkoniyat, majburiy emas)
- Ko'p-mintaqa/ko'p-shahar miqyoslash
- Web/desktop to'liq qo'llab-quvvatlash (hozir faqat skeleton)

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
