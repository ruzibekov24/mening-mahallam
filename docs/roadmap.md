# Roadmap

> **Eslatma (2026-09-01):** ushbu fayl endi git tarixi (`git log`,
> `pubspec.yaml` version tarixi) bilan solishtirib qayta yozildi — avvalgi
> nusxa faqat v1.4.0gacha "tayyor" deb ko'rsatib, v1.4.1–v1.8.0 oralig'idagi
> real ishlab chiqilgan versiyalarni tushirib qoldirgan edi.
>
> **Versiya-raqamlash haqida:** git tag'lari (`v1.2.0`, `v1.3.0`...) commit
> xabarlaridagi versiyalarga mos kelmaydi (masalan `v1.3.0` tegi aslida
> "v1.8.0" xabarli commitga qo'yilgan) — bu eski, chalkash nomlash tarixi,
> qasddan tuzatilmagan (tag qayta yozish repo tarixini o'zgartiradi).
> `pubspec.yaml`dagi haqiqiy manba: versiya nomi v1.8.0+21gacha ko'tarilgan,
> so'ng oxirgi commit uni **ataylab v1.3.1+23ga qaytargan** (build raqami
> 23 — barcha oldingi ishlar saqlanib qolgan, faqat ommaviy reliz uchun
> nom qayta tartiblangan).

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

## v1.4.1 — Shoshilinch tuzatish (tayyor)

- [x] AI Yordamchi manzili placeholder edi, haqiqiy `assistant-worker` deploy
      manziliga tuzatildi
- [x] v1.4.0dan keyin barcha asosiy ekranlarda "Nimadir xato ketdi" xabari —
      `connectivity_plus` (native plugin) shubhali sabab sifatida to'liq
      olib tashlandi (oflayn banner funksiyasi vaqtincha yo'qoldi)
- [x] `AndroidManifest.xml`ga `ACCESS_NETWORK_STATE` ruxsatnomasi qo'shildi

## v1.5.0 — AI Workers AI'ga o'tkazish + suhbat tarixi (tayyor)

- [x] Production Firestore composite index xatosi (Home/E'lonlar/Murojaat
      ekranlaridagi asosiy xato) tuzatildi
- [x] Login ekranidagi dublikat mahalla-tekshirish kodi olib tashlandi
- [x] AI Yordamchi Gemini'dan Cloudflare Workers AI (Llama 3.3 70B)ga
      o'tkazildi — tashqi API kalit endi kerak emas
- [x] AI suhbat tarixi Firestore'da saqlanadi (ro'yxat, yangi suhbat, o'chirish)
- [x] AI javoblari formatlangan + harflab chiqish animatsiyasi
- [x] Premium: kunlik AI limiti 20 → 100, super-admin premiumni bekor qila
      oladi, yangi badge dizayni; premium foydalanuvchi uchun AI orqali
      murojaat qoralamasini oldindan to'ldirish
- [x] AI Yordamchi: so'ralmagan mavzularni javobga qo'shib yuborishi
      cheklandi (tizim ko'rsatmasiga qoida qo'shildi)

## v1.6.0 — Animatsiya va tafsilot ekranlari (tayyor)

- [x] Umumiy `AppPageRoute` o'tish yordamchisi (fade+slide), ~18 ta
      navigatsiya joyiga qo'llandi
- [x] E'lon/Tadbir uchun yangi tafsilot ekranlari (Hero rasm, to'liq matn,
      reaksiyalar); Tadbir modeliga `description` qo'shildi
- [x] Murojaat tafsiloti: ulashish, o'xshash murojaatlar, o'z izohini
      o'chirish, Hero rasm uzluksizligi

## v1.6.1 — Rasm keshlash, oflayn holat (tayyor)

- [x] `cached_network_image` — barcha `Image.network` o'rnini bosdi
      (shimmer placeholder)
- [x] Oflayn holat aniqlash native plugin'siz — Firestore oqimiga dastlabki
      kutish taymeri (v1.4.1da olib tashlangan funksiya xavfsizroq usulda
      qaytarildi)
- [x] Murojaatga yangi izoh yozilganda muallifga bildirishnoma
- [x] Til almashtirishda tasdiqlovchi toast

## v1.7.0 — Telegram uslubidagi chat, premium badge, banner iqtisodiyoti (tayyor)

- [x] Chat: o'qildi belgisi, "yozmoqda..." animatsiyasi, emoji reaksiya,
      rasm yuborish/to'liq ekran ko'rish, kun ajratgichlari
- [x] Premium: 5 ta badge uslubi (Oltin/Safir/Zumrad/Yoqut/Kumush), profil
      banner ro'yxatidan 30tadan 4tasi bepul qoladi
- [x] AI kunlik limiti tugaganda premium taklif kartochkasi
- [x] Firestore qoidalari: `typing`/`lastReadAt`/`reactions` — har kim
      faqat o'z kalitini yozadi

## v1.8.0 — "Mahal" AI qayta dizayni, Liquid Glass izchilligi (tayyor)

- [x] AI Yordamchi ("Mahal"): bo'limga kirish bilan yangi suhbat, sidebar
      orqali tarix, AI o'zi suhbatga nom beradi
- [x] AI 5 xil niyatni tanib (murojaat/fikr-mulohaza/xizmatlar/yordam/
      premium) tegishli ekranga tugma taklif qiladi
- [x] Liquid Glass qayta ishlatiladigan komponentlar kutubxonasi
      (Surface/Button/CircleButton/BackButton/ToggleSwitch/PillButton),
      38+ joyga qo'llandi
- [x] `assistant-worker`ga AI niyat aniqlash + sarlavha generatsiyasi,
      productionga deploy

## v1.3.1 — Ommaviy relizga tayyorgarlik (joriy holat, `main`, 2026-09-01)

Versiya nomi qasddan qayta tartibga solindi (build 23, yuqoridagi barcha
ishlar saqlangan holda) — navigatsiya va brend izchilligi ustida ishlandi:

- [x] Bosh ekran header'idan AI/Chat ikonkalari olib tashlandi, faqat tekis
      bildirishnoma qoldi
- [x] Bosh ekranga banner va xarita orasida "Mahal" bilan suhbat kartasi
- [x] Qo'shnilar bo'limi "Qo'shnilar"/"Yozishmalar"ga bo'lindi
- [x] Marka rangi logotip bilan bir xillashtirildi (#0752EB)
- [x] Sarlavhalar Work Sans, matn Source Sans 3 shriftiga o'tkazildi
- [x] Sozlamalar > Versiya to'g'ri qiymatni ko'rsatadi

## v2.0 — Katta yangilanish: to'lov integratsiyasi (hali boshlanmagan, `v2-dev` bo'sh)

`v2-dev` va `v1.5-dev` branch'lari `main`dan uzoqlashmagan — ikkalasi ham
v1.4.1 commitida to'xtab qolgan, hali hech qanday to'lov-bog'liq kod
yozilmagan.

Markazida real to'lov shlyuzi turadi (hozir premium/e'lon to'lovi qo'lda,
admin tasdiqlaydi — kodda ochiq izoh bilan qayd etilgan).

- [ ] Click/Payme (va/yoki Play Billing) integratsiyasi — premium va
      xizmat e'lonlari uchun
- [ ] Xizmatlar bozorini peer-to-peer qilish + to'lov orqali buyurtma

## Yangi g'oyalar (tavsiya, 2026-09-01)

Kod bazasidagi mavjud modullarni (`lib/features/*`, `assistant-worker/`,
`admin/`) tekshirib chiqilganda topilgan, hali yopilmagan aniq bo'shliqlar:

- **Xizmatlar reytingiga matnli sharh** — v1.3.0da yulduzli baho qo'shilgan,
  lekin matnli sharh "keyingi versiyaga qoldirildi" deb yozilgan edi, hali
  qilinmagan (`lib/features/services/`). Eng kichik, eng tez qo'shsa
  bo'ladigan punkt.
- **Xizmatlarga oldindan bron/navbat** — `services/` da xarita pin va
  reyting bor, lekin real vaqtli murojaat/navbat yo'q. v2.0 to'lov
  infratuzilmasi bilan tabiiy bog'lanadi (bron + to'lov bitta oqimda).
- **AI yordamchi foydalanish analitikasi** — `assistant-worker/`da kunlik
  so'rov cheklovi bor, lekin super-admin panelda (`admin/`) qaysi niyat
  turlari (murojaat/fikr-mulohaza/xizmatlar/yordam/premium) ko'p
  ishlatilayotgani, kvota qanchada tugayotgani ko'rinmaydi — v1.8.0da
  qo'shilgan niyat aniqlashdan bevosita foydalanish mumkin.
- **Mahalla-aro taqqoslash** (super-admin panel) — `admin_stats_history`
  orqali har bir mahalla uchun trend sparkline bor, lekin mahallalarni
  bir-biriga solishtirish (masalan murojaat yopilish tezligi bo'yicha
  reyting) yo'q — mavjud ma'lumotdan qo'shimcha view sifatida chiqarish
  mumkin.
- **Oflaynda murojaat/e'lon yaratish** — v1.6.1da oflayn holatni aniqlash
  qo'shilgan (faqat banner), lekin oflaynda yangi murojaat/e'lonni local
  navbatga qo'yib, ulanish tiklanganda avtomatik yuborish yo'q — banner
  infratuzilmasi ustiga qurish mumkin.
- **Guruh chat va murojaat SLA uchun push bildirishnoma** — v1.4.0da
  qo'shilgan `notificationPrefs` tur-tur yoqish/o'chirishni qo'llab-
  quvvatlaydi, lekin guruh chat xabari va murojaat muddati (SLA) o'tishi
  uchun push hali ulanganini/ulanmaganini tekshirib chiqish kerak — ehtimol
  bo'shliq bor.

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
