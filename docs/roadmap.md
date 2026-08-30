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

## v1.2.0 — Web super-admin panel + jamoat faolligi (tayyor, `v1.2-dev` branch)

Ikki qism: (A) ilovaga bog'langan to'liq web super-admin panel, (B) v1.5
ro'yxatidan 4 punkt (report, bildirishnoma, reaksiya, so'rovnoma+qidiruv).

**A-qism — Web admin panel:**
- [x] `admin-worker/` — Cloudflare Worker backend (Firebase ID token
      tekshirish, `role == superAdmin` tasdiqlash, Firestore REST orqali
      imtiyozli amallar: premium tasdiqlash/rad etish, banner CRUD,
      shikoyatlarni ko'rib chiqish)
- [x] Statistika sinxronizatsiyasi — Cloudflare Cron Trigger, Firestore
      `count()` agregatsiya so'rovlari, natija Supabase Postgres'ga
      yoziladi (Firebase Spark rejada qoladi, Cloud Functions kerak emas)
- [x] `admin/` — Vite + TypeScript frontend (Firebase Auth login,
      dashboard, mahallalar, premium so'rovlar, bannerlar, shikoyatlar)
- [ ] Deploy: `wrangler secret put` (Firebase/Supabase sirlari),
      `wrangler deploy`, Cloudflare Pages'ga frontend, Supabase SQL
      sxemasini ishga tushirish

**B-qism — Mobil ilova:**
- [x] Report (shikoyat) mexanizmi — `lib/features/moderation/` yangi
      modul, chat xabari/e'lon/xizmat/profil uchun shikoyat tugmasi
- [x] Bildirishnoma turlarini to'liq ulash — `newEvent`/`newMessage`
      ulandi (`newPoll` allaqachon ulangan ekan)
- [x] E'lonlarga reaksiya qo'shish — 4 ta emoji, `reactedUids` maydoni
- [x] So'rovnoma yaxshilash — ko'p tanlovli, anonim, tugash muddati
      (eski formatdagi ovozlar bilan orqaga moslik saqlangan)
- [x] Qidiruvni kengaytirish — `services/` va `polls/` endi qidiruvda

## v1.3.0 — Til/xizmat reytingi + admin panel kengaytmasi (tayyor, `v1.3-dev` branch)

**A-qism — Mobil ilova:**
- [x] Ingliz tili — `lib/l10n/app_en.arb` (538 kalit), `language_screen.dart`
      ga 4-til tanlovi qo'shildi
- [x] Xizmatlar (`services/`) bo'limiga reyting — `LocalService.ratings`
      (uid → 1-5 yulduz), o'rtacha baho va son ko'rsatiladi, matnli
      sharh keyingi versiyaga qoldirildi

**B-qism — Web admin panel kengaytmasi:**
- [x] Statistika trend grafiklari — `admin_stats_history` (Supabase,
      append-only), dashboard kartalarida sparkline
- [x] Mahalla tafsilot sahifasi — `GET /api/mahallas/:id/detail`,
      a'zolar/murojaat holati/e'lon-tadbir-so'rovnoma-xizmat sonlari
- [x] Audit-log — har bir imtiyozli amal (25 ta endpoint) `adminAuditLog`
      kolleksiyasiga yoziladi, alohida sahifada ko'rsatiladi
- Ko'p super-admin qo'llab-quvvatlash — **rad etildi**, hozircha kerak
  emas deb topildi

## v1.4.0 — Murojaat/chat/xarita chuqurlashtirish + AI yordamchi (tayyor, `v1.4-dev` branch)

v2.0 ro'yxatidan to'lovdan tashqari 4 punkt + 2 yangi g'oya:

- [x] Murojaatlar oqimini chuqurlashtirish — xodimga biriktirish, izoh
      thread (`mahallas/*/requests/*/comments`), muddat (SLA), muddati
      o'tganda bildirishnoma
- [x] Guruh chat — yangi `groupChats` kolleksiyasi, mavjud 1:1 chatga
      tegilmagan
- [x] Xarita boyitish — `LocalService`ga ixtiyoriy joylashuv, xaritada
      xizmat ko'rsatuvchi pinlari
- [x] **AI chat-yordamchi** — `assistant-worker/` (yangi Cloudflare
      Worker, Gemini API, kunlik so'rov cheklovi bilan), Gemini kaliti
      Firestore orqali (`appConfig/assistant`) super-admin panelidan
      almashtiriladi — kvota tugasa yangi kalitni qo'lda kod
      o'zgartirmasdan qo'yish mumkin
- [x] Bildirishnoma sozlamalari — har bir tur uchun alohida yoqish/
      o'chirish (`notificationPrefs`), avvalgi global bayroq hech
      qanday ta'sirga ega emas edi — bu birinchi marta haqiqatan ishlaydi
- [x] Offline keshlash — Firestore kesh aniq sozlandi, `connectivity_plus`
      orqali oflayn banner

## v2.0 — Katta yangilanish: to'lov integratsiyasi (rejalashtirish bosqichida, `v2-dev` branch)

Markazida real to'lov shlyuzi turadi (hozir premium/e'lon to'lovi qo'lda,
admin tasdiqlaydi — kodda ochiq izoh bilan qayd etilgan).

- [ ] Click/Payme (va/yoki Play Billing) integratsiyasi — premium va
      xizmat e'lonlari uchun
- [ ] Xizmatlar bozorini peer-to-peer qilish + to'lov orqali buyurtma

## v3.0 — Uzoq muddatli, tasdiqlanmagan g'oyalar

- **AI butun ilova bo'ylab** — v2.0dagi alohida chat-yordamchidan farqli
  o'laroq, AI turli modullarga singdiriladi: murojaatlarni avtomatik
  kategoriyalash/muhimlik darajasini baholash, so'rovnoma/e'lon
  tavsiyalari, qidiruvda tabiiy til bilan so'rash, va h.k. (raqobatchi
  "Mahalla AI" ilovasiga javob sifatida ham qaraladi)
- Usage analytics / BI dashboard (hozir kod bazasida hech qanday
  analitika yo'q)
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
