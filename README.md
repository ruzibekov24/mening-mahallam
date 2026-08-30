# Mening Mahallam

O'zbekiston mahallalari uchun mobil ilova — mahalla aholisi, faollari va
raislarini bitta joyda birlashtiradi: e'lonlar, tadbirlar, murojaatlar,
so'rovnomalar, qo'shnilar ro'yxati va chat.

## Holat

**v1.0.5** — publish uchun tayyor (Google Play / App Store).

Faol ishlanmoqda:
- `v1.1-dev` — dizayn izchilligi va sifat tuzatishlari (yangi funksiya yo'q)
- `v2-dev` — kelajakdagi katta yangilanish (rejalashtirish bosqichida)

Batafsil: [`docs/roadmap.md`](docs/roadmap.md).

## Texnologiyalar

- **Frontend:** Flutter (Dart), Riverpod
- **Backend:** Firebase (Auth, Firestore, Realtime DB, Storage), Supabase (Edge Functions — telefon tasdiqlash, push)
- **Landing/marketing sayt:** Cloudflare Pages/Workers (`landing/`, `landing-worker/`)

## Asosiy funksiyalar

- Mahallaga QR orqali qo'shilish, rais/aholi rollari
- E'lonlar va tadbirlar
- Murojaatlar (shikoyat/taklif) va ularni ko'rib chiqish oqimi
- So'rovnomalar (polls)
- Qo'shnilar ro'yxati, xarita
- Chat, bildirishnomalar
- Premium (mahalla uchun qo'shimcha imkoniyatlar)

To'liq modul ro'yxati: [`lib/features/`](lib/features).

## Loyihani ishga tushirish

```bash
flutter pub get
flutter run
```

Firebase/Supabase konfiguratsiyasi loyihada allaqachon ulangan
(`lib/firebase_options.dart`, `lib/core/services/supabase_config.dart`).
Reliz imzosi kaliti (`android/key.properties`) versiyalarda saqlanmaydi —
lokal muhitda alohida sozlanadi.

## Hujjatlar

| Fayl | Mazmuni |
|---|---|
| [`docs/roadmap.md`](docs/roadmap.md) | Versiyalar rejasi: v1.0 → v1.1 → v2.0 |
| [`FRONTEND_AUDIT.md`](FRONTEND_AUDIT.md) | Dizayn tizimi auditi va tuzatishlar tarixi |
| [`docs/archive/`](docs/archive/) | Loyihaning dastlabki (kod yozilishidan oldingi) reja hujjatlari — tarixiy arxiv |
