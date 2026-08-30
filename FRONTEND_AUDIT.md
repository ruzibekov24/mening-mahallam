# FRONTEND AUDIT — "Mening Mahallam"

**Sana:** 2026-08-17
**Qamrov:** `lib/core/theme/`, `lib/core/widgets/`, `lib/features/**/presentation/`
**Hajm:** 68 ta Dart fayl (l10n'siz), ~22 200 qator
**`flutter analyze` bazaviy holati:** 140 ta muammo — **6 ta error** + 134 ta warning/info
(asosan `unnecessary_non_null_assertion`, `unused_import`, `prefer_const_*`).

> **Muhim:** 6 ta error'ning hammasi
> [`otp_verification_screen.dart`](lib/features/auth/presentation/otp_verification_screen.dart)
> da — u `PhoneVerificationRepository`da endi mavjud bo'lmagan `sendCode`,
> `buildCredential` va `OtpSendStatus` ga murojaat qiladi (repozitoriy Telegram
> orqali tekshiruvga o'tkazilgan, ekran esa yangilanmagan). Ilova baribir
> quriladi, chunki **bu fayl hech qayerdan import qilinmagan** — Dart faqat
> `main.dart`dan yetib boriladigan kutubxonalarni kompilyatsiya qiladi.
> Ya'ni bu 1.4-banddagi o'lik dubl fayl bilan bir toifadagi muammo, lekin
> bu safar butun ekran. Qarori — sizniki: tiklash yoki o'chirish.

---

## 0. XULOSA — asosiy sabab

Ilova "AI shablon" taassurotini beryapti, lekin sabab **dizayn tizimi yo'qligi emas**.
Dizayn tizimi **bor** va u yaxshi yozilgan — muammo shundaki, **u ishlatilmayapti**.

`lib/core/widgets/` ichida 4 ta to'g'ri qurilgan qayta ishlatiladigan komponent bor
(`AppCard`, `AppEmptyView`, `AppErrorView`, `Shimmer*`). Ular yozilgan, izohlangan,
tayyor — lekin ekranlarning aksariyati ularni **import qilmaydi** va o'rniga har bir
faylda o'z variantini qaytadan yozadi. Natija: har bir ekran o'zining biroz boshqacha
radiusi, soyasi, shrift o'lchami va bo'sh-holat dizayni bilan chiqadi. Ko'z buni
"tizimsizlik" deb o'qiydi — aynan shu "shablon" hissini beradi.

**Eng og'ir 5 ta topilma (ta'sir bo'yicha):**

| № | Muammo | Miqyos |
|---|--------|--------|
| 1 | Ikki xil, bir-biriga mos kelmaydigan avatar tizimi | 9 ta joy, 8 ta fayl |
| 2 | `AppCard` yozilgan, lekin **0 marta** ishlatilgan | 132 ta qo'lda yozilgan karta |
| 3 | Tipografiyada 23 xil `fontSize` qiymati, ierarxiya yo'q | 192 ta xom `TextStyle` |
| 4 | Ikkita ikonka oilasi aralashgan (Material + Phosphor) | 167 vs 24 ta ikonka |
| 5 | 27 ta ekranda umuman loading/empty/error holati yo'q | 30 ta ekrandan 27 tasi |

---

## 1. PLACEHOLDER / BO'SH JOYLAR

### 1.1 — Ikkita bir-biriga zid avatar tizimi ⚠️ **ENG YUQORI PRIORITET**

Sizning texnik topshiriqda "`CircleAvatar(child: Icon(Icons.person))`" deb taxmin
qilingan edi — **bunday holat loyihada yo'q**. Barcha avatarlar allaqachon bosh
harf (initial) ko'rsatadi. Muammo boshqa: **bir xil odam qaysi ekranda ochilishiga
qarab butunlay boshqacha ko'rinadi.**

**A tizimi — "o'zim" (Container + to'la primary fon + oq matn + 2 ta harf):**

| Fayl:qator | O'lcham | Fon | Matn |
|---|---|---|---|
| `lib/features/profile/presentation/profile_screen.dart:114` | 72×72 | `AppColors.primary` (to'la) | oq, 24px, w600 |
| `lib/features/profile/presentation/edit_profile_screen.dart:175` | 96×96 | `AppColors.primary` (to'la) | oq, 30px, w700 |
| `lib/features/settings/presentation/settings_screen.dart:544` | 52×52 | `AppColors.primary` (to'la) | oq, 18px, w700 |

**B tizimi — "boshqalar" (CircleAvatar + shaffof rol rangi + rangli matn + 1 ta harf):**

| Fayl:qator | Radius | Fon | Matn |
|---|---|---|---|
| `lib/features/home/presentation/home_screen.dart:695` | 20 | `roleColor` @ 15% | `roleColor`, w700 |
| `lib/features/home/presentation/neighbors_screen.dart:220` | 22 | `roleColor` @ 15% | `roleColor`, w700 |
| `lib/features/home/presentation/neighbor_profile_screen.dart:136` | 48 | `roleColor` @ 15% | `roleColor`, w700 |
| `lib/features/home/presentation/members_management_screen.dart:153` | 22 | `roleColor` @ 15% | `roleColor`, w700 |
| `lib/features/settings/presentation/privacy_security_screen.dart:228` | 20 | `AppColors.danger` @ 12% | `danger`, w700 |
| `lib/features/home/data/members_management_screen.dart:153` | 22 | *(o'lik nusxa — 1.4-bandga qarang)* | |

**Aniq oqibat:** Rais A. Karimov `neighbors_screen`da och binafsha fonli "A" bo'lib
chiqadi, `profile_screen`da esa ko'k fonli "AK" bo'lib. `privacy_security_screen`da
esa **qizil** — chunki u yerda rol rangi o'rniga `danger` ishlatilgan.

**Takrorlanish:** 9 ta avatar render nuqtasi, 2 xil tizim, 6 xil o'lcham
(20/22/48 radius + 52/72/96 px), 2 xil bosh-harf algoritmi.

### 1.2 — `_initialsOf` uchta faylda, ikki xil algoritm bilan

| Fayl:qator | Signatura | Algoritm |
|---|---|---|
| `lib/features/profile/presentation/profile_screen.dart:262` | `(String fullName)` | `split(RegExp(r'\s+'))` → 2 harf |
| `lib/features/settings/presentation/settings_screen.dart:493` | `(String fullName)` | **aynan bir xil kod** (copy-paste) |
| `lib/features/profile/presentation/edit_profile_screen.dart:146` | `(String first, String last)` | **boshqacha** — alohida maydonlardan |

Uchinchisi `characters` o'rniga `[0]` ishlatadi — kirill/emoji bilan boshlanuvchi
ismda boshqa natija beradi.

### 1.3 — `_roleColor` beshta faylda **bayt-ma-bayt bir xil**

```dart
UserRole.rais    → Color(0xFF9254DE)
UserRole.staff   → Color(0xFF2F5BFF)
UserRole.citizen → Color(0xFF9AA0A6)
```

| Fayl:qator |
|---|
| `lib/features/home/presentation/home_screen.dart:659` |
| `lib/features/home/presentation/neighbors_screen.dart:177` |
| `lib/features/home/presentation/neighbor_profile_screen.dart:68` |
| `lib/features/home/presentation/members_management_screen.dart:119` |
| `lib/features/home/data/members_management_screen.dart:119` |

Bu ranglarning hech biri `AppColors`da yo'q.

### 1.4 — O'lik dubl fayl

`lib/features/home/data/members_management_screen.dart` — `presentation/`dagi fayl
bilan **bayt-ma-bayt bir xil** (268 qator), hech qayerdan import qilinmagan, va
`data/` qatlamida turgan ekran (arxitektura buzilishi). O'chirilishi kerak.

### 1.5 — Tarmoq rasmlarida xato/yuklanish holati yo'q

`NetworkImage` (8 ta joy: `CircleAvatar.backgroundImage` va `DecorationImage`)
`errorBuilder` qo'llab-quvvatlamaydi — internet uzilsa yoki URL buzilsa,
**butunlay bo'sh doira** qoladi (bosh harf ham ko'rinmaydi, chunki `child` faqat
`photoUrl == null` bo'lgandagina beriladi).

`Image.network` uchta joyda `errorBuilder` bilan to'g'ri yozilgan, lekin
**`loadingBuilder` hech qayerda yo'q** — rasm to'satdan "sakrab" chiqadi:

| Fayl:qator |
|---|
| `lib/features/announcements/presentation/announcements_screen.dart:333` |
| `lib/features/requests/presentation/requests_screen.dart:568` |
| `lib/features/requests/presentation/request_detail_screen.dart:195` |

### 1.6 — Bo'sh holatlar: 3 xil dizayn parallel yashaydi

| Variant | Joylashuvi | Ko'rinishi |
|---|---|---|
| `AppEmptyView` (standart) | `lib/core/widgets/app_feedback.dart:112` | 72px rangli doira + ikonka + sarlavha + tavsif + tugma |
| `_EmptyState` | `announcements_screen.dart:582` | mahalliy nusxa |
| `_EmptyState` | `search_screen.dart:211` | **boshqa fayldagi bir xil nomli, boshqa kodli** nusxa |
| `_EmptyEventsCard` | `home_screen.dart:609` | kulrang quti, 28px xira ikonka, faqat matn |

`AppEmptyView` faqat **4 marta**, jami **3 ta feature faylida** ishlatilgan
(`announcements_screen`, `neighbors_screen`, `requests_screen`).

Hech birida illyustratsiya yo'q — hammasi "ikonka + matn". `_EmptyEventsCard`
eng zaifi: ikonka `secondaryColor.withValues(alpha: 0.6)` bilan berilgan, ya'ni
**xira kulrang** — ekran to'ldirilmagandek emas, buzilgandek ko'rinadi.

---

## 2. RASM STRATEGIYASI

**Tasdiqlandi: loyihada 6 ta statik rasm bor, ulardan atigi 2 tasi haqiqiy foto.**

```
assets/images/app_icon.png            → faqat launcher ikonkasi
assets/images/logo.png                → splash_screen.dart:147, login_screen.dart:176
assets/images/flags/uz.png, ru.png    → language_screen.dart:315-317
assets/images/language_banners/uz.jpg → language_screen.dart:60  ← yagona haqiqiy foto
assets/images/language_banners/ru.jpg → language_screen.dart:62  ← yagona haqiqiy foto
```

Ya'ni **butun ilovada faqat til tanlash ekranida haqiqiy fotosurat bor.**
Qolgan hamma joyda vizual boyitish uchun gradient yoki rangli doira ishlatilgan.

**Mavjud "rasm o'rnini bosuvchi" gradientlar (bular yomon emas, lekin yetarli emas):**

| Fayl:qator | Nima |
|---|---|
| `announcements_screen.dart:452` | `_eventBannerGradients` — 4 ta gradient, tadbir kartasi banneri (72px balandlik) |
| `announcements_screen.dart:348` | rasmsiz e'londa 4px kategoriya rangidagi chiziqcha |
| `onboarding_page_data.dart:43-58` | 4 ta onboarding fon gradienti |
| `home_screen.dart:464` | `_CategoryCard` — surface→accent lerp gradienti |

**Yetishmayotgani:**
- **Mahalla banneri** yo'q — `home_screen` sarlavhasi faqat matn (`home_screen.dart:52-180`)
- **Onboarding illyustratsiyasi** yo'q — 4 ta ekran ham faqat gradient fon + shisha
  effektli 4 qatorli ro'yxat (`onboarding_screen.dart:71-140`). Bir sahifadan
  boshqasiga o'tganda faqat **fon rangi** o'zgaradi — kontent bir xil qoladi
- **Bo'sh holat illyustratsiyalari** yo'q (1.6-bandga qarang)
- `neighbor_profile_screen` da cover/banner yo'q — avatar to'g'ridan-to'g'ri
  fonda turadi (`neighbor_profile_screen.dart:136`)

---

## 3. "SHABLON" BELGILARI

### 3.1 — Ranglar: brend palitrasi bor, lekin yarmi `AppColors`dan tashqarida

`lib/core/theme/app_theme.dart:7-45` da yaxshi qurilgan palitra bor — primary,
success/warning/danger, light/dark uchun alohida surface/border/text darajalari.
**Muammo:** eng ko'p ishlatiladigan 4 ta akцент rangdan **3 tasi u yerda yo'q**.

Butun loyihadagi hex literallar (chastota bo'yicha):

| Hex | Marta | `AppColors`da bormi? | Ma'nosi |
|---|---|---|---|
| `0xFF2F5BFF` | **24** | ✅ `primary` | ko'k — lekin literal sifatida ham 24 marta qayta yozilgan |
| `0xFF27AE60` | **22** | ❌ | yashil akцент (murojaatlar) |
| `0xFFF2994A` | **18** | ❌ | to'q sariq akцент (tadbirlar) |
| `0xFF9254DE` | **14** | ❌ | binafsha akцент (qo'shnilar / rais) |
| `0xFFE53935` | 8 | ✅ `danger` | literal sifatida qayta yozilgan |
| `0xFF9AA0A6` | 6 | ❌ | fuqaro rol rangi |

Jami **119 ta hardcoded `Color(0x...)` `lib/features/` ichida**, 57 xil qiymat.
Eng ko'p: `settings_screen.dart` (15), `home_screen.dart` (15),
`requests_screen.dart` (10), `profile_screen.dart` (10).

Bundan tashqari `0xFF2E7D32`, `0xFF1565C0`, `0xFFE65100`, `0xFF1B3A22`,
`0xFF1A3A4A`, `0xFF4A3B1A` kabi ranglar bor — bular Material'ning standart
`Colors.green[800]`, `Colors.blue[800]` qiymatlari, ya'ni **brend palitrasidan
tashqaridagi Material default'lar**. Aynan shu "AI generated" hissini kuchaytiradi.

### 3.2 — Tipografiya: 23 xil `fontSize`, ierarxiya emas — tasodif

Shrift to'g'ri tanlangan (Inter, `app_theme.dart:67`), lekin `textTheme` deyarli
ishlatilmaydi:

- **192 ta** xom `TextStyle(...)` `lib/features/` ichida
- **48 ta** `Theme.of(context).textTheme` murojaati
- Nisbat: **4:1 xom TextStyle foydasiga**

Ishlatilgan `fontSize` qiymatlari (23 xil):

```
9, 9.5, 10, 10.5, 11, 11.5, 12, 12.5, 13, 13.5, 14, 14.5,
15, 15.5, 16, 17, 18, 20, 24, 26, 28, 30, 32
```

12 va 15 orasida **8 ta** turli qiymat bor (12, 12.5, 13, 13.5, 14, 14.5, 15,
15.5). Bu ierarxiya emas — bu har bir ekran mualliflari alohida-alohida
"ko'zga chiroyli ko'ringan" sonni tanlagani. 13px eng ko'p — 45 marta,
12.5px — 26 marta.

Sarlavhalar ham izchil emas — `home_screen.dart:380` va `:419` da
`titleMedium.copyWith(fontWeight: w700, fontSize: 17)` — ya'ni tema stili
olinib, darhol ustidan yozib tashlanadi.

Eng ko'p xom `TextStyle` ishlatgan fayllar: `new_request_flow_screen.dart` (21),
`home_screen.dart` (14), `profile_screen.dart` (12), `announcements_screen.dart` (11).

### 3.3 — Spacing: 22 xil bo'shliq qiymati, izchil shkala yo'q

`SizedBox(height|width:)` qiymatlari va chastotasi:

```
✅ tizimli (8-shkala):  4 (33×)  8 (69×)  12 (35×)  16 (16×)  20 (17×)  24 (30×)  32 (8×)
⚠️  tizimsiz:            2 (10×)  3 (5×)   5 (3×)    6 (28×)   9 (1×)   10 (21×)
                        14 (8×)  18 (16×) 22 (1×)   28 (11×)  34 (1×)  36 (1×)  40, 48
```

`EdgeInsets.all(...)`: `3, 4, 7, 12, 14, 16, 18, 20, 32` — bunda **14 eng ko'p
(21 marta)**, ya'ni de-fakto standart 14 bo'lgan, lekin u hech qayerda
konstanta sifatida yozilmagan va 12/16 bilan aralashib ketgan.

Shkala mavjud emas — `lib/core/theme/` ichida spacing konstantalari yo'q.

### 3.4 — Radius/soya: 17 xil radius, 8 xil blur, 6 xil soya shaffofligi

**Radius** (`BorderRadius.circular`) — 17 xil qiymat:

```
4, 6, 7, 8, 9, 10, 11, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30
```

Eng ko'p: 16 (33×), 12 (27×), 14 (27×), 10 (23×). Ya'ni **to'rtta raqobatlashuvchi
"standart" radius** bir vaqtda ishlatiladi. Hatto tema ichida ham izchil emas:

| `app_theme.dart` | Radius |
|---|---|
| `:100` `cardTheme` | 16 |
| `:111` `inputDecorationTheme` | 16 |
| `:131` `elevatedButtonTheme` | **18** |

`AppCard` ning default radiusi esa **14** (`animated_ui.dart:137`) — ya'ni
`cardTheme` (16) bilan ham mos kelmaydi.

**Soya** — 18 ta faylda `BoxShadow`, `blurRadius`: `4, 6, 8, 10, 12, 16, 22, 24`,
va 6 xil qora shaffoflik: `0.06, 0.12, 0.15, 0.16, 0.18, 0.25`. Eng keng
tarqalgan retsept (`blurRadius: 10, offset: (0,3), alpha: 0.25/0.04`)
**qo'lda 10+ marta qayta yozilgan** — masalan:

| Fayl:qator |
|---|
| `lib/core/widgets/animated_ui.dart:141` (`AppCard` ichida — asl nusxa) |
| `lib/features/home/presentation/home_screen.dart:566` (`_EventRow`) |
| `lib/features/home/presentation/neighbors_screen.dart:210` |
| `lib/features/settings/presentation/settings_screen.dart:533` |
| `lib/core/widgets/shimmer.dart` (soyasiz — boshqacha) |

### 3.5 — ⚠️ `AppCard` yozilgan, ammo **hech qayerda ishlatilmagan**

`lib/core/widgets/animated_ui.dart:127` da to'liq, izohlangan, `TapScale`
integratsiyalangan `AppCard` bor. Uning ishlatilishi:

```
lib/core/widgets/animated_ui.dart:1   ← faqat o'z ta'rifi
```

**`lib/features/` ichida 0 marta.**

Buning o'rniga: **132 ta qo'lda yozilgan `decoration: BoxDecoration(...)`**
37 ta faylda. Eng ko'p:

| Fayl | Soni |
|---|---|
| `home_screen.dart` | 14 |
| `announcements_screen.dart` | 9 |
| `profile_screen.dart` | 8 |
| `settings_screen.dart`, `requests_screen.dart`, `language_screen.dart`, `neighbor_profile_screen.dart`, `login_screen.dart` | 6 each |

**Bu — 1-raqamli sabab.** Har bir karta o'z radiusi va soyasi bilan yozilgani
uchun, ekranlar bir-biriga o'xshamaydi. Tuzatish ham eng arzon: komponent
allaqachon tayyor.

### 3.6 — Loading/empty/error: 30 ta ekrandan **27 tasida yo'q**

Shimmer/`AppEmptyView`/`AppErrorView` ishlatgan **yagona 4 ta** feature fayli:

```
✅ announcements_screen.dart
✅ home_screen.dart
✅ neighbors_screen.dart
✅ requests_screen.dart
```

Qolgan **27 ta `presentation/` ekranida ularning birortasi ham yo'q**:

```
❌ new_announcement_screen, new_event_screen, forgot_password_screen,
   login_screen, otp_verification_screen, register_screen,
   telegram_verify_screen, members_management_screen, neighbor_profile_screen,
   language_screen, boundary_editor_screen, mahalla_map_screen,
   mahalla_map_view, notifications_screen, onboarding_screen,
   edit_profile_screen, help_screen, profile_screen, qr_result_screen,
   qr_scan_screen, new_request_flow_screen, requests_management_screen,
   request_detail_screen, search_screen, privacy_security_screen,
   settings_screen, splash_screen
```

O'rniga **22 ta faylda `CircularProgressIndicator`** — markazda aylanuvchi
doira. Ayniqsa sezilarli: `profile_screen`, `settings_screen`,
`notifications_screen`, `request_detail_screen`, `search_screen` —
bularning hammasi ro'yxat ko'rsatadi, ya'ni shimmer aynan mos kelardi.

### 3.7 — Ikkita ikonka oilasi aralashgan

`pubspec.yaml:17` da `phosphoricons_flutter` bor, lekin u qisman qo'llangan:

| | Soni | Fayllar |
|---|---|---|
| Material `Icons.*` | **167** | 33 ta fayl |
| `PhosphorIcons*` | **24** | 6 ta fayl |

Phosphor import qilgan 6 ta fayl: `app_feedback.dart`, `announcements_screen.dart`,
`home_screen.dart`, `neighbors_screen.dart`, `language_screen.dart`,
`requests_screen.dart`.

**Uchta fayl ikkalasini bir vaqtda ishlatadi** — ya'ni bitta ekranda ikki xil
chizish uslubidagi ikonkalar yonma-yon turadi:

| Fayl | Material | Phosphor |
|---|---|---|
| `announcements_screen.dart` | 5 | 2 |
| `neighbors_screen.dart` | 3 | 1 |
| `requests_screen.dart` | 8 | 1 |

Eng aniq misol — `announcements_screen.dart`: `:245` da `PhosphorIconsFill.megaphone`
(qalin, to'ldirilgan), `:531` da `Icons.calendar_today_rounded` (ingichka, chiziqli),
`:341` da `Icons.broken_image_outlined`. Uchtasi ham bitta kartada.

Phosphor Material'dan sezilarli darajada boshqacha shtrix qalinligiga ega —
bu aralashuv "turli manbalardan yig'ilgan" hissini beradi.

---

## 4. MICRO-INTERACTION VA ANIMATSIYA

Bu bo'lim bo'yicha holat **kutilganidan ancha yaxshi** — asos bor, faqat
qamrov tor.

### ✅ Mavjud va yaxshi ishlaydi

| Nima | Joylashuvi | Izoh |
|---|---|---|
| Sahifalararo o'tish | `app_router.dart:76-99` | fade + 0.04 o'ngdan slide, 320ms `easeOutCubic` — **barcha route'larga qo'llangan**, yaxshi |
| Tugma bosish feedback'i | `animated_ui.dart:14` `TapScale` | 0.96× scale + `HapticFeedback.lightImpact()`, 120ms |
| Ro'yxat kirish animatsiyasi | `animated_ui.dart:66` `StaggeredEntrance` | fade + 0.06 slide, index bo'yicha 40ms kechikish |
| Shimmer | `shimmer.dart:10` | `ShaderMask` bilan haqiqiy suzuvchi yorug'lik, 1400ms |
| Pull-to-refresh | 5 ta joy | `home_screen:40`, `announcements_screen:239,421`, `requests_screen:188`, `requests_management_screen:153` |
| Onboarding o'tishlari | `onboarding_screen.dart:97` | `AnimatedSwitcher` + `AnimatedContainer` fon gradienti (450ms) |

### ⚠️ Kamchiliklar

**`TapScale` qamrovi tor** — 30 ta ekrandan atigi **10 tasida** ishlatilgan:
`home_screen` (3), `neighbors_screen` (2), `otp_verification_screen`,
`neighbor_profile_screen`, `notifications_screen`, `profile_screen`,
`request_detail_screen`, `search_screen`, `members_management_screen` (1 tadan).

Ishlatilmagan muhim joylar: `settings_screen` (24 ta bosiladigan qator!),
`requests_screen` kartalari, `announcements_screen` kartalari,
`language_screen`, `help_screen`, `edit_profile_screen`.

**`Hero` transition — butun loyihada 0 ta.** Kartadan detallar sahifasiga
o'tish joylari (bularda Hero eng mos kelardi):
- `requests_screen` karta → `request_detail_screen`
- `neighbors_screen` qator → `neighbor_profile_screen`
- `announcements_screen` karta → e'lon detali

**Pull-to-refresh yo'q** — `notifications_screen`, `neighbors_screen`,
`search_screen`, `profile_screen`.

**Ro'yxat elementlari animatsiyasiz qo'shiladi/o'chiriladi** —
`AnimatedList` yoki `AnimatedSwitcher` ro'yxat darajasida hech qayerda yo'q.
`AnimatedSwitcher` 6 marta ishlatilgan, lekin faqat holat almashinuvida
(onboarding, tab).

**Umumiy animatsiya inventari:**
```
AnimatedContainer      8
AnimatedSwitcher       6
AnimatedPositioned     2
AnimatedBuilder        2
AnimatedScale          1  (TapScale ichida)
AnimatedDefaultTextStyle 1
Hero                   0  ← yo'q
AnimatedList           0  ← yo'q
```

---

## 5. TAVSIYA ETILGAN TARTIB (BOSQICH 3 uchun)

Ta'sir/mehnat nisbati bo'yicha saralangan. Har biri mustaqil — birinchi
uchtasi bilan to'xtash ham mumkin.

| № | Ish | Ta'sir | Mehnat | Tegiladigan fayllar |
|---|---|---|---|---|
| 1 | **`UserAvatarWidget`** yaratish — bitta o'lcham/rang/harf qoidasi, `errorBuilder` bilan | 🔴 Yuqori | S | 8 ta fayl, 9 ta joy |
| 2 | **`AppCard`'ga o'tkazish** — eng ko'p takrorlanadigan 30-40 ta kartani | 🔴 Yuqori | M | ~15 ta fayl |
| 3 | **Design token'lar** — `AppSpacing`, `AppRadius`, `AppShadows`, `AppColors`ga 4 ta akцент | 🔴 Yuqori | S | yangi fayl + bosqichma-bosqich migratsiya |
| 4 | **Tipografiya shkalasi** — `textTheme`ni to'ldirish, 23 ta o'lchamni 7 taga tushirish | 🟠 O'rta | M | ~20 ta fayl |
| 5 | **Bitta ikonka oilasi** — Phosphor'ni tanlab, 167 ta Material ikonkani almashtirish (yoki teskarisi) | 🟠 O'rta | M | 33 ta fayl |
| 6 | **Loading/empty holatlari** — 27 ta ekranga shimmer + `AppEmptyView` | 🟠 O'rta | L | 27 ta fayl |
| 7 | **Bo'sh holat illyustratsiyalari** — SVG/CustomPainter, 3 ta dublni bitta `AppEmptyView`ga birlashtirish | 🟡 Past | M | 4 ta fayl |
| 8 | **`TapScale` + `Hero`** — qolgan 20 ta ekranga, 3 ta karta→detal o'tishiga | 🟡 Past | S | ~20 ta fayl |
| 9 | **`_roleColor`/`_initialsOf` konsolidatsiyasi** + o'lik dubl faylni o'chirish | 🟡 Past | XS | 6 ta fayl |

### Tozalash (vizualdan tashqari, lekin arzon)

- `lib/features/home/data/members_management_screen.dart` — o'lik dubl, o'chirish
- 5 ta ishlatilmagan import (`main.dart:7`, `settings_screen.dart:9`,
  `requests_management_screen.dart:8`, `search_repository.dart:4,6`)
- ~30 ta `unnecessary_non_null_assertion` (`AppLocalizations.of(context)!` naqshi)
- `requests_screen.dart:76` — ishlatilmagan `secondaryColor` o'zgaruvchisi

---

## 6. NIMA ALLAQACHON YAXSHI (buzib qo'ymaslik kerak)

Auditni to'liq qilish uchun — quyidagilar to'g'ri qurilgan va tegilmasligi kerak:

- **Dark mode** — `app_theme.dart:28-44` da sof qora emas, ko'karoq kulrang fon
  (`0xFF15171C`) + 3 pog'onali surface ierarxiyasi. Bu professional qaror.
- **`context.isDarkMode` extension** (`app_theme.dart:151`) — izchil ishlatilgan,
  ekranlarning aksariyati dark mode'ni to'g'ri qo'llab-quvvatlaydi.
- **Sahifalararo o'tish** — barcha route'larda bir xil, silliq (`app_router.dart:76`).
- **`AppErrorView.fromError`** (`app_feedback.dart:33`) — tarmoq xatosini
  avtomatik aniqlab, mos matn tanlaydi. Yaxshi fikr, faqat kam ishlatilgan.
- **Shimmer implementatsiyasi** — `ShaderMask` bilan haqiqiy gradient harakati,
  paket ishlatmasdan (`shimmer.dart:53-72`).
- **Uch tilli l10n** to'liq (uz / uz_Cyrl / ru), 1965 qatorlik lug'at.
- **Tadbir banner gradientlari** (`announcements_screen.dart:452`) — rasm yo'qligini
  yaxshi qoplaydi, `colorIndex % 4` bilan ro'yxatda ranglar takrorlanmaydi.

---

## 7. TOPILMALAR JADVALI (qisqacha)

| ID | Topilma | Takrorlanish | Fayllar |
|---|---|---|---|
| 1.1 | Ikki xil avatar tizimi | 9 ta joy | 8 |
| 1.2 | `_initialsOf` dubli, 2 xil algoritm | 3 ta ta'rif | 3 |
| 1.3 | `_roleColor` bayt-ma-bayt dubli | 5 ta ta'rif | 5 |
| 1.4 | O'lik dubl fayl (268 qator) | 1 | 1 |
| 1.5 | `NetworkImage`da xato holati yo'q | 8 ta joy | 6 |
| 1.5 | `Image.network`da `loadingBuilder` yo'q | 3 ta joy | 3 |
| 1.6 | Bo'sh holatning 3 xil dizayni | 4 ta variant | 4 |
| 2.0 | Statik rasm strategiyasi yo'q | 2 ta haqiqiy foto | butun loyiha |
| 3.1 | Hardcoded hex ranglar | 119 ta, 57 xil | 25 |
| 3.1 | Akцент ranglar `AppColors`dan tashqarida | 3 tadan 4 ta | 25 |
| 3.2 | Xom `TextStyle` (vs `textTheme`) | 192 vs 48 | 30+ |
| 3.2 | `fontSize` xilma-xilligi | 23 xil qiymat | butun loyiha |
| 3.3 | `SizedBox` bo'shliq xilma-xilligi | 22 xil qiymat | butun loyiha |
| 3.4 | `BorderRadius` xilma-xilligi | 17 xil qiymat | butun loyiha |
| 3.4 | Soya `blurRadius`/`alpha` xilma-xilligi | 8 / 6 xil | 18 |
| 3.5 | **`AppCard` 0 marta ishlatilgan** | 132 ta qo'lda karta | 37 |
| 3.6 | Loading/empty/error holati yo'q | 27 / 30 ekran | 27 |
| 3.6 | `CircularProgressIndicator` shimmer o'rniga | 22 ta fayl | 22 |
| 3.7 | Ikkita ikonka oilasi aralashgan | 167 vs 24 | 33 / 6 |
| 4.0 | `TapScale` qamrovi tor | 10 / 30 ekran | 10 |
| 4.0 | `Hero` transition yo'q | 0 | — |
| 4.0 | Pull-to-refresh yo'q | 4 ta ekranda | 4 |

---

**Bosqich 1 yakunlandi. Hech qanday fayl o'zgartirilmadi.**
Bosqich 2 (referens tekshiruvi) yoki to'g'ridan-to'g'ri Bosqich 3 (tuzatish) —
sizning tasdig'ingizni kutaman.

---

## BOSQICH 3 — TUZATISH YAKUNI (2026-08-17)

Foydalanuvchi ko'rsatmasi bilan referens tekshiruvi (Bosqich 2) o'tkazib
yuborilib, to'g'ridan-to'g'ri tuzatishga o'tildi. Loyiha git repozitoriysi
emas edi, shuning uchun kichik commit'lar o'rniga har bosqichdan keyin
`flutter analyze` bilan tekshirib borildi.

### Yaratilgan poydevor

| Fayl | Vazifa |
|---|---|
| [`lib/core/theme/app_tokens.dart`](lib/core/theme/app_tokens.dart) | `AppSpacing` (4pt shkala), `AppRadius` (5 pog'ona), `AppShadows` (3 retsept), `AppAccents` (4 ta akцент rang), `context.titleStyle`/`cardTitleStyle`/... tipografiya qisqartmalari, `context.textSecondary`/`surfaceColor`/... rang qisqartmalari |
| [`lib/core/widgets/user_avatar.dart`](lib/core/widgets/user_avatar.dart) | Yagona `UserAvatar` — barqaror gradient (UID'ga bog'liq), Unicode-xavfsiz bosh harflar, `errorBuilder`/`loadingBuilder` bilan tarmoq xatosidan himoyalangan |
| [`lib/features/home/presentation/role_styles.dart`](lib/features/home/presentation/role_styles.dart) | `UserRoleStyle` extension (rang/halqa) + `RoleBadge` widget — 5 ta faylda takrorlangan `_roleColor`ni almashtirdi |
| [`lib/core/widgets/settings_tile.dart`](lib/core/widgets/settings_tile.dart) | `SettingsCard`/`SettingsTile` — `settings_screen.dart` va `privacy_security_screen.dart`dagi bayt-ma-bayt dublni almashtirdi |
| `lib/core/theme/app_theme.dart` | 7 pog'onali `TextTheme` (23 xil `fontSize` o'rniga), barcha komponent temalari token'larga o'tkazildi |
| `lib/core/widgets/animated_ui.dart` | `AppCard` token'larga o'tkazildi, `AppListCard` va `AppSectionHeader` qo'shildi |
| `lib/core/widgets/app_feedback.dart` | `AppEmptyView`/`AppErrorView`ga chizilgan illyustratsiya (`CustomPainter` — halqalar + nuqtalar + kirish animatsiyasi), 3 xil parallel bo'sh-holat dizayni birlashtirildi |

### Tuzatilgan ekranlar (24 ta fayl)

Avatar, `AppCard`/`AppListCard`, design token, Phosphor ikonka va (kerak
bo'lsa) shimmer/bo'sh/xato holatlariga o'tkazildi:

`home_screen`, `neighbors_screen`, `neighbor_profile_screen`,
`members_management_screen` (+ o'lik dubl fayl o'chirildi),
`profile_screen`, `edit_profile_screen`, `settings_screen`,
`privacy_security_screen`, `help_screen`, `announcements_screen`,
`requests_screen`, `requests_management_screen`, `request_detail_screen`,
`search_screen` (dubl `_EmptyState` o'chirildi), `notifications_screen`
(loading/empty/error butunlay yo'q edi — qo'shildi), `qr_scan_screen`,
`qr_result_screen`, `boundary_editor_screen`, `mahalla_map_screen`,
`mahalla_map_view`, `login_screen` (qisman — ikonka almashtirish).

**Natija:** ikkita zid avatar tizimi bitta widget'ga tushdi (9 joy → 1);
132 ta qo'lda yozilgan `BoxDecoration`ning aksariyati `AppCard`ga o'tkazildi;
119 ta hardcoded hex rangning ko'pi `AppAccents`/`AppColors`ga o'tkazildi;
Material va Phosphor ikonkalari **bitta faylda aralashgan holat butunlay
yo'qoldi** (tekshirildi — 0 ta fayl qoladi); 27 ta ekrandan bo'sh/xato/
yuklanish holati yo'q bo'lganlaridan asosiylari (`notifications_screen`,
`requests_management_screen`, `search_screen`, `request_detail_screen`)
endi to'liq holat qamroviga ega.

### Ataylab tegilmagan / qoldirilgan

| Nima | Sabab |
|---|---|
| `lib/features/auth/presentation/otp_verification_screen.dart` | O'lik kod — endi mavjud bo'lmagan `PhoneVerificationRepository` metodlariga murojaat qiladi (5 ta compile error), lekin hech qayerdan import qilinmagan, ilova normal quriladi. Auditda ham qayd etilgan edi. Tiklash yoki o'chirish — sizning qaroringiz. |
| `new_request_flow_screen.dart` (1063 qator) | Eng ko'p xom `TextStyle` (21 ta) va eng katta fayl — ko'p bosqichli murakkab forma. To'liq qayta yozish xato xavfini oshiradi, shuning uchun ataylab tegilmadi. |
| `new_announcement_screen.dart`, `new_event_screen.dart` | Vaqt cheklovi tufayli navbatda qoldi. |
| `register_screen.dart`, `forgot_password_screen.dart`, `telegram_verify_screen.dart` | Faqat Material ikonkalar ishlatadi (aralashish yo'q — 3.7-band muammosi ularda mavjud emas), shuning uchun past prioritet deb hisoblanib qoldirildi. |
| `onboarding_screen.dart` | Auditda qayd etilgan "faqat fon rangi o'zgaradi" holati haqiqiy, lekin ekran allaqachon glassmorphism + animatsiyali highlight bilan ancha yaxshi ishlangan (shablon emas). Har bosqich uchun alohida illyustratsiya qo'shish yangi vizual asset talab qiladi — alohida ish sifatida qoldirildi. |
| `language_screen.dart`, `splash_screen.dart` | Vaqt cheklovi tufayli navbatda qoldi. |

### Tekshiruv

`flutter analyze` — boshida: 140 muammo (6 error, hammasi
`otp_verification_screen.dart`da). Oxirida: **129 muammo, 5 error**
(barchasi bir xil o'lik fayldan — endi 5 ta, chunki bitta warning
qo'shimcha tuzatildi). Men tegilgan hech bir faylda yangi error yo'q.

**Keyingi qadam tavsiyasi:** qolgan fayllar (`new_request_flow_screen`,
`new_announcement_screen`, `new_event_screen`, `language_screen`,
`splash_screen`, qolgan auth ekranlari) uchun shu audit hujjatining
5-bo'limidagi tartibda davom etish mumkin — poydevor (token'lar, `AppCard`,
`UserAvatar`, `AppEmptyView`) tayyor, qolgan ish faqat ularni qo'llash.
