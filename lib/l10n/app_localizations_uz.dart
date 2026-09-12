// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Mening Mahallam';

  @override
  String get splashTagline => 'Sizning mahallangiz bitta ilovada';

  @override
  String get onboardingWelcomeTitle => 'Xush kelibsiz!';

  @override
  String get onboardingWelcomeDescription =>
      'Mening Mahallam — mahallangiz bitta ilovada. Keling, imkoniyatlar bilan tanishtiraman.';

  @override
  String get onboardingAnnouncementsTitle => 'Har doim xabardor bo\'ling';

  @override
  String get onboardingAnnouncementsDescription =>
      'Mahallangizdagi yangiliklar va e\'lonlar to\'g\'ridan-to\'g\'ri qo\'lingizda';

  @override
  String get onboardingEventsTitle => 'Tadbirlarni o\'tkazib yubormang';

  @override
  String get onboardingEventsDescription =>
      'Yig\'in, bayram yoki tadbir bo\'lsa — birinchilardan bo\'lib bilib olasiz';

  @override
  String get onboardingRequestsTitle => 'Muammoni bir necha bosishda yeching';

  @override
  String get onboardingRequestsDescription =>
      'Ko\'chada nosozlik ko\'rdingizmi? Murojaat yuboring, rais va xodimlar darhol ko\'radi';

  @override
  String get onboardingNeighborsTitle => 'Qo\'shnilaringiz bilan bog\'laning';

  @override
  String get onboardingNeighborsDescription =>
      'Ko\'changizdagilarni toping, suhbatlashing, birga mahallani yaxshilang';

  @override
  String get previewAnnouncements => 'E\'lonlar';

  @override
  String get previewEvents => 'Tadbirlar';

  @override
  String get previewRequests => 'Murojaatlar';

  @override
  String get previewNeighbors => 'Qo\'shnilar';

  @override
  String get continueButton => 'Davom etish';

  @override
  String get skipButton => 'O\'tkazib yuborish';

  @override
  String get loginButton => 'Kirish';

  @override
  String get registerButton => 'Ro\'yxatdan o\'tish';

  @override
  String get loginTitle => 'Kirish';

  @override
  String get loginSubtitle => 'Ma\'lumotlaringizni kiriting';

  @override
  String get phoneLabel => 'Telefon raqam';

  @override
  String get passwordLabel => 'Parol';

  @override
  String get forgotPassword => 'Parolni unutdingizmi?';

  @override
  String get orDivider => 'yoki';

  @override
  String get noAccountQuestion => 'Hisobingiz yo\'qmi? ';

  @override
  String get phoneValidationError => 'Telefon raqamni to\'liq kiriting';

  @override
  String get passwordValidationError =>
      'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';

  @override
  String get unexpectedError => 'Kutilmagan xatolik yuz berdi';

  @override
  String get registerTitle => 'Ro\'yxatdan o\'tish';

  @override
  String get registerSubtitle => 'Yangi hisob yaratish';

  @override
  String get firstNameLabel => 'Ism';

  @override
  String get lastNameLabel => 'Familiya';

  @override
  String get firstNameValidationError => 'Ismingizni kiriting';

  @override
  String get lastNameValidationError => 'Familiyangizni kiriting';

  @override
  String get haveAccountQuestion => 'Hisobingiz bormi? ';

  @override
  String get welcomeGreeting => 'Xush kelibsiz';

  @override
  String helloUser(String name) {
    return 'Assalomu alaykum, $name!';
  }

  @override
  String get helloGeneric => 'Assalomu alaykum!';

  @override
  String get guestName => 'mehmon';

  @override
  String get searchHint => 'Qidirish...';

  @override
  String get categoryAnnouncements => 'E\'lonlar';

  @override
  String get categoryEvents => 'Tadbirlar';

  @override
  String get categoryRequests => 'Murojaatlar';

  @override
  String get categoryNeighbors => 'Qo\'shnilar';

  @override
  String get upcomingEventsTitle => 'Yaqin tadbirlar';

  @override
  String get noUpcomingEvents => 'Hozircha yaqin tadbirlar yo\'q';

  @override
  String get eventsLoadError => 'Tadbirlarni yuklashda xatolik yuz berdi';

  @override
  String get today => 'Bugun';

  @override
  String get tomorrow => 'Ertaga';

  @override
  String get profileTitle => 'Profil';

  @override
  String get defaultUserName => 'Foydalanuvchi';

  @override
  String get profileLoadError => 'Ma\'lumotlarni yuklashda xatolik';

  @override
  String get chooseBannerTitle => 'Banner tanlang';

  @override
  String get premiumBannerLockedMessage =>
      'Bu banner premium — hozircha qulflangan';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumSettingSubtitle =>
      'Cheksiz murojaat, reklamasiz va boshqa imkoniyatlar';

  @override
  String get premiumHeroTitle => 'Premium obuna';

  @override
  String get premiumHeroSubtitle =>
      'Mahallangizda faolroq bo\'ling — cheklovlarsiz';

  @override
  String get premiumPerMonth => 'so\'m/oy';

  @override
  String get premiumBenefitsTitle => 'NIMALAR OCHILADI';

  @override
  String get premiumBenefitUnlimited => 'Cheksiz murojaat — kunlik limit yo\'q';

  @override
  String get premiumBenefitNoAds => 'Reklamalar umuman ko\'rinmaydi';

  @override
  String get premiumBenefitPriority => 'Murojaatingiz ro\'yxatda tepada turadi';

  @override
  String get premiumBenefitImages => 'Bitta murojaatga 10 tagacha rasm';

  @override
  String get premiumBenefitBanners => 'Maxsus profil bannerlari';

  @override
  String get premiumBenefitBadge => 'Profilingizda premium nishoni';

  @override
  String get premiumBuyAction => 'Premium olish';

  @override
  String get premiumActiveTitle => 'Premium faol';

  @override
  String premiumActiveUntil(String date, int days) {
    return '$date gacha — $days kun qoldi';
  }

  @override
  String get premiumTransferHint =>
      'Quyidagi kartaga o\'tkazma qiling. Nusxa olish uchun ustiga bosing.';

  @override
  String get premiumCardNumber => 'Karta raqami';

  @override
  String get premiumCardHolder => 'Karta egasi';

  @override
  String get premiumAmount => 'To\'lov summasi';

  @override
  String get premiumCardCopied => 'Karta raqami nusxalandi';

  @override
  String get premiumHolderCopied => 'Karta egasi nusxalandi';

  @override
  String get premiumAmountCopied => 'Summa nusxalandi';

  @override
  String premiumPaymentTimeLeft(String time) {
    return 'To\'lov uchun $time qoldi';
  }

  @override
  String get premiumPaymentExpired =>
      'To\'lov vaqti tugadi — qaytadan boshlang';

  @override
  String get premiumIPaidAction => 'To\'ladim';

  @override
  String get premiumContactAdmin => 'Admin bilan Telegramda';

  @override
  String get premiumTelegramHint =>
      'Tezroq tasdiqlash uchun chekni Telegramga yuboring — ixtiyoriy.';

  @override
  String get premiumWaitingTitle => 'Tasdiqlash kutilmoqda';

  @override
  String get premiumWaitingSubtitle =>
      'Admin to\'lovni tekshirgach premium ochiladi';

  @override
  String get premiumRequestsTitle => 'Premium so\'rovlari';

  @override
  String get premiumRequestsEmpty => 'Kutilayotgan so\'rov yo\'q';

  @override
  String premiumRequestMonths(int count) {
    return '$count oylik obuna';
  }

  @override
  String get premiumApproveAction => 'Tasdiqlash';

  @override
  String get premiumRejectAction => 'Rad etish';

  @override
  String get adLabel => 'Reklama';

  @override
  String get adManagementTitle => 'Xizmat reklamalari';

  @override
  String get adAddAction => 'Reklama qo\'shish';

  @override
  String get adEmptyTitle => 'Hozircha reklama yo\'q';

  @override
  String get adTitleLabel => 'Xizmat nomi';

  @override
  String get adDescriptionLabel => 'Qisqacha tavsif';

  @override
  String get adOwnerLabel => 'Usta / tashkilot nomi';

  @override
  String get adTitleRequired => 'Xizmat nomini kiriting';

  @override
  String get adSaveAction => 'Saqlash';

  @override
  String get adStatusActive => 'Faol';

  @override
  String get adStatusExpired => 'Tugagan';

  @override
  String adActiveUntil(String date) {
    return '$date gacha faol';
  }

  @override
  String get adExtendAction => '7 kunga uzaytirish';

  @override
  String get adPromoteTitle => 'Xizmatingizni reklama qiling';

  @override
  String adPromoteSubtitle(String price) {
    return 'Haftasiga $price — mahallangiz ko\'radi';
  }

  @override
  String get adPromoteAction => 'Reklama berish';

  @override
  String get noMahallaTitle => 'Avval mahallangizga qo\'shiling';

  @override
  String get noMahallaSubtitle =>
      'Mahalla raisi bergan QR kodni skanerlang — shundan keyin e\'lonlar, murojaatlar va qo\'shnilaringiz shu yerda ko\'rinadi.';

  @override
  String get noMahallaAction => 'QR kodni skanerlash';

  @override
  String get emptyAnnouncementsSubtitle =>
      'Mahalla raisi yoki xodimlari e\'lon joylaganda shu yerda ko\'rinadi.';

  @override
  String get emptyRequestsSubtitle =>
      'Mahallada muammo bo\'lsa, birinchi murojaatni siz yuborishingiz mumkin.';

  @override
  String get emptyRequestsAction => 'Murojaat yuborish';

  @override
  String get emptyNeighborsSubtitle =>
      'Qo\'shnilaringiz ilovaga qo\'shilgach shu yerda ko\'rinadi. Ularni taklif qiling!';

  @override
  String get emptyServicesSubtitle =>
      'Mahalladagi ustalar va xizmatlar shu yerda to\'planadi.';

  @override
  String get emptyEventsSubtitle =>
      'Rejalashtirilgan tadbirlar shu yerda ko\'rinadi.';

  @override
  String get premiumBadgeLabel => 'Premium';

  @override
  String get chooseBadgeStyleTitle => 'Belgi uslubini tanlang';

  @override
  String get premiumBadgeStyleGold => 'Oltin';

  @override
  String get premiumBadgeStyleSapphire => 'Safir';

  @override
  String get premiumBadgeStyleEmerald => 'Zumrad';

  @override
  String get premiumBadgeStyleRuby => 'Yoqut';

  @override
  String get premiumBadgeStyleSilver => 'Kumush';

  @override
  String dailyRequestLimitReached(Object count) {
    return 'Kunlik murojaat limitiga ($count ta) yetdingiz. Ertaga qayta urinib ko\'ring yoki Premium bilan cheksiz yuboring.';
  }

  @override
  String get myInfoMenuItem => 'Mening ma\'lumotlarim';

  @override
  String get notificationsMenuItem => 'Bildirishnomalar';

  @override
  String get settingsMenuItem => 'Sozlamalar';

  @override
  String get helpMenuItem => 'Yordam';

  @override
  String get logoutMenuItem => 'Chiqish';

  @override
  String get logoutConfirmTitle => 'Chiqishni tasdiqlang';

  @override
  String get logoutConfirmMessage => 'Haqiqatan ham tizimdan chiqmoqchimisiz?';

  @override
  String get cancelButton => 'Bekor qilish';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get sectionMahalla => 'Mahalla';

  @override
  String get currentMahalla => 'Joriy mahalla';

  @override
  String get notConnected => 'Bog\'lanmagan';

  @override
  String get unknownValue => 'Noma\'lum';

  @override
  String get changeButton => 'Almashtirish';

  @override
  String get changeMahallaTitle => 'Mahallani almashtirish';

  @override
  String get changeMahallaMessage =>
      'Yangi mahallaga QR kod skanerlash yoki kodni qo\'lda kiritish orqali bog\'lanasiz. Davom etasizmi?';

  @override
  String get sectionConvenience => 'Qulaylik';

  @override
  String get sectionGeneral => 'Umumiy';

  @override
  String get sectionManagement => 'Boshqaruv';

  @override
  String get membersManagementTitle => 'A\'zolarni boshqarish';

  @override
  String get noMembersYet => 'Hozircha a\'zolar yo\'q';

  @override
  String get roleUpdated => 'Rol yangilandi';

  @override
  String get selectRoleTitle => 'Rolni tanlang';

  @override
  String get languageSettingTitle => 'Til';

  @override
  String get languageUpdatedMessage => 'Til o\'zgartirildi';

  @override
  String get appearanceSettingTitle => 'Ko\'rinish';

  @override
  String get textSizeSettingTitle => 'Matn kattaligi';

  @override
  String get eyeComfortTitle => 'Ko\'z himoyasi';

  @override
  String get eyeComfortSubtitle => 'Ko\'k rangni kamaytiruvchi issiq filtr';

  @override
  String get sectionAbout => 'Ilova haqida';

  @override
  String get versionLabel => 'Versiya';

  @override
  String get statActiveRequests => 'Faol murojaatlar';

  @override
  String get statNewAnnouncements => 'Yangi e\'lonlar';

  @override
  String get statUpcomingEvents => 'Yaqin tadbirlar';

  @override
  String get myRequestsStat => 'Murojaatlarim';

  @override
  String get myAnnouncementsStat => 'E\'lonlarim';

  @override
  String get myJoinedStat => 'Qo\'shilganlarim';

  @override
  String get myRequestsTitle => 'Mening murojaatlarim';

  @override
  String get recentActivityTitle => 'So\'nggi faoliyat';

  @override
  String get mahallaStatsTitle => 'Mahalla statistikasi';

  @override
  String get statsTotalMembers => 'A\'zolar';

  @override
  String get statsActiveRequests => 'Faol murojaat';

  @override
  String get statsNewAnnouncements => 'Yangi e\'lon';

  @override
  String get statsUpcomingEvents => 'Yaqin tadbir';

  @override
  String get noRecentActivity => 'Hozircha faoliyat yo\'q';

  @override
  String get activityLoadError => 'Faoliyatni yuklashda xatolik yuz berdi';

  @override
  String activityNewAnnouncement(String title) {
    return 'Yangi e\'lon: $title';
  }

  @override
  String activityNewRequest(String title) {
    return 'Yangi murojaat: $title';
  }

  @override
  String activityNewEvent(String title) {
    return 'Yangi tadbir: $title';
  }

  @override
  String minutesAgo(int count) {
    return '$count daqiqa oldin';
  }

  @override
  String hoursAgo(int count) {
    return '$count soat oldin';
  }

  @override
  String daysAgo(int count) {
    return '$count kun oldin';
  }

  @override
  String get sectionAccount => 'Hisob';

  @override
  String get changePasswordTitle => 'Parolni o\'zgartirish';

  @override
  String get changePhoneTitle => 'Telefon raqamni o\'zgartirish';

  @override
  String get deleteAccountTitle => 'Hisobni o\'chirish';

  @override
  String get deleteAccountConfirmTitle => 'Hisobni o\'chirish';

  @override
  String get deleteAccountConfirmMessage =>
      'Bu amalni ortga qaytarib bo\'lmaydi. Barcha ma\'lumotlaringiz butunlay o\'chiriladi. Davom etasizmi?';

  @override
  String get deleteButton => 'O\'chirish';

  @override
  String get editButton => 'Tahrirlash';

  @override
  String get sectionDataStorage => 'Ma\'lumotlar va xotira';

  @override
  String get clearCacheTitle => 'Keshni tozalash';

  @override
  String get clearCacheSubtitle =>
      'Vaqtinchalik saqlangan fayllarni o\'chiradi';

  @override
  String get cacheClearedMessage => 'Kesh tozalandi';

  @override
  String get sectionSupport => 'Yordam va qo\'llab-quvvatlash';

  @override
  String get rateAppTitle => 'Ilovani baholash';

  @override
  String get feedbackTitle => 'Fikr bildirish';

  @override
  String get feedbackSubtitle =>
      'Ilova haqidagi fikringiz bizga muhim — mahalla rahbariyatiga to\'g\'ridan-to\'g\'ri yetadi.';

  @override
  String get feedbackRatingRequiredError =>
      'Iltimos, yulduzcha bilan baho bering';

  @override
  String get feedbackMessageLabel => 'Fikringiz (ixtiyoriy)';

  @override
  String get feedbackMessageHint => 'Nima yoqdi, nimani yaxshilash kerak?';

  @override
  String get feedbackSubmitButton => 'Yuborish';

  @override
  String get feedbackSubmittedMessage => 'Rahmat! Fikringiz yuborildi';

  @override
  String get feedbackModeRatingTab => 'Baho qoldirish';

  @override
  String get feedbackModeQuestionTab => 'Savol / Murojaat';

  @override
  String get feedbackQuestionTitle => 'Savol yoki murojaat';

  @override
  String get feedbackQuestionSubtitle =>
      'Savolingizni yoki murojaatingizni yozing — superadmin ko\'rib chiqadi va zarur bo\'lsa aloqaga chiqadi.';

  @override
  String get feedbackQuestionMessageHint =>
      'Savolingiz yoki murojaatingizni shu yerga yozing...';

  @override
  String get feedbackQuestionBadge => 'Savol';

  @override
  String get feedbackListTitle => 'Foydalanuvchi fikrlari';

  @override
  String get noFeedbackFound => 'Hozircha fikrlar yo\'q';

  @override
  String get unknownUserLabel => 'Noma\'lum foydalanuvchi';

  @override
  String get requestAuthorLabel => 'Yuborgan';

  @override
  String get quickNewRequestTitle => 'Yangi murojaat yuborish';

  @override
  String get quickNewRequestSubtitle =>
      'Muammo bormi? Bir necha soniyada yuboring';

  @override
  String get mahalCardTitle => 'Mahal bilan suhbat';

  @override
  String get mahalCardSubtitle =>
      'Savollaringizga javob oling, murojaat yozib bering yoki mahalla haqida so\'rang';

  @override
  String get openLinkAction => 'Havolani ochish';

  @override
  String get linkOpenFailedMessage => 'Havolani ochib bo\'lmadi';

  @override
  String get bannerManagementTitle => 'Bannerlar';

  @override
  String get addBannerTitle => 'Yangi banner qo\'shish';

  @override
  String get bannerTitleLabel => 'Sarlavha';

  @override
  String get bannerDescriptionLabel => 'Tavsif (ixtiyoriy)';

  @override
  String get bannerLinkLabel => 'Havola (ixtiyoriy, https://...)';

  @override
  String get bannerAttributionLabel => 'Muallif/manba (ixtiyoriy)';

  @override
  String get bannerImageRequiredError => 'Iltimos, rasm tanlang';

  @override
  String get bannerTitleRequiredError => 'Iltimos, sarlavha kiriting';

  @override
  String get noBannersFound => 'Hozircha bannerlar yo\'q';

  @override
  String get mahallaOnMapTitle => 'Mahallangiz xaritada';

  @override
  String get developerTitle => 'Rivojlantiruvchi';

  @override
  String get developerSubtitle => 'Mahallam jamoasi';

  @override
  String get termsTitle => 'Foydalanish shartlari';

  @override
  String get privacyPolicyTitle => 'Maxfiylik siyosati';

  @override
  String get comingSoonMessage => 'Bu funksiya tez orada qo\'shiladi';

  @override
  String get profileSaved => 'Ma\'lumotlar saqlandi';

  @override
  String get saveButton => 'Saqlash';

  @override
  String get faqTitle => 'Ko\'p beriladigan savollar';

  @override
  String get contactUsTitle => 'Biz bilan bog\'laning';

  @override
  String get callUs => 'Telefon orqali';

  @override
  String get telegramUs => 'Telegram orqali';

  @override
  String get faqQ1 => 'Mahallaga qanday qo\'shilaman?';

  @override
  String get faqA1 =>
      'Ro\'yxatdan o\'tgandan so\'ng, mahalla raisi yoki mas\'ul xodim tomonidan berilgan QR kodni skanerlash orqali mahallangizga bog\'lanasiz.';

  @override
  String get faqQ2 => 'Murojaat qanday yuboraman?';

  @override
  String get faqA2 =>
      '\"Murojaat\" bo\'limiga o\'ting va yangi murojaat yarating. Murojaatingiz holati \"Yangi\", \"Jarayonda\" yoki \"Yakunlandi\" sifatida ko\'rsatiladi.';

  @override
  String get faqQ3 => 'E\'lonlarni qanday ko\'raman?';

  @override
  String get faqA3 =>
      'Bosh ekrandagi \"E\'lonlar\" bo\'limida mahallangizga oid barcha rasmiy e\'lonlar kategoriyalar bo\'yicha ko\'rsatiladi.';

  @override
  String get faqQ4 => 'Parolimni unutdim, nima qilaman?';

  @override
  String get faqA4 =>
      'Kirish ekranidagi «Parolni unutdingizmi?» tugmasini bosing. Elektron pochtangizga tiklash havolasi yuboriladi. Xat kelmasa, «Spam» papkasini ham tekshiring.';

  @override
  String get faqQ5 => 'Ma\'lumotlarim xavfsizmi?';

  @override
  String get faqA5 =>
      'Ha, barcha ma\'lumotlar faqat mahallangiz doirasida ko\'rinadi va himoyalangan serverda saqlanadi.';

  @override
  String get callFailedMessage => 'Qo\'ng\'iroq qilib bo\'lmadi';

  @override
  String get telegramFailedMessage => 'Telegram ochib bo\'lmadi';

  @override
  String get announcementsTitle => 'E\'lonlar';

  @override
  String get eventsTitle => 'Tadbirlar';

  @override
  String get feedTitle => 'Lenta';

  @override
  String get postsFilterLabel => 'Postlar';

  @override
  String get noPostsYet => 'Hozircha postlar yo\'q';

  @override
  String get noPostsHint =>
      'Qo\'shnilar birinchi post qilganda, u shu yerda paydo bo\'ladi.';

  @override
  String get writePostHint => 'Nima gaplar?';

  @override
  String get postCreatedMessage => 'Post joylandi';

  @override
  String get writePostOrImageError => 'Matn yozing yoki rasm qo\'shing';

  @override
  String get postUpdatedMessage => 'Post yangilandi';

  @override
  String get editPostTitle => 'Postni tahrirlash';

  @override
  String get postingTooFastError =>
      'Juda tez-tez post joylayapsiz. Biroz kuting va qayta urinib ko\'ring.';

  @override
  String get inappropriateContentError =>
      'Matnda nomaqbul so\'zlar bor. Iltimos, matnni tahrirlang.';

  @override
  String get reactionsSheetTitle => 'Reaksiyalar';

  @override
  String get addStoryLabel => 'Hikoya qo\'shish';

  @override
  String get yourStoryLabel => 'Sizning hikoyangiz';

  @override
  String get newButton => 'Yangi';

  @override
  String get noAnnouncementsYet => 'Hozircha e\'lonlar yo\'q';

  @override
  String get noEventsYet => 'Hozircha tadbirlar yo\'q';

  @override
  String get noEventsHint =>
      'Mahalla raisi yoki xodimlari tadbir e\'lon qilganda, u shu yerda paydo bo\'ladi.';

  @override
  String get announcementsLoadError =>
      'E\'lonlarni yuklashda xatolik yuz berdi';

  @override
  String participantsCount(int count) {
    return '$count qatnashuvchi';
  }

  @override
  String todayAt(String time) {
    return 'Bugun, $time';
  }

  @override
  String get categoryKommunal => 'Kommunal';

  @override
  String get categoryXavfsizlik => 'Xavfsizlik';

  @override
  String get categoryUmumiy => 'Umumiy';

  @override
  String get newAnnouncementTitle => 'Yangi e\'lon';

  @override
  String get editAnnouncementTitle => 'E\'lonni tahrirlash';

  @override
  String get pollsTitle => 'So\'rovnomalar';

  @override
  String get newPollTitle => 'Yangi so\'rovnoma';

  @override
  String get pollQuestionHint => 'Savolingizni yozing...';

  @override
  String pollOptionHint(int number) {
    return '$number-variant';
  }

  @override
  String get addOptionButton => 'Variant qo\'shish';

  @override
  String get fillPollFields => 'Savol va kamida 2 ta variant kiriting';

  @override
  String get pollPostedMessage => 'So\'rovnoma joylandi';

  @override
  String get noPollsYet => 'Hozircha so\'rovnomalar yo\'q';

  @override
  String pollVotesCount(int count) {
    return '$count ovoz';
  }

  @override
  String get conversationsTitle => 'Xabarlar';

  @override
  String get conversationsMenuItem => 'Xabarlar';

  @override
  String get noConversationsYet => 'Hozircha suhbatlar yo\'q';

  @override
  String get noMessagesYet =>
      'Hozircha xabarlar yo\'q. Birinchi bo\'lib yozing!';

  @override
  String get messageHint => 'Xabar yozing...';

  @override
  String get sendMessageAction => 'Xabar yozish';

  @override
  String get typingIndicator => 'yozmoqda...';

  @override
  String get attachImageAction => 'Rasm biriktirish';

  @override
  String get imageUploadFailed => 'Rasm yuborilmadi. Qayta urinib ko\'ring';

  @override
  String get yesterdayLabel => 'Kecha';

  @override
  String get switchMahallaTitle => 'Mahalla tanlash';

  @override
  String get switchMahallaMenuItem => 'Mahalla almashtirish (Super Admin)';

  @override
  String get switchMahallaMenuItemActive => 'Boshqa mahallani boshqaryapsiz';

  @override
  String get exitMahallaModeAction => 'O\'z mahallamga qaytish';

  @override
  String get noMahallasFound => 'Mahallalar topilmadi';

  @override
  String get broadcastToAllMahallasLabel =>
      'Barcha mahallalarga yuborish (Super Admin)';

  @override
  String get servicesTitle => 'Mahalliy xizmatlar';

  @override
  String get newServiceTitle => 'Xizmat qo\'shish';

  @override
  String get editServiceTitle => 'Xizmatni tahrirlash';

  @override
  String get serviceCategoryLabel => 'Toifa';

  @override
  String get serviceNameLabel => 'Ism yoki tashkilot nomi';

  @override
  String get serviceNameHint => 'Masalan: Aziz aka (santexnik)';

  @override
  String get servicePhoneLabel => 'Telefon raqami';

  @override
  String get serviceDescriptionLabel => 'Tavsif';

  @override
  String get serviceDescriptionHint => 'Ish vaqti, narxi va h.k...';

  @override
  String get fillServiceFields => 'Ism va telefon raqamini kiriting';

  @override
  String get servicePostedMessage => 'Xizmat qo\'shildi';

  @override
  String get serviceUpdatedMessage => 'Xizmat yangilandi';

  @override
  String get noServicesYet => 'Hozircha xizmatlar yo\'q';

  @override
  String get serviceCategorySantexnik => 'Santexnik';

  @override
  String get serviceCategoryElektrik => 'Elektrik';

  @override
  String get serviceCategoryDuradgor => 'Duradgor';

  @override
  String get serviceCategoryTozalash => 'Tozalash';

  @override
  String get serviceCategoryQurilish => 'Qurilish';

  @override
  String get serviceCategoryBoshqa => 'Boshqa';

  @override
  String get editPollTitle => 'So\'rovnomani tahrirlash';

  @override
  String get pollUpdatedMessage => 'So\'rovnoma yangilandi';

  @override
  String get changeVoteConfirmTitle => 'Ovozni almashtirish';

  @override
  String get changeVoteConfirmMessage =>
      'Siz allaqachon boshqa variantga ovoz bergansiz. Ovozingizni almashtirmoqchimisiz?';

  @override
  String get changeVoteConfirmButton => 'Ha, almashtirish';

  @override
  String get pollAllowMultipleLabel =>
      'Bir nechta variant tanlashga ruxsat berish';

  @override
  String get pollAnonymousLabel => 'Anonim so\'rovnoma';

  @override
  String get pollClosesAtLabel => 'Yopilish sanasi (ixtiyoriy)';

  @override
  String get pollClosesAtClearButton => 'Tozalash';

  @override
  String get pollClosedBadge => 'Yopilgan';

  @override
  String get pollVoteClosedError =>
      'Bu so\'rovnoma yopilgan, ovoz berish mumkin emas';

  @override
  String get pollSubmitVoteButton => 'Ovoz berish';

  @override
  String get categoryServices => 'Xizmatlar';

  @override
  String get categoryPolls => 'So\'rovnomalar';

  @override
  String get categoryLabel => 'Kategoriya';

  @override
  String get titleLabel => 'Sarlavha';

  @override
  String get titleHint => 'Masalan: Ertaga suv o\'chirilishi haqida';

  @override
  String get bodyLabel => 'Matn';

  @override
  String get bodyHint => 'E\'lon matnini batafsil yozing...';

  @override
  String get photoLabel => 'Rasm';

  @override
  String get optionalLabel => '(ixtiyoriy)';

  @override
  String get postButton => 'Joylash';

  @override
  String get fillTitleAndBody => 'Sarlavha va matnni to\'ldiring';

  @override
  String get announcementPosted => 'E\'lon muvaffaqiyatli joylandi';

  @override
  String get announcementUpdated => 'E\'lon yangilandi';

  @override
  String get requestsTitle => 'Murojaatlar';

  @override
  String get mustVerifyMahallaFirst =>
      'Avval mahallangizni tasdiqlashingiz kerak';

  @override
  String get managementPanelBanner => 'Boshqaruv paneli — barcha murojaatlar';

  @override
  String get requestsLoadError => 'Murojaatlarni yuklashda xatolik yuz berdi';

  @override
  String joinedCount(int count) {
    return '$count kishi qo\'shildi';
  }

  @override
  String noRequestsWithStatus(String status) {
    return '$status murojaatlar yo\'q';
  }

  @override
  String get filterAll => 'Hammasi';

  @override
  String get noRequestsAtAll => 'Hozircha murojaatlar yo\'q';

  @override
  String get statusYangi => 'Yangi';

  @override
  String get statusJarayonda => 'Jarayonda';

  @override
  String get statusYakunlandi => 'Yakunlandi';

  @override
  String get typeMaxfiy => 'Maxfiy';

  @override
  String get typeOmmaviy => 'Ommaviy';

  @override
  String get priorityPast => 'Past';

  @override
  String get priorityOrtacha => 'O\'rtacha';

  @override
  String get priorityYuqori => 'Yuqori';

  @override
  String get managementPanelTitle => 'Boshqaruv paneli';

  @override
  String get changeStatusTitle => 'Holatni o\'zgartirish';

  @override
  String statusChangedMessage(String status) {
    return 'Holat \"$status\" ga o\'zgartirildi';
  }

  @override
  String get statusChangeError => 'Holatni o\'zgartirishda xatolik yuz berdi';

  @override
  String get allFilter => 'Barchasi';

  @override
  String get noRequestsFound => 'Murojaatlar topilmadi';

  @override
  String get tapToChangeStatus => 'Holatni o\'zgartirish uchun bosing';

  @override
  String get stepType => 'Turi';

  @override
  String get stepDetails => 'Tafsilotlar';

  @override
  String get stepLocation => 'Joylashuv';

  @override
  String get stepReview => 'Ko\'rib chiqish';

  @override
  String get stepDone => 'Tayyor';

  @override
  String get newRequestTitle => 'Yangi murojaat';

  @override
  String get fillTitleAndDescription => 'Sarlavha va tavsifni to\'ldiring';

  @override
  String get sendButton => 'Yuborish';

  @override
  String get chooseRequestType => 'Murojaat turini tanlang';

  @override
  String get requestTypeExplain =>
      'Bu murojaatingizni kim ko\'ra olishini belgilaydi';

  @override
  String get typeMaxfiyDescription => 'Faqat siz va mahalla raisi ko\'radi';

  @override
  String get typeOmmaviyDescription =>
      'Mahalladagi hamma ko\'radi va qo\'shilishi mumkin';

  @override
  String get titleFieldLabel => 'Sarlavha';

  @override
  String get titleFieldHint => 'Masalan: Ko\'cha yoritilishi ishlamayapti';

  @override
  String get descriptionLabel => 'Tavsif';

  @override
  String get descriptionHint => 'Muammoni batafsil tasvirlab bering...';

  @override
  String get attachPhotoLabel => 'Rasm biriktirish';

  @override
  String get priorityLevelLabel => 'Muhimlik darajasi';

  @override
  String get reviewDataTitle => 'Ma\'lumotlarni tekshiring';

  @override
  String get reviewType => 'Turi';

  @override
  String get reviewPriority => 'Muhimlik';

  @override
  String get reviewLocation => 'Joylashuv';

  @override
  String get reviewLocationSet => 'Belgilangan';

  @override
  String get reviewLocationNotSet => 'Belgilanmagan';

  @override
  String reviewPhotos(int count) {
    return 'Rasmlar ($count)';
  }

  @override
  String get requestSentTitle => 'Murojaat yuborildi!';

  @override
  String get requestSentMessage =>
      'Murojaatingiz qabul qilindi va ko\'rib chiqilmoqda';

  @override
  String get backToListButton => 'Ro\'yxatga qaytish';

  @override
  String get qrScanInstruction =>
      'Mahalla eshigidagi QR kodni ramka ichiga joylashtiring';

  @override
  String get checkingStatus => 'Tekshirilmoqda...';

  @override
  String get scanningStatus => 'Skanerlanmoqda...';

  @override
  String get enterCodeManually => 'Kodni qo\'lda kiritish';

  @override
  String get enterMahallaCodeTitle => 'Mahalla kodini kiriting';

  @override
  String get mahallaCodeHint => 'Masalan: Y234-5678';

  @override
  String get confirmButton => 'Tasdiqlash';

  @override
  String get qrGenericError => 'Xatolik yuz berdi, qayta urinib ko\'ring';

  @override
  String get confirmError =>
      'Tasdiqlashda xatolik yuz berdi, qayta urinib ko\'ring';

  @override
  String get mahallaFoundLabel => 'Mahalla topildi';

  @override
  String get rescanButton => 'Qayta skanerlash';

  @override
  String get changePhotoLabel => 'Rasmni o\'zgartirish';

  @override
  String get birthDateLabel => 'Tug\'ilgan sana';

  @override
  String get addressLabel => 'Manzil';

  @override
  String get streetLabel => 'Ko\'cha';

  @override
  String get streetHint => 'Masalan: Bog\'bon ko\'chasi';

  @override
  String get houseNumberLabel => 'Uy raqami';

  @override
  String get houseNumberHint => 'Masalan: 15';

  @override
  String get genderLabel => 'Jinsi';

  @override
  String get genderMale => 'Erkak';

  @override
  String get genderFemale => 'Ayol';

  @override
  String get notSpecified => 'Ko\'rsatilmagan';

  @override
  String get selectDate => 'Sanani tanlang';

  @override
  String get photoUploadError => 'Rasm yuklashda xatolik yuz berdi';

  @override
  String get otpTitle => 'Tasdiqlash kodi';

  @override
  String otpSubtitle(String phone) {
    return '$phone raqamiga yuborilgan 6 xonali kodni kiriting';
  }

  @override
  String get otpInvalidCode => 'Kod noto\'g\'ri, qaytadan kiriting';

  @override
  String get otpResendCode => 'Kodni qayta yuborish';

  @override
  String otpResendCooldown(int seconds) {
    return 'Qayta yuborish (${seconds}s)';
  }

  @override
  String get forgotPasswordTitle => 'Parolni tiklash';

  @override
  String get forgotPasswordSubtitle =>
      'Ro\'yxatdan o\'tgan telefon raqamingizni kiriting, unga tasdiqlash kodi yuboramiz';

  @override
  String get sendCodeButton => 'Kod yuborish';

  @override
  String get newPasswordLabel => 'Yangi parol';

  @override
  String get newPasswordTitle => 'Yangi parol o\'rnating';

  @override
  String get newPasswordSubtitle =>
      'Hisobingiz uchun yangi parol o\'ylab toping';

  @override
  String get savePasswordButton => 'Parolni saqlash';

  @override
  String get passwordResetSuccess => 'Parolingiz muvaffaqiyatli yangilandi';

  @override
  String get newEventTitle => 'Yangi tadbir';

  @override
  String get editEventTitle => 'Tadbirni tahrirlash';

  @override
  String get eventTitleHint => 'Masalan: Mahalla yig\'ilishi';

  @override
  String get eventDescriptionHint =>
      'Tadbir haqida qo\'shimcha ma\'lumot (ixtiyoriy)...';

  @override
  String get pinAnnouncementAction => 'Yuqoriga mahkamlash';

  @override
  String get unpinAnnouncementAction => 'Mahkamlashni yechish';

  @override
  String get cannotMessageBlockedUser =>
      'Bu foydalanuvchiga xabar yubora olmaysiz.';

  @override
  String get rsvpToggleLabel => 'Qatnashish belgisi';

  @override
  String get rsvpToggleHint =>
      'Yoqilsa, foydalanuvchilar \"Boraman\" deb belgilay oladi.';

  @override
  String get rsvpJoinAction => 'Boraman';

  @override
  String get rsvpJoinedLabel => 'Boraman';

  @override
  String get dateLabel => 'Sana';

  @override
  String get selectTime => 'Vaqtni tanlang';

  @override
  String get locationLabel => 'Manzil';

  @override
  String get locationHint => 'Tadbir o\'tkaziladigan joy';

  @override
  String get fillEventFields => 'Sarlavha va sanani kiriting';

  @override
  String get eventPosted => 'Tadbir joylandi';

  @override
  String get eventUpdated => 'Tadbir yangilandi';

  @override
  String get neighborsTitle => 'Qo\'shnilar';

  @override
  String get mahalladoshlar => 'Mahalladoshlar';

  @override
  String get yozishmalarTitle => 'Yozishmalar';

  @override
  String get noNeighborsYet => 'Hozircha qo\'shnilar yo\'q';

  @override
  String get onlineNow => 'Onlayn';

  @override
  String get lastSeenUnknown => 'Oxirgi faollik noma\'lum';

  @override
  String get lastSeenJustNow => 'Hozirgina faol edi';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return '$minutes daqiqa oldin';
  }

  @override
  String lastSeenHoursAgo(int hours) {
    return '$hours soat oldin';
  }

  @override
  String lastSeenDaysAgo(int days) {
    return '$days kun oldin';
  }

  @override
  String get sectionPrivacy => 'Maxfiylik';

  @override
  String get showPhoneToNeighborsTitle => 'Telefonni qo\'shnilarga ko\'rsatish';

  @override
  String get showPhoneToNeighborsSubtitle =>
      'Yoqilsa, Qo\'shnilar ro\'yxatida raqamingiz ko\'rinadi';

  @override
  String get privacySecurityTitle => 'Maxfiylik va xavfsizlik';

  @override
  String get privacySecuritySubtitle =>
      'Ko\'rinish, bloklangan foydalanuvchilar, parol';

  @override
  String get sectionVisibility => 'Ko\'rinish';

  @override
  String get showLastSeenTitle => 'Oxirgi faollikni ko\'rsatish';

  @override
  String get showLastSeenSubtitle =>
      'Yoqilsa, qo\'shnilar online holatingizni ko\'radi';

  @override
  String get sectionBlockedUsers => 'Bloklangan foydalanuvchilar';

  @override
  String get blockedUsersTitle => 'Bloklangan foydalanuvchilar';

  @override
  String get noBlockedUsers => 'Bloklangan foydalanuvchilar yo\'q';

  @override
  String blockedUsersCount(int count) {
    return '$count ta bloklangan';
  }

  @override
  String get blockUserAction => 'Bloklash';

  @override
  String get blockUserConfirmTitle => 'Foydalanuvchini bloklash';

  @override
  String blockUserConfirmMessage(String name) {
    return '$name sizga xabar yoza olmaydi va ro\'yxatingizda ko\'rinmaydi. Rozimisiz?';
  }

  @override
  String userBlockedMessage(String name) {
    return '$name bloklandi';
  }

  @override
  String get unblockAction => 'Blokdan chiqarish';

  @override
  String userUnblockedMessage(String name) {
    return '$name blokdan chiqarildi';
  }

  @override
  String get phoneHiddenByUser => 'Bu foydalanuvchi telefonini yashirgan';

  @override
  String get markAllAsReadAction => 'Barchasini o\'qilgan deb belgilash';

  @override
  String get noNotificationsYet => 'Hozircha bildirishnomalar yo\'q';

  @override
  String get searchPromptText => 'E\'lon, tadbir yoki murojaat qidiring';

  @override
  String get searchNoResults => 'Hech narsa topilmadi';

  @override
  String get requestDetailTitle => 'Murojaat tafsilotlari';

  @override
  String get requestNotFound => 'Murojaat topilmadi';

  @override
  String get announcementDetailTitle => 'E\'lon tafsilotlari';

  @override
  String get announcementNotFound => 'E\'lon topilmadi';

  @override
  String get eventDetailTitle => 'Tadbir tafsilotlari';

  @override
  String get eventNotFound => 'Tadbir topilmadi';

  @override
  String get shareAction => 'Ulashish';

  @override
  String get joinRequestAction => 'Qo\'shilish';

  @override
  String get leaveRequestAction => 'Chiqish';

  @override
  String get mahallaStaffTitle => 'Mahalla xodimlari';

  @override
  String get mahallaMapTitle => 'Mahalla xaritasi';

  @override
  String get locationStepTitle => 'Joylashuvni belgilang';

  @override
  String get locationStepSubtitle =>
      'Xaritani bosib nuqta qo\'ying yoki joriy joylashuvingizni ishlating (ixtiyoriy)';

  @override
  String get locationPermissionError => 'Joylashuvga ruxsat berilmadi';

  @override
  String get clearLocationAction => 'Tozalash';

  @override
  String get boundaryEditorTitle => 'Chegarani belgilash';

  @override
  String get boundaryEditorHint =>
      'Xaritani bosib mahalla chegarasi bo\'ylab nuqtalar qo\'ying (kamida 3 ta)';

  @override
  String get boundaryMinPointsError => 'Kamida 3 ta nuqta belgilang';

  @override
  String get boundarySavedMessage => 'Chegara saqlandi';

  @override
  String get saveBoundaryAction => 'Chegarani saqlash';

  @override
  String get editBoundaryAction => 'Chegarani tahrirlash';

  @override
  String get mapLayerSatellite => 'Sputnik ko\'rinishi';

  @override
  String get mapLayerStreets => 'Ko\'cha xaritasi';

  @override
  String get deleteItemConfirmTitle => 'O\'chirish';

  @override
  String deleteItemConfirmMessage(String title) {
    return '\"$title\" butunlay o\'chiriladi. Bu amalni ortga qaytarib bo\'lmaydi.';
  }

  @override
  String get itemDeletedMessage => 'O\'chirildi';

  @override
  String get searchNeighborHint => 'Ism bo\'yicha qidirish...';

  @override
  String get currentPasswordLabel => 'Joriy parol';

  @override
  String get confirmPasswordLabel => 'Parolni tasdiqlang';

  @override
  String get passwordMismatchError => 'Parollar mos kelmadi';

  @override
  String get newPhoneLabel => 'Yangi telefon raqam';

  @override
  String get phoneChangedMessage =>
      'Telefon raqam muvaffaqiyatli o\'zgartirildi';

  @override
  String get termsBody =>
      'Ushbu ilovadan foydalanish orqali siz quyidagi shartlarga rozilik bildirasiz:\n\n1. Ilova mahalla aholisi va xodimlari o\'rtasida muloqotni osonlashtirish uchun mo\'ljallangan.\n2. Foydalanuvchi o\'z profilida to\'g\'ri va haqiqiy ma\'lumot kiritishi shart.\n3. Boshqa foydalanuvchilarga nisbatan haqoratli, noqonuniy yoki yolg\'on ma\'lumot tarqatish taqiqlanadi.\n4. Mahalla ma\'muriyati (xodim/rais) tomonidan joylashtirilgan e\'lon va tadbirlar rasmiy xarakterga ega bo\'lishi mumkin.\n5. Ilova ma\'muriyati qoidabuzarlik aniqlangan hisoblarni bloklash yoki o\'chirish huquqini o\'zida saqlab qoladi.';

  @override
  String get privacyPolicyBody =>
      'Sizning ma\'lumotlaringiz qanday ishlatiladi:\n\n1. Ism, familiya, telefon raqam va mahalla ma\'lumotlari faqat mahalla ichidagi muloqot uchun ishlatiladi.\n2. Telefon raqamingiz sozlamalarda ruxsat bermaguningizcha boshqa aholiga ko\'rinmaydi.\n3. Oxirgi faollik vaqti sozlamalarda o\'chirilishi mumkin.\n4. Ma\'lumotlaringiz uchinchi tomonlarga sotilmaydi yoki ularga uzatilmaydi.\n5. Hisobingizni o\'chirishni so\'rasangiz, ma\'lumotlaringiz Firestore bazasidan olib tashlanadi.';

  @override
  String get deleteAccountRequested =>
      'So\'rovingiz yuborildi. Administrator tez orada hisobingizni o\'chiradi.';

  @override
  String get deleteAccountAlreadyPending =>
      'Sizning o\'chirish so\'rovingiz allaqachon ko\'rib chiqilmoqda.';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get cameraIntroTitle => 'Kameraga ruxsat kerak';

  @override
  String get cameraIntroBody =>
      'Mahallangizga qo\'shilish uchun rais yoki xodim bergan QR kodni skanerlash kerak. Kamera faqat shu maqsadda ishlatiladi — hech qanday rasm saqlanmaydi va yuborilmaydi.';

  @override
  String get cameraIntroButton => 'Kamerani ochish';

  @override
  String get cameraErrorPermission =>
      'Kameraga ruxsat berilmagan. Ruxsatni telefon sozlamalarida (Ilovalar → Mening Mahallam → Ruxsatlar → Kamera) yoqishingiz mumkin. Yoki mahalla kodini qo\'lda kiriting.';

  @override
  String get cameraErrorUnsupported =>
      'Bu qurilmada QR skanerlash qo\'llab-quvvatlanmaydi. Mahalla kodini qo\'lda kiriting.';

  @override
  String get cameraErrorGeneric =>
      'Kamera ochilmadi. Boshqa ilova kamerani ishlatayotgan bo\'lishi mumkin — uni yoping va qayta urinib ko\'ring.';

  @override
  String get noAnnouncementsHint =>
      'Mahalla raisi yoki xodimlari e\'lon joylaganda, u shu yerda birinchi bo\'lib paydo bo\'ladi.';

  @override
  String get noRequestsHint =>
      'Ko\'cha yoritgichi, tozalik, suv yoki boshqa masala bo\'yicha murojaat yuboring — mahalla xodimlari javob beradi.';

  @override
  String get noNeighborsHint =>
      'Mahalladoshlaringiz ilovaga qo\'shilgan sari ular shu yerda ko\'rinadi. Qo\'shnilaringizni taklif qiling!';

  @override
  String get noPollsHint =>
      'Mahalla so\'rovnomalari shu yerda chiqadi — ovoz berib, qaror qabul qilishda ishtirok etasiz.';

  @override
  String get noServicesHint =>
      'Mahalladagi ustalar, do\'konlar va xizmatlar shu yerda to\'planadi.';

  @override
  String get noConversationsHint =>
      'Qo\'shnilar bo\'limidan biror kishini tanlab, unga to\'g\'ridan-to\'g\'ri yozishingiz mumkin.';

  @override
  String get noNotificationsHint =>
      'Yangi e\'lon, tadbir yoki murojaatingizga javob kelganda shu yerda xabar beramiz.';

  @override
  String get currencySom => 'so\'m';

  @override
  String get premiumConfigTitle => 'To\'lov rekvizitlari';

  @override
  String get premiumConfigHint =>
      'Bu yerda o\'zgartirilgan qiymatlar barcha foydalanuvchilarga darhol ko\'rinadi — ilovani yangilash shart emas.';

  @override
  String get premiumConfigSaved => 'Rekvizitlar saqlandi';

  @override
  String get premiumCardNumberLabel => 'Karta raqami';

  @override
  String get premiumCardNumberInvalid =>
      'Karta raqami 16 ta raqamdan iborat bo\'lishi kerak';

  @override
  String get premiumCardHolderLabel => 'Karta egasining ismi';

  @override
  String get premiumCardHolderInvalid => 'Karta egasining ismini kiriting';

  @override
  String get premiumPriceLabel => 'Oylik narx';

  @override
  String get premiumPriceInvalid => 'To\'g\'ri narx kiriting';

  @override
  String get premiumTelegramLabel => 'Telegram foydalanuvchi nomi';

  @override
  String get premiumChoosePlan => 'Muddatni tanlang';

  @override
  String premiumPlanMonths(int count) {
    return '$count oy';
  }

  @override
  String premiumPriceValue(String amount) {
    return '$amount so\'m';
  }

  @override
  String get premiumBenefitAdDiscount =>
      'Xizmat reklamasini joylashtirish 50% arzon';

  @override
  String get premiumBenefitSupport =>
      'Ustuvor qo\'llab-quvvatlash — murojaatingiz birinchi ko\'riladi';

  @override
  String get premiumBenefitAvatar => 'Profil suratida oltin premium halqa';

  @override
  String get premiumBenefitEarlyAccess =>
      'Yangi imkoniyatlar birinchi bo\'lib sizga ochiladi';

  @override
  String premiumPerMonthAmount(String amount) {
    return 'oyiga $amount so\'m';
  }

  @override
  String get advertiseTitle => 'Xizmatingizni shu yerda reklama qiling';

  @override
  String advertisePrice(String amount) {
    return 'Haftasiga atigi $amount so\'m';
  }

  @override
  String advertisePremiumDiscount(String amount) {
    return 'Premium chegirmangiz — oddiy narx $amount so\'m';
  }

  @override
  String get advertiseHowTo =>
      'Reklama joylashtirish uchun mahalla raisi yoki ilova administratori bilan bog\'laning.';

  @override
  String get photoTooLarge => 'Fayl juda katta. 5 MB dan kichik rasm tanlang';

  @override
  String get avatarSourceImage => 'Rasm';

  @override
  String get avatarSourceVideo => 'Video';

  @override
  String get avatarSourceVideoHint =>
      'Birinchi 4 soniyasi jonli GIF avatarga aylantiriladi';

  @override
  String get videoToGifError =>
      'Videoni GIF\'ga aylantirib bo\'lmadi. Boshqa video bilan urinib ko\'ring';

  @override
  String get premiumBenefitAnimatedAvatar => 'Jonli (GIF) profil surati';

  @override
  String get premiumGrantTitle => 'Premiumni qo\'lda berish';

  @override
  String get premiumGrantSelfAction => 'O\'zimga berish';

  @override
  String get premiumGrantPhoneLabel => 'Telefon raqami';

  @override
  String get premiumGrantAction => 'Shu raqamga berish';

  @override
  String get premiumRevokeAction => 'Shu raqamdan bekor qilish';

  @override
  String get premiumRevokeConfirmTitle => 'Premiumni bekor qilish';

  @override
  String premiumRevokeConfirmMessage(String name) {
    return '$name uchun premium obunani muddatidan oldin bekor qilmoqchimisiz?';
  }

  @override
  String premiumRevokedFrom(String name) {
    return '$name uchun premium bekor qilindi';
  }

  @override
  String premiumGrantedSelf(int months) {
    return 'Sizga $months oylik premium berildi';
  }

  @override
  String premiumGrantedTo(String name, int months) {
    return '$name — $months oylik premium berildi';
  }

  @override
  String get premiumGrantUserNotFound =>
      'Bu raqam bilan foydalanuvchi topilmadi';

  @override
  String premiumUntilShort(String date) {
    return '$date gacha';
  }

  @override
  String get personalInfoSection => 'Shaxsiy ma\'lumotlar';

  @override
  String get addressSection => 'Manzil';

  @override
  String get mahallaCenterTitle => 'Mahalla markazi';

  @override
  String get mahallaCenterHint =>
      'Xaritaga bosib markazni belgilang yoki tepadagi nishon tugmasi orqali koordinatani kiriting.';

  @override
  String get mahallaCenterCoordsHint =>
      'Google Maps\'dan nusxalagan koordinatani qo\'ying (kenglik, uzunlik).';

  @override
  String get mahallaCenterSaved => 'Mahalla markazi saqlandi';

  @override
  String get boundaryModeLabel => 'Chegara';

  @override
  String get centerModeLabel => 'Markaz';

  @override
  String get saveCenterAction => 'Markazni saqlash';

  @override
  String get appearanceSystemHint => 'Telefon sozlamasiga ergashadi';

  @override
  String get textSizePreviewTitle => 'Mahalla yig\'ilishi';

  @override
  String get textSizePreviewBody =>
      'Asosiy matn shunday ko\'rinadi. Sizga qulay o\'lchamni tanlang.';

  @override
  String get okButton => 'OK';

  @override
  String get reportAction => 'Shikoyat qilish';

  @override
  String get reportSheetTitle => 'Shikoyat qilish';

  @override
  String get reportReasonLabel => 'Sabab';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHaqoratOmuhandaslik => 'Haqorat yoki tahdid';

  @override
  String get reportReasonAldash => 'Firibgarlik / aldash';

  @override
  String get reportReasonNomunosib => 'Nomunosib kontent';

  @override
  String get reportReasonBoshqa => 'Boshqa';

  @override
  String get reportDetailsLabel => 'Qo\'shimcha izoh';

  @override
  String get reportDetailsHint => 'Batafsil yozing (ixtiyoriy)';

  @override
  String get reportSubmitAction => 'Yuborish';

  @override
  String get reportSubmittedMessage =>
      'Shikoyatingiz qabul qilindi, ko\'rib chiqamiz';

  @override
  String get reportErrorMessage => 'Shikoyat yuborishda xatolik yuz berdi';

  @override
  String get reportChooseReasonError => 'Iltimos, sababni tanlang';

  @override
  String serviceRatingCount(int count) {
    return '$count baho';
  }

  @override
  String get serviceNoRatingsYet => 'Hali baho yo\'q';

  @override
  String get yourRatingLabel => 'Sizning bahoyingiz';

  @override
  String get assignStaffTitle => 'Xodimga biriktirish';

  @override
  String get noStaffFoundLabel => 'Mahallada xodim topilmadi';

  @override
  String get cancelAssignmentAction => 'Biriktirishni bekor qilish';

  @override
  String get requestAssignedMessage => 'Murojaat biriktirildi';

  @override
  String get dueDateSetMessage => 'Muddat belgilandi';

  @override
  String get assignAction => 'Biriktirish';

  @override
  String get setDueDateAction => 'Muddat belgilash';

  @override
  String assignedToLabel(String fullName) {
    return 'Biriktirilgan: $fullName';
  }

  @override
  String dueDateLabel(String date) {
    return 'Muddat: $date';
  }

  @override
  String get dueDateOverdueSuffix => ' — muddati o\'tdi';

  @override
  String get commentsTitle => 'Izohlar';

  @override
  String get noCommentsYet => 'Hozircha izohlar yo\'q';

  @override
  String get commentHint => 'Izoh yozing...';

  @override
  String get similarRequestsTitle => 'O\'xshash murojaatlar';

  @override
  String get createGroupAction => 'Guruh yaratish';

  @override
  String get groupNameLabel => 'Guruh nomi';

  @override
  String get groupNameHint => 'Masalan: Ko\'cha faollari';

  @override
  String get selectMembersLabel => 'A\'zolarni tanlang';

  @override
  String selectMembersLabelWithCount(int count) {
    return 'A\'zolarni tanlang ($count)';
  }

  @override
  String get enterGroupNameError => 'Guruh nomini kiriting';

  @override
  String get selectAtLeastOneMemberError => 'Kamida bitta a\'zo tanlang';

  @override
  String get groupCreateError => 'Guruh yaratishda xatolik yuz berdi';

  @override
  String get groupsSectionTitle => 'Guruhlar';

  @override
  String get locationFieldLabel => 'Joylashuv';

  @override
  String get locationSetLabel => 'Joylashuv belgilandi';

  @override
  String get setLocationLabel => 'Joylashuvni belgilash';

  @override
  String get locationDetectError =>
      'Joylashuvni aniqlab bo\'lmadi. Ruxsat yoki GPS holatini tekshiring.';

  @override
  String get tapMapHint => 'Xaritani bosib nuqta belgilang';

  @override
  String get assistantScreenTitle => 'Mahal';

  @override
  String get assistantSubtitleLabel => 'AI yordamchi';

  @override
  String get assistantInputHint => 'Savolingizni yozing...';

  @override
  String get assistantGreetingTitle => 'Salom! Men Mahalman';

  @override
  String get assistantGreetingSubtitle =>
      'Mahalla haqida savollaringizga javob berishga, ilovadan foydalanishga yordam berishga tayyorman.';

  @override
  String get assistantSuggestion1 => 'Mahallamda qanday xizmatlar bor?';

  @override
  String get assistantSuggestion2 => 'Murojaat qanday yuboriladi?';

  @override
  String get assistantSuggestion3 => 'Ilovadan qanday foydalanaman?';

  @override
  String get assistantLimitUpsellTitle => 'Kunlik limit tugadi';

  @override
  String get assistantLimitUpsellMessage =>
      'Premium bilan har kuni ancha ko\'proq xabar yuborishingiz mumkin.';

  @override
  String get assistantLimitUpsellButton => 'Premium haqida';

  @override
  String get assistantActionOpenFeedback => 'Fikr bildirish';

  @override
  String get assistantActionOpenServices => 'Xizmatlarni ko\'rish';

  @override
  String get assistantActionOpenHelp => 'Yordam olish';

  @override
  String get assistantActionOpenPremium => 'Premium haqida';

  @override
  String get assistantActionOpenNewRequest => 'Murojaat ekranini ochish';

  @override
  String get assistantActionEditProfile => 'Profil formasini to\'ldirish';

  @override
  String get assistantNewChat => 'Yangi suhbat';

  @override
  String get assistantDeleteChatTitle => 'Suhbatni o\'chirish';

  @override
  String assistantDeleteChatMessage(String title) {
    return '\"$title\" suhbatini butunlay o\'chirmoqchimisiz?';
  }

  @override
  String get notificationPreferencesTitle => 'Bildirishnoma sozlamalari';

  @override
  String get notificationPreferencesSubtitle =>
      'Qaysi turdagi xabarlarni olishni tanlang';

  @override
  String get notificationPreferencesSectionHeader => 'Qaysi xabarlarni olasiz';

  @override
  String get notificationTypeAnnouncementLabel => 'Yangi e\'lonlar';

  @override
  String get notificationTypeEventLabel => 'Yangi tadbirlar';

  @override
  String get notificationTypePollLabel => 'Yangi so\'rovnomalar';

  @override
  String get notificationTypeMessageLabel => 'Yangi xabarlar';

  @override
  String get notificationTypeRequestStatusLabel => 'Murojaat holati';

  @override
  String get offlineBannerMessage => 'Oflayn — internet yo\'q';

  @override
  String get statusHistoryTitle => 'Holat tarixi';

  @override
  String get remindMeAction => 'Eslatib tur';

  @override
  String get reminderSetMessage => 'Eslatma qo\'yildi';

  @override
  String get reminderCancelledMessage => 'Eslatma bekor qilindi';

  @override
  String get eventReminderNotificationTitle => 'Tadbir eslatmasi';

  @override
  String get editMessageAction => 'Tahrirlash';

  @override
  String get messageDeletedPlaceholder => 'Xabar o\'chirildi';

  @override
  String get editedLabel => '(tahrirlangan)';

  @override
  String get recentSearchesTitle => 'So\'nggi qidiruvlar';

  @override
  String get clearRecentSearchesAction => 'Tozalash';

  @override
  String get microphonePermissionDeniedMessage => 'Mikrofonga ruxsat berilmadi';

  @override
  String get serviceAvailableLabel => 'Mavjud';

  @override
  String get serviceBusyLabel => 'Band';

  @override
  String get markBusyToggleLabel => 'Hozir band emasman';

  @override
  String get callAction => 'Qo\'ng\'iroq qilish';

  @override
  String lastSeenLabel(String time) {
    return 'Oxirgi marta: $time';
  }
}

/// The translations for Uzbek, using the Cyrillic script (`uz_Cyrl`).
class AppLocalizationsUzCyrl extends AppLocalizationsUz {
  AppLocalizationsUzCyrl() : super('uz_Cyrl');

  @override
  String get appTitle => 'Менинг маҳаллам';

  @override
  String get splashTagline => 'Сизнинг маҳаллангиз битта иловада';

  @override
  String get onboardingWelcomeTitle => 'Хуш келибсиз!';

  @override
  String get onboardingWelcomeDescription =>
      'Менинг Маҳаллам — маҳаллангиз битта иловада. Келинг, имкониятлар билан таништираман.';

  @override
  String get onboardingAnnouncementsTitle => 'Ҳар доим хабардор бўлинг';

  @override
  String get onboardingAnnouncementsDescription =>
      'Маҳаллангиздаги янгиликлар ва эълонлар тўғридан-тўғри қўлингизда';

  @override
  String get onboardingEventsTitle => 'Тадбирларни ўтказиб юборманг';

  @override
  String get onboardingEventsDescription =>
      'Йиғин, байрам ёки тадбир бўлса — биринчилардан бўлиб билиб оласиз';

  @override
  String get onboardingRequestsTitle => 'Муаммони бир неча босишда ечинг';

  @override
  String get onboardingRequestsDescription =>
      'Кўчада носозлик кўрдингизми? Мурожаат юборинг, раис ва ходимлар дарҳол кўради';

  @override
  String get onboardingNeighborsTitle => 'Қўшниларингиз билан боғланинг';

  @override
  String get onboardingNeighborsDescription =>
      'Кўчангиздагиларни топинг, суҳбатлашинг, бирга маҳаллани яхшиланг';

  @override
  String get previewAnnouncements => 'Эълонлар';

  @override
  String get previewEvents => 'Тадбирлар';

  @override
  String get previewRequests => 'Мурожаатлар';

  @override
  String get previewNeighbors => 'Қўшнилар';

  @override
  String get continueButton => 'Давом этиш';

  @override
  String get skipButton => 'Ўтказиб юбориш';

  @override
  String get loginButton => 'Кириш';

  @override
  String get registerButton => 'Рўйхатдан ўтиш';

  @override
  String get loginTitle => 'Кириш';

  @override
  String get loginSubtitle => 'Маълумотларингизни киритинг';

  @override
  String get phoneLabel => 'Телефон рақам';

  @override
  String get passwordLabel => 'Парол';

  @override
  String get forgotPassword => 'Паролни унутдингизми?';

  @override
  String get orDivider => 'ёки';

  @override
  String get noAccountQuestion => 'Ҳисобингиз йўқми? ';

  @override
  String get phoneValidationError => 'Телефон рақамни тўлиқ киритинг';

  @override
  String get passwordValidationError =>
      'Парол камида 6 та белгидан иборат бўлиши керак';

  @override
  String get unexpectedError => 'Кутилмаган хатолик юз берди';

  @override
  String get registerTitle => 'Рўйхатдан ўтиш';

  @override
  String get registerSubtitle => 'Янги ҳисоб яратиш';

  @override
  String get firstNameLabel => 'Исм';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get firstNameValidationError => 'Исмингизни киритинг';

  @override
  String get lastNameValidationError => 'Фамилиянгизни киритинг';

  @override
  String get haveAccountQuestion => 'Ҳисобингиз борми? ';

  @override
  String get welcomeGreeting => 'Хуш келибсиз';

  @override
  String helloUser(String name) {
    return 'Ассалому алайкум, $name!';
  }

  @override
  String get helloGeneric => 'Ассалому алайкум!';

  @override
  String get guestName => 'меҳмон';

  @override
  String get searchHint => 'Қидириш...';

  @override
  String get categoryAnnouncements => 'Эълонлар';

  @override
  String get categoryEvents => 'Тадбирлар';

  @override
  String get categoryRequests => 'Мурожаатлар';

  @override
  String get categoryNeighbors => 'Қўшнилар';

  @override
  String get upcomingEventsTitle => 'Яқин тадбирлар';

  @override
  String get noUpcomingEvents => 'Ҳозирча яқин тадбирлар йўқ';

  @override
  String get eventsLoadError => 'Тадбирларни юклашда хатолик юз берди';

  @override
  String get today => 'Бугун';

  @override
  String get tomorrow => 'Эртага';

  @override
  String get profileTitle => 'Профил';

  @override
  String get defaultUserName => 'Фойдаланувчи';

  @override
  String get profileLoadError => 'Маълумотларни юклашда хатолик';

  @override
  String get chooseBannerTitle => 'Баннер танланг';

  @override
  String get premiumBannerLockedMessage =>
      'Бу баннер премиум — ҳозирча қулфланган';

  @override
  String get premiumTitle => 'Премиум';

  @override
  String get premiumSettingSubtitle =>
      'Чексиз мурожаат, рекламасиз ва бошқа имкониятлар';

  @override
  String get premiumHeroTitle => 'Премиум обуна';

  @override
  String get premiumHeroSubtitle =>
      'Маҳаллангизда фаолроқ бўлинг — чекловларсиз';

  @override
  String get premiumPerMonth => 'сўм/ой';

  @override
  String get premiumBenefitsTitle => 'НИМАЛАР ОЧИЛАДИ';

  @override
  String get premiumBenefitUnlimited => 'Чексиз мурожаат — кунлик лимит йўқ';

  @override
  String get premiumBenefitNoAds => 'Рекламалар умуман кўринмайди';

  @override
  String get premiumBenefitPriority => 'Мурожаатингиз рўйхатда тепада туради';

  @override
  String get premiumBenefitImages => 'Битта мурожаатга 10 тагача расм';

  @override
  String get premiumBenefitBanners => 'Махсус профил баннерлари';

  @override
  String get premiumBenefitBadge => 'Профилингизда премиум нишони';

  @override
  String get premiumBuyAction => 'Премиум олиш';

  @override
  String get premiumActiveTitle => 'Премиум фаол';

  @override
  String premiumActiveUntil(String date, int days) {
    return '$date гача — $days кун қолди';
  }

  @override
  String get premiumTransferHint =>
      'Қуйидаги картага ўтказма қилинг. Нусха олиш учун устига босинг.';

  @override
  String get premiumCardNumber => 'Карта рақами';

  @override
  String get premiumCardHolder => 'Карта эгаси';

  @override
  String get premiumAmount => 'Тўлов суммаси';

  @override
  String get premiumCardCopied => 'Карта рақами нусхаланди';

  @override
  String get premiumHolderCopied => 'Карта эгаси нусхаланди';

  @override
  String get premiumAmountCopied => 'Сумма нусхаланди';

  @override
  String premiumPaymentTimeLeft(String time) {
    return 'Тўлов учун $time қолди';
  }

  @override
  String get premiumPaymentExpired => 'Тўлов вақти тугади — қайтадан бошланг';

  @override
  String get premiumIPaidAction => 'Тўладим';

  @override
  String get premiumContactAdmin => 'Админ билан Телеграмда';

  @override
  String get premiumTelegramHint =>
      'Тезроқ тасдиқлаш учун чекни Телеграмга юборинг — ихтиёрий.';

  @override
  String get premiumWaitingTitle => 'Тасдиқлаш кутилмоқда';

  @override
  String get premiumWaitingSubtitle =>
      'Админ тўловни текширгач премиум очилади';

  @override
  String get premiumRequestsTitle => 'Премиум сўровлари';

  @override
  String get premiumRequestsEmpty => 'Кутилаётган сўров йўқ';

  @override
  String premiumRequestMonths(int count) {
    return '$count ойлик обуна';
  }

  @override
  String get premiumApproveAction => 'Тасдиқлаш';

  @override
  String get premiumRejectAction => 'Рад этиш';

  @override
  String get adLabel => 'Реклама';

  @override
  String get adManagementTitle => 'Хизмат рекламалари';

  @override
  String get adAddAction => 'Реклама қўшиш';

  @override
  String get adEmptyTitle => 'Ҳозирча реклама йўқ';

  @override
  String get adTitleLabel => 'Хизмат номи';

  @override
  String get adDescriptionLabel => 'Қисқача тавсиф';

  @override
  String get adOwnerLabel => 'Уста / ташкилот номи';

  @override
  String get adTitleRequired => 'Хизмат номини киритинг';

  @override
  String get adSaveAction => 'Сақлаш';

  @override
  String get adStatusActive => 'Фаол';

  @override
  String get adStatusExpired => 'Тугаган';

  @override
  String adActiveUntil(String date) {
    return '$date гача фаол';
  }

  @override
  String get adExtendAction => '7 кунга узайтириш';

  @override
  String get adPromoteTitle => 'Хизматингизни реклама қилинг';

  @override
  String adPromoteSubtitle(String price) {
    return 'Ҳафтасига $price — маҳаллангиз кўради';
  }

  @override
  String get adPromoteAction => 'Реклама бериш';

  @override
  String get noMahallaTitle => 'Аввал маҳаллангизга қўшилинг';

  @override
  String get noMahallaSubtitle =>
      'Маҳалла раиси берган QR кодни сканерланг — шундан кейин эълонлар, мурожаатлар ва қўшниларингиз шу ерда кўринади.';

  @override
  String get noMahallaAction => 'QR кодни сканерлаш';

  @override
  String get emptyAnnouncementsSubtitle =>
      'Маҳалла раиси ёки ходимлари эълон жойлаганда шу ерда кўринади.';

  @override
  String get emptyRequestsSubtitle =>
      'Маҳаллада муаммо бўлса, биринчи мурожаатни сиз юборишингиз мумкин.';

  @override
  String get emptyRequestsAction => 'Мурожаат юбориш';

  @override
  String get emptyNeighborsSubtitle =>
      'Қўшниларингиз иловага қўшилгач шу ерда кўринади. Уларни таклиф қилинг!';

  @override
  String get emptyServicesSubtitle =>
      'Маҳалладаги усталар ва хизматлар шу ерда тўпланади.';

  @override
  String get emptyEventsSubtitle =>
      'Режалаштирилган тадбирлар шу ерда кўринади.';

  @override
  String get premiumBadgeLabel => 'Премиум';

  @override
  String get chooseBadgeStyleTitle => 'Белги услубини танланг';

  @override
  String get premiumBadgeStyleGold => 'Олтин';

  @override
  String get premiumBadgeStyleSapphire => 'Сафир';

  @override
  String get premiumBadgeStyleEmerald => 'Зумрад';

  @override
  String get premiumBadgeStyleRuby => 'Ёқут';

  @override
  String get premiumBadgeStyleSilver => 'Кумуш';

  @override
  String dailyRequestLimitReached(Object count) {
    return 'Кунлик мурожаат лимитига ($count та) етдингиз. Эртага қайта уриниб кўринг ёки Premium билан чексиз юборинг.';
  }

  @override
  String get myInfoMenuItem => 'Менинг маълумотларим';

  @override
  String get notificationsMenuItem => 'Билдиришномалар';

  @override
  String get settingsMenuItem => 'Созламалар';

  @override
  String get helpMenuItem => 'Ёрдам';

  @override
  String get logoutMenuItem => 'Чиқиш';

  @override
  String get logoutConfirmTitle => 'Чиқишни тасдиқланг';

  @override
  String get logoutConfirmMessage => 'Ҳақиқатан ҳам тизимдан чиқмоқчимисиз?';

  @override
  String get cancelButton => 'Бекор қилиш';

  @override
  String get settingsTitle => 'Созламалар';

  @override
  String get sectionMahalla => 'Маҳалла';

  @override
  String get currentMahalla => 'Жорий маҳалла';

  @override
  String get notConnected => 'Боғланмаган';

  @override
  String get unknownValue => 'Номаълум';

  @override
  String get changeButton => 'Алмаштириш';

  @override
  String get changeMahallaTitle => 'Маҳаллани алмаштириш';

  @override
  String get changeMahallaMessage =>
      'Янги маҳаллага QR код сканерлаш ёки кодни қўлда киритиш орқали боғланасиз. Давом этасизми?';

  @override
  String get sectionConvenience => 'Қулайлик';

  @override
  String get sectionGeneral => 'Умумий';

  @override
  String get sectionManagement => 'Бошқарув';

  @override
  String get membersManagementTitle => 'Аъзоларни бошқариш';

  @override
  String get noMembersYet => 'Ҳозирча аъзолар йўқ';

  @override
  String get roleUpdated => 'Рол янгиланди';

  @override
  String get selectRoleTitle => 'Ролни танланг';

  @override
  String get languageSettingTitle => 'Тил';

  @override
  String get languageUpdatedMessage => 'Тил ўзгартирилди';

  @override
  String get appearanceSettingTitle => 'Кўриниш';

  @override
  String get textSizeSettingTitle => 'Матн катталиги';

  @override
  String get eyeComfortTitle => 'Кўз ҳимояси';

  @override
  String get eyeComfortSubtitle => 'Кўк рангни камайтирувчи иссиқ фильтр';

  @override
  String get sectionAbout => 'Илова ҳақида';

  @override
  String get versionLabel => 'Версия';

  @override
  String get statActiveRequests => 'Фаол мурожаатлар';

  @override
  String get statNewAnnouncements => 'Янги эълонлар';

  @override
  String get statUpcomingEvents => 'Яқин тадбирлар';

  @override
  String get myRequestsStat => 'Мурожаатларим';

  @override
  String get myAnnouncementsStat => 'Эълонларим';

  @override
  String get myJoinedStat => 'Қўшилганларим';

  @override
  String get myRequestsTitle => 'Менинг мурожаатларим';

  @override
  String get recentActivityTitle => 'Сўнгги фаолият';

  @override
  String get mahallaStatsTitle => 'Маҳалла статистикаси';

  @override
  String get statsTotalMembers => 'Аъзолар';

  @override
  String get statsActiveRequests => 'Фаол мурожаат';

  @override
  String get statsNewAnnouncements => 'Янги эълон';

  @override
  String get statsUpcomingEvents => 'Яқин тадбир';

  @override
  String get noRecentActivity => 'Ҳозирча фаолият йўқ';

  @override
  String get activityLoadError => 'Фаолиятни юклашда хатолик юз берди';

  @override
  String activityNewAnnouncement(String title) {
    return 'Янги эълон: $title';
  }

  @override
  String activityNewRequest(String title) {
    return 'Янги мурожаат: $title';
  }

  @override
  String activityNewEvent(String title) {
    return 'Янги тадбир: $title';
  }

  @override
  String minutesAgo(int count) {
    return '$count дақиқа олдин';
  }

  @override
  String hoursAgo(int count) {
    return '$count соат олдин';
  }

  @override
  String daysAgo(int count) {
    return '$count кун олдин';
  }

  @override
  String get sectionAccount => 'Ҳисоб';

  @override
  String get changePasswordTitle => 'Паролни ўзгартириш';

  @override
  String get changePhoneTitle => 'Телефон рақамни ўзгартириш';

  @override
  String get deleteAccountTitle => 'Ҳисобни ўчириш';

  @override
  String get deleteAccountConfirmTitle => 'Ҳисобни ўчириш';

  @override
  String get deleteAccountConfirmMessage =>
      'Бу амални ортга қайтариб бўлмайди. Барча маълумотларингиз бутунлай ўчирилади. Давом этасизми?';

  @override
  String get deleteButton => 'Ўчириш';

  @override
  String get editButton => 'Таҳрирлаш';

  @override
  String get sectionDataStorage => 'Маълумотлар ва хотира';

  @override
  String get clearCacheTitle => 'Кешни тозалаш';

  @override
  String get clearCacheSubtitle => 'Вақтинчалик сақланган файлларни ўчиради';

  @override
  String get cacheClearedMessage => 'Кеш тозаланди';

  @override
  String get sectionSupport => 'Ёрдам ва қўллаб-қувватлаш';

  @override
  String get rateAppTitle => 'Иловани баҳолаш';

  @override
  String get feedbackTitle => 'Фикр билдириш';

  @override
  String get feedbackSubtitle =>
      'Илова ҳақидаги фикрингиз биз учун муҳим — маҳалла раҳбариятига тўғридан-тўғри етади.';

  @override
  String get feedbackRatingRequiredError =>
      'Илтимос, юлдузча билан баҳо беринг';

  @override
  String get feedbackMessageLabel => 'Фикрингиз (ихтиёрий)';

  @override
  String get feedbackMessageHint => 'Нима ёқди, нимани яхшилаш керак?';

  @override
  String get feedbackSubmitButton => 'Юбориш';

  @override
  String get feedbackSubmittedMessage => 'Раҳмат! Фикрингиз юборилди';

  @override
  String get feedbackModeRatingTab => 'Баҳо қолдириш';

  @override
  String get feedbackModeQuestionTab => 'Савол / Мурожаат';

  @override
  String get feedbackQuestionTitle => 'Савол ёки мурожаат';

  @override
  String get feedbackQuestionSubtitle =>
      'Саволингизни ёки мурожаатингизни ёзинг — суперадмин кўриб чиқади ва зарур бўлса алоқага чиқади.';

  @override
  String get feedbackQuestionMessageHint =>
      'Саволингиз ёки мурожаатингизни шу ерга ёзинг...';

  @override
  String get feedbackQuestionBadge => 'Савол';

  @override
  String get feedbackListTitle => 'Фойдаланувчи фикрлари';

  @override
  String get noFeedbackFound => 'Ҳозирча фикрлар йўқ';

  @override
  String get unknownUserLabel => 'Номаълум фойдаланувчи';

  @override
  String get requestAuthorLabel => 'Юборган';

  @override
  String get quickNewRequestTitle => 'Янги мурожаат юбориш';

  @override
  String get quickNewRequestSubtitle =>
      'Муаммо борми? Бир неча сонияда юборинг';

  @override
  String get mahalCardTitle => 'Маҳал билан суҳбат';

  @override
  String get mahalCardSubtitle =>
      'Саволларингизга жавоб олинг, мурожаат ёзиб беринг ёки маҳалла ҳақида сўранг';

  @override
  String get openLinkAction => 'Ҳаволани очиш';

  @override
  String get linkOpenFailedMessage => 'Ҳаволани очиб бўлмади';

  @override
  String get bannerManagementTitle => 'Баннерлар';

  @override
  String get addBannerTitle => 'Янги баннер қўшиш';

  @override
  String get bannerTitleLabel => 'Сарлавҳа';

  @override
  String get bannerDescriptionLabel => 'Тавсиф (ихтиёрий)';

  @override
  String get bannerLinkLabel => 'Ҳавола (ихтиёрий, https://...)';

  @override
  String get bannerAttributionLabel => 'Муаллиф/манба (ихтиёрий)';

  @override
  String get bannerImageRequiredError => 'Илтимос, расм танланг';

  @override
  String get bannerTitleRequiredError => 'Илтимос, сарлавҳа киритинг';

  @override
  String get noBannersFound => 'Ҳозирча баннерлар йўқ';

  @override
  String get mahallaOnMapTitle => 'Маҳаллангиз харитада';

  @override
  String get developerTitle => 'Ривожлантирувчи';

  @override
  String get developerSubtitle => 'Маҳаллам жамоаси';

  @override
  String get termsTitle => 'Фойдаланиш шартлари';

  @override
  String get privacyPolicyTitle => 'Махфийлик сиёсати';

  @override
  String get comingSoonMessage => 'Бу функция тез орада қўшилади';

  @override
  String get profileSaved => 'Маълумотлар сақланди';

  @override
  String get saveButton => 'Сақлаш';

  @override
  String get faqTitle => 'Кўп бериладиган саволлар';

  @override
  String get contactUsTitle => 'Биз билан боғланинг';

  @override
  String get callUs => 'Телефон орқали';

  @override
  String get telegramUs => 'Телеграм орқали';

  @override
  String get faqQ1 => 'Маҳаллага қандай қўшиламан?';

  @override
  String get faqA1 =>
      'Рўйхатдан ўтгандан сўнг, маҳалла раиси ёки масъул ходим томонидан берилган QR кодни сканерлаш орқали маҳаллангизга боғланасиз.';

  @override
  String get faqQ2 => 'Мурожаат қандай юбораман?';

  @override
  String get faqA2 =>
      '\"Мурожаат\" бўлимига ўтинг ва янги мурожаат яратинг. Мурожаатингиз ҳолати \"Янги\", \"Жараёнда\" ёки \"Якунланди\" сифатида кўрсатилади.';

  @override
  String get faqQ3 => 'Эълонларни қандай кўраман?';

  @override
  String get faqA3 =>
      'Бош экрандаги \"Эълонлар\" бўлимида маҳаллангизга оид барча расмий эълонлар категориялар бўйича кўрсатилади.';

  @override
  String get faqQ4 => 'Паролимни унутдим, нима қиламан?';

  @override
  String get faqA4 =>
      'Кириш экранидаги «Паролни унутдингизми?» тугмасини босинг. Электрон почтангизга тиклаш ҳаволаси юборилади. Хат келмаса, «Спам» папкасини ҳам текширинг.';

  @override
  String get faqQ5 => 'Маълумотларим хавфсизми?';

  @override
  String get faqA5 =>
      'Ҳа, барча маълумотлар фақат маҳаллангиз доирасида кўринади ва ҳимояланган серверда сақланади.';

  @override
  String get callFailedMessage => 'Қўнғироқ қилиб бўлмади';

  @override
  String get telegramFailedMessage => 'Телеграм очиб бўлмади';

  @override
  String get announcementsTitle => 'Эълонлар';

  @override
  String get eventsTitle => 'Тадбирлар';

  @override
  String get feedTitle => 'Лента';

  @override
  String get postsFilterLabel => 'Постлар';

  @override
  String get noPostsYet => 'Ҳозирча постлар йўқ';

  @override
  String get noPostsHint =>
      'Қўшнилар биринчи пост қилганда, у шу ерда пайдо бўлади.';

  @override
  String get writePostHint => 'Нима гаплар?';

  @override
  String get postCreatedMessage => 'Пост жойланди';

  @override
  String get writePostOrImageError => 'Матн ёзинг ёки расм қўшинг';

  @override
  String get postUpdatedMessage => 'Пост янгиланди';

  @override
  String get editPostTitle => 'Постни таҳрирлаш';

  @override
  String get postingTooFastError =>
      'Жуда тез-тез пост жойлаяпсиз. Бироз кутинг ва қайта уриниб кўринг.';

  @override
  String get inappropriateContentError =>
      'Матнда номақбул сўзлар бор. Илтимос, матнни таҳрирланг.';

  @override
  String get reactionsSheetTitle => 'Реаксиялар';

  @override
  String get addStoryLabel => 'Ҳикоя қўшиш';

  @override
  String get yourStoryLabel => 'Сизнинг ҳикоянгиз';

  @override
  String get newButton => 'Янги';

  @override
  String get noAnnouncementsYet => 'Ҳозирча эълонлар йўқ';

  @override
  String get noEventsYet => 'Ҳозирча тадбирлар йўқ';

  @override
  String get noEventsHint =>
      'Маҳалла раиси ёки ходимлари тадбир эълон қилганда, у шу ерда пайдо бўлади.';

  @override
  String get announcementsLoadError => 'Эълонларни юклашда хатолик юз берди';

  @override
  String participantsCount(int count) {
    return '$count қатнашувчи';
  }

  @override
  String todayAt(String time) {
    return 'Бугун, $time';
  }

  @override
  String get categoryKommunal => 'Коммунал';

  @override
  String get categoryXavfsizlik => 'Хавфсизлик';

  @override
  String get categoryUmumiy => 'Умумий';

  @override
  String get newAnnouncementTitle => 'Янги эълон';

  @override
  String get editAnnouncementTitle => 'Эълонни таҳрирлаш';

  @override
  String get pollsTitle => 'Сўровномалар';

  @override
  String get newPollTitle => 'Янги сўровнома';

  @override
  String get pollQuestionHint => 'Саволингизни ёзинг...';

  @override
  String pollOptionHint(int number) {
    return '$number-вариант';
  }

  @override
  String get addOptionButton => 'Вариант қўшиш';

  @override
  String get fillPollFields => 'Савол ва камида 2 та вариант киритинг';

  @override
  String get pollPostedMessage => 'Сўровнома жойланди';

  @override
  String get noPollsYet => 'Ҳозирча сўровномалар йўқ';

  @override
  String pollVotesCount(int count) {
    return '$count овоз';
  }

  @override
  String get conversationsTitle => 'Хабарлар';

  @override
  String get conversationsMenuItem => 'Хабарлар';

  @override
  String get noConversationsYet => 'Ҳозирча суҳбатлар йўқ';

  @override
  String get noMessagesYet => 'Ҳозирча хабарлар йўқ. Биринчи бўлиб ёзинг!';

  @override
  String get messageHint => 'Хабар ёзинг...';

  @override
  String get sendMessageAction => 'Хабар ёзиш';

  @override
  String get typingIndicator => 'ёзмоқда...';

  @override
  String get attachImageAction => 'Расм бириктириш';

  @override
  String get imageUploadFailed => 'Расм юборилмади. Қайта уриниб кўринг';

  @override
  String get yesterdayLabel => 'Кеча';

  @override
  String get switchMahallaTitle => 'Маҳалла танлаш';

  @override
  String get switchMahallaMenuItem => 'Маҳалла алмаштириш (Супер Админ)';

  @override
  String get switchMahallaMenuItemActive => 'Бошқа маҳаллани бошқаряпсиз';

  @override
  String get exitMahallaModeAction => 'Ўз маҳалламга қайтиш';

  @override
  String get noMahallasFound => 'Маҳаллалар топилмади';

  @override
  String get broadcastToAllMahallasLabel =>
      'Барча маҳаллаларга юбориш (Супер Админ)';

  @override
  String get servicesTitle => 'Маҳаллий хизматлар';

  @override
  String get newServiceTitle => 'Хизмат қўшиш';

  @override
  String get editServiceTitle => 'Хизматни таҳрирлаш';

  @override
  String get serviceCategoryLabel => 'Тоифа';

  @override
  String get serviceNameLabel => 'Исм ёки ташкилот номи';

  @override
  String get serviceNameHint => 'Масалан: Азиз ака (сантехник)';

  @override
  String get servicePhoneLabel => 'Телефон рақами';

  @override
  String get serviceDescriptionLabel => 'Тавсиф';

  @override
  String get serviceDescriptionHint => 'Иш вақти, нархи ва ҳ.к...';

  @override
  String get fillServiceFields => 'Исм ва телефон рақамини киритинг';

  @override
  String get servicePostedMessage => 'Хизмат қўшилди';

  @override
  String get serviceUpdatedMessage => 'Хизмат янгиланди';

  @override
  String get noServicesYet => 'Ҳозирча хизматлар йўқ';

  @override
  String get serviceCategorySantexnik => 'Сантехник';

  @override
  String get serviceCategoryElektrik => 'Электрик';

  @override
  String get serviceCategoryDuradgor => 'Дурадгор';

  @override
  String get serviceCategoryTozalash => 'Тозалаш';

  @override
  String get serviceCategoryQurilish => 'Қурилиш';

  @override
  String get serviceCategoryBoshqa => 'Бошқа';

  @override
  String get editPollTitle => 'Сўровномани таҳрирлаш';

  @override
  String get pollUpdatedMessage => 'Сўровнома янгиланди';

  @override
  String get changeVoteConfirmTitle => 'Овозни алмаштириш';

  @override
  String get changeVoteConfirmMessage =>
      'Сиз аллақачон бошқа вариантга овоз бергансиз. Овозингизни алмаштирмоқчимисиз?';

  @override
  String get changeVoteConfirmButton => 'Ҳа, алмаштириш';

  @override
  String get pollAllowMultipleLabel =>
      'Бир нечта вариант танлашга рухсат бериш';

  @override
  String get pollAnonymousLabel => 'Аноним сўровнома';

  @override
  String get pollClosesAtLabel => 'Ёпилиш санаси (ихтиёрий)';

  @override
  String get pollClosesAtClearButton => 'Тозалаш';

  @override
  String get pollClosedBadge => 'Ёпилган';

  @override
  String get pollVoteClosedError =>
      'Бу сўровнома ёпилган, овоз бериш мумкин эмас';

  @override
  String get pollSubmitVoteButton => 'Овоз бериш';

  @override
  String get categoryServices => 'Хизматлар';

  @override
  String get categoryPolls => 'Сўровномалар';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get titleLabel => 'Сарлавҳа';

  @override
  String get titleHint => 'Масалан: Эртага сув ўчирилиши ҳақида';

  @override
  String get bodyLabel => 'Матн';

  @override
  String get bodyHint => 'Эълон матнини батафсил ёзинг...';

  @override
  String get photoLabel => 'Расм';

  @override
  String get optionalLabel => '(ихтиёрий)';

  @override
  String get postButton => 'Жойлаш';

  @override
  String get fillTitleAndBody => 'Сарлавҳа ва матнни тўлдиринг';

  @override
  String get announcementPosted => 'Эълон муваффақиятли жойланди';

  @override
  String get announcementUpdated => 'Эълон янгиланди';

  @override
  String get requestsTitle => 'Мурожаатлар';

  @override
  String get mustVerifyMahallaFirst =>
      'Аввал маҳаллангизни тасдиқлашингиз керак';

  @override
  String get managementPanelBanner => 'Бошқарув панели — барча мурожаатлар';

  @override
  String get requestsLoadError => 'Мурожаатларни юклашда хатолик юз берди';

  @override
  String joinedCount(int count) {
    return '$count киши қўшилди';
  }

  @override
  String noRequestsWithStatus(String status) {
    return '$status мурожаатлар йўқ';
  }

  @override
  String get filterAll => 'Ҳаммаси';

  @override
  String get noRequestsAtAll => 'Ҳозирча мурожаатлар йўқ';

  @override
  String get statusYangi => 'Янги';

  @override
  String get statusJarayonda => 'Жараёнда';

  @override
  String get statusYakunlandi => 'Якунланди';

  @override
  String get typeMaxfiy => 'Махфий';

  @override
  String get typeOmmaviy => 'Оммавий';

  @override
  String get priorityPast => 'Паст';

  @override
  String get priorityOrtacha => 'Ўртача';

  @override
  String get priorityYuqori => 'Юқори';

  @override
  String get managementPanelTitle => 'Бошқарув панели';

  @override
  String get changeStatusTitle => 'Ҳолатни ўзгартириш';

  @override
  String statusChangedMessage(String status) {
    return 'Ҳолат \"$status\" га ўзгартирилди';
  }

  @override
  String get statusChangeError => 'Ҳолатни ўзгартиришда хатолик юз берди';

  @override
  String get allFilter => 'Барчаси';

  @override
  String get noRequestsFound => 'Мурожаатлар топилмади';

  @override
  String get tapToChangeStatus => 'Ҳолатни ўзгартириш учун босинг';

  @override
  String get stepType => 'Тури';

  @override
  String get stepDetails => 'Тафсилотлар';

  @override
  String get stepLocation => 'Жойлашув';

  @override
  String get stepReview => 'Кўриб чиқиш';

  @override
  String get stepDone => 'Тайёр';

  @override
  String get newRequestTitle => 'Янги мурожаат';

  @override
  String get fillTitleAndDescription => 'Сарлавҳа ва тавсифни тўлдиринг';

  @override
  String get sendButton => 'Юбориш';

  @override
  String get chooseRequestType => 'Мурожаат турини танланг';

  @override
  String get requestTypeExplain =>
      'Бу мурожаатингизни ким кўра олишини белгилайди';

  @override
  String get typeMaxfiyDescription => 'Фақат сиз ва маҳалла раиси кўради';

  @override
  String get typeOmmaviyDescription =>
      'Маҳалладаги ҳамма кўради ва қўшилиши мумкин';

  @override
  String get titleFieldLabel => 'Сарлавҳа';

  @override
  String get titleFieldHint => 'Масалан: Кўча ёритилиши ишламаяпти';

  @override
  String get descriptionLabel => 'Тавсиф';

  @override
  String get descriptionHint => 'Муаммони батафсил тасвирлаб беринг...';

  @override
  String get attachPhotoLabel => 'Расм бириктириш';

  @override
  String get priorityLevelLabel => 'Муҳимлик даражаси';

  @override
  String get reviewDataTitle => 'Маълумотларни текширинг';

  @override
  String get reviewType => 'Тури';

  @override
  String get reviewPriority => 'Муҳимлик';

  @override
  String get reviewLocation => 'Жойлашув';

  @override
  String get reviewLocationSet => 'Белгиланган';

  @override
  String get reviewLocationNotSet => 'Белгиланмаган';

  @override
  String reviewPhotos(int count) {
    return 'Расмлар ($count)';
  }

  @override
  String get requestSentTitle => 'Мурожаат юборилди!';

  @override
  String get requestSentMessage =>
      'Мурожаатингиз қабул қилинди ва кўриб чиқилмоқда';

  @override
  String get backToListButton => 'Рўйхатга қайтиш';

  @override
  String get qrScanInstruction =>
      'Маҳалла эшигидаги QR кодни рамка ичига жойлаштиринг';

  @override
  String get checkingStatus => 'Текширилмоқда...';

  @override
  String get scanningStatus => 'Сканерланмоқда...';

  @override
  String get enterCodeManually => 'Кодни қўлда киритиш';

  @override
  String get enterMahallaCodeTitle => 'Маҳалла кодини киритинг';

  @override
  String get mahallaCodeHint => 'Масалан: Y234-5678';

  @override
  String get confirmButton => 'Тасдиқлаш';

  @override
  String get qrGenericError => 'Хатолик юз берди, қайта уриниб кўринг';

  @override
  String get confirmError =>
      'Тасдиқлашда хатолик юз берди, қайта уриниб кўринг';

  @override
  String get mahallaFoundLabel => 'Маҳалла топилди';

  @override
  String get rescanButton => 'Қайта сканерлаш';

  @override
  String get changePhotoLabel => 'Расмни ўзгартириш';

  @override
  String get birthDateLabel => 'Туғилган сана';

  @override
  String get addressLabel => 'Манзил';

  @override
  String get streetLabel => 'Кўча';

  @override
  String get streetHint => 'Масалан: Боғбон кўчаси';

  @override
  String get houseNumberLabel => 'Уй рақами';

  @override
  String get houseNumberHint => 'Масалан: 15';

  @override
  String get genderLabel => 'Жинси';

  @override
  String get genderMale => 'Эркак';

  @override
  String get genderFemale => 'Аёл';

  @override
  String get notSpecified => 'Кўрсатилмаган';

  @override
  String get selectDate => 'Санани танланг';

  @override
  String get photoUploadError => 'Расм юклашда хатолик юз берди';

  @override
  String get otpTitle => 'Тасдиқлаш коди';

  @override
  String otpSubtitle(String phone) {
    return '$phone рақамига юборилган 6 хонали кодни киритинг';
  }

  @override
  String get otpInvalidCode => 'Код нотўғри, қайтадан киритинг';

  @override
  String get otpResendCode => 'Кодни қайта юбориш';

  @override
  String otpResendCooldown(int seconds) {
    return 'Қайта юбориш ($secondsс)';
  }

  @override
  String get forgotPasswordTitle => 'Паролни тиклаш';

  @override
  String get forgotPasswordSubtitle =>
      'Рўйхатдан ўтган телефон рақамингизни киритинг, унга тасдиқлаш коди юборамиз';

  @override
  String get sendCodeButton => 'Код юбориш';

  @override
  String get newPasswordLabel => 'Янги парол';

  @override
  String get newPasswordTitle => 'Янги парол ўрнатинг';

  @override
  String get newPasswordSubtitle => 'Ҳисобингиз учун янги парол ўйлаб топинг';

  @override
  String get savePasswordButton => 'Паролни сақлаш';

  @override
  String get passwordResetSuccess => 'Паролингиз муваффақиятли янгиланди';

  @override
  String get newEventTitle => 'Янги тадбир';

  @override
  String get editEventTitle => 'Тадбирни таҳрирлаш';

  @override
  String get eventTitleHint => 'Масалан: Маҳалла йиғилиши';

  @override
  String get eventDescriptionHint =>
      'Тадбир ҳақида қўшимча маълумот (ихтиёрий)...';

  @override
  String get pinAnnouncementAction => 'Юқорига маҳкамлаш';

  @override
  String get unpinAnnouncementAction => 'Маҳкамлашни ечиш';

  @override
  String get cannotMessageBlockedUser =>
      'Бу фойдаланувчига хабар юбора олмайсиз.';

  @override
  String get rsvpToggleLabel => 'Қатнашиш белгиси';

  @override
  String get rsvpToggleHint =>
      'Ёқилса, фойдаланувчилар \"Бораман\" деб белгилай олади.';

  @override
  String get rsvpJoinAction => 'Бораман';

  @override
  String get rsvpJoinedLabel => 'Бораман';

  @override
  String get dateLabel => 'Сана';

  @override
  String get selectTime => 'Вақтни танланг';

  @override
  String get locationLabel => 'Манзил';

  @override
  String get locationHint => 'Тадбир ўтказиладиган жой';

  @override
  String get fillEventFields => 'Сарлавҳа ва санани киритинг';

  @override
  String get eventPosted => 'Тадбир жойланди';

  @override
  String get eventUpdated => 'Тадбир янгиланди';

  @override
  String get neighborsTitle => 'Қўшнилар';

  @override
  String get mahalladoshlar => 'Маҳалладошлар';

  @override
  String get yozishmalarTitle => 'Ёзишмалар';

  @override
  String get noNeighborsYet => 'Ҳозирча қўшнилар йўқ';

  @override
  String get onlineNow => 'Онлайн';

  @override
  String get lastSeenUnknown => 'Охирги фаоллик номаълум';

  @override
  String get lastSeenJustNow => 'Ҳозиргина фаол эди';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return '$minutes дақиқа олдин';
  }

  @override
  String lastSeenHoursAgo(int hours) {
    return '$hours соат олдин';
  }

  @override
  String lastSeenDaysAgo(int days) {
    return '$days кун олдин';
  }

  @override
  String get sectionPrivacy => 'Махфийлик';

  @override
  String get showPhoneToNeighborsTitle => 'Телефонни қўшниларга кўрсатиш';

  @override
  String get showPhoneToNeighborsSubtitle =>
      'Ёқилса, Қўшнилар рўйхатида рақамингиз кўринади';

  @override
  String get privacySecurityTitle => 'Махфийлик ва хавфсизлик';

  @override
  String get privacySecuritySubtitle => 'Кўриниш, блокланганлар, парол';

  @override
  String get sectionVisibility => 'Кўриниш';

  @override
  String get showLastSeenTitle => 'Охирги фаолликни кўрсатиш';

  @override
  String get showLastSeenSubtitle =>
      'Ёқилса, қўшнилар онлайн ҳолатингизни кўради';

  @override
  String get sectionBlockedUsers => 'Блокланган фойдаланувчилар';

  @override
  String get blockedUsersTitle => 'Блокланган фойдаланувчилар';

  @override
  String get noBlockedUsers => 'Блокланган фойдаланувчилар йўқ';

  @override
  String blockedUsersCount(int count) {
    return '$count та блокланган';
  }

  @override
  String get blockUserAction => 'Блоклаш';

  @override
  String get blockUserConfirmTitle => 'Фойдаланувчини блоклаш';

  @override
  String blockUserConfirmMessage(String name) {
    return '$name сизга хабар ёза олмайди ва рўйхатингизда кўринмайди. Розимисиз?';
  }

  @override
  String userBlockedMessage(String name) {
    return '$name блокланди';
  }

  @override
  String get unblockAction => 'Блокдан чиқариш';

  @override
  String userUnblockedMessage(String name) {
    return '$name блокдан чиқарилди';
  }

  @override
  String get phoneHiddenByUser => 'Бу фойдаланувчи телефонини яширган';

  @override
  String get markAllAsReadAction => 'Барчасини ўқилган деб белгилаш';

  @override
  String get noNotificationsYet => 'Ҳозирча билдиришномалар йўқ';

  @override
  String get searchPromptText => 'Эълон, тадбир ёки мурожаат қидиринг';

  @override
  String get searchNoResults => 'Ҳеч нарса топилмади';

  @override
  String get requestDetailTitle => 'Мурожаат тафсилотлари';

  @override
  String get requestNotFound => 'Мурожаат топилмади';

  @override
  String get announcementDetailTitle => 'Эълон тафсилотлари';

  @override
  String get announcementNotFound => 'Эълон топилмади';

  @override
  String get eventDetailTitle => 'Тадбир тафсилотлари';

  @override
  String get eventNotFound => 'Тадбир топилмади';

  @override
  String get shareAction => 'Улашиш';

  @override
  String get joinRequestAction => 'Қўшилиш';

  @override
  String get leaveRequestAction => 'Чиқиш';

  @override
  String get mahallaStaffTitle => 'Маҳалла ходимлари';

  @override
  String get mahallaMapTitle => 'Маҳалла харитаси';

  @override
  String get locationStepTitle => 'Жойлашувни белгиланг';

  @override
  String get locationStepSubtitle =>
      'Харитани босиб нуқта қўйинг ёки жорий жойлашувингизни ишлатинг (ихтиёрий)';

  @override
  String get locationPermissionError => 'Жойлашувга рухсат берилмади';

  @override
  String get clearLocationAction => 'Тозалаш';

  @override
  String get boundaryEditorTitle => 'Чегарани белгилаш';

  @override
  String get boundaryEditorHint =>
      'Харитани босиб маҳалла чегараси бўйлаб нуқталар қўйинг (камида 3 та)';

  @override
  String get boundaryMinPointsError => 'Камида 3 та нуқта белгиланг';

  @override
  String get boundarySavedMessage => 'Чегара сақланди';

  @override
  String get saveBoundaryAction => 'Чегарани сақлаш';

  @override
  String get editBoundaryAction => 'Чегарани таҳрирлаш';

  @override
  String get mapLayerSatellite => 'Спутник кўриниши';

  @override
  String get mapLayerStreets => 'Кўча харитаси';

  @override
  String get deleteItemConfirmTitle => 'Ўчириш';

  @override
  String deleteItemConfirmMessage(String title) {
    return '\"$title\" бутунлай ўчирилади. Бу амални ортга қайтариб бўлмайди.';
  }

  @override
  String get itemDeletedMessage => 'Ўчирилди';

  @override
  String get searchNeighborHint => 'Исм бўйича қидириш...';

  @override
  String get currentPasswordLabel => 'Жорий парол';

  @override
  String get confirmPasswordLabel => 'Паролни тасдиқланг';

  @override
  String get passwordMismatchError => 'Пароллар мос келмади';

  @override
  String get newPhoneLabel => 'Янги телефон рақам';

  @override
  String get phoneChangedMessage => 'Телефон рақам муваффақиятли ўзгартирилди';

  @override
  String get termsBody =>
      'Ушбу иловадан фойдаланиш орқали сиз қуйидаги шартларга розилик билдирасиз:\n\n1. Илова маҳалла аҳолиси ва ходимлари ўртасида мулоқотни осонлаштириш учун мўлжалланган.\n2. Фойдаланувчи ўз профилида тўғри ва ҳақиқий маълумот киритиши шарт.\n3. Бошқа фойдаланувчиларга нисбатан ҳақоратли, ноқонуний ёки ёлғон маълумот тарқатиш тақиқланади.\n4. Маҳалла маъмурияти (ходим/раис) томонидан жойлаштирилган эълон ва тадбирлар расмий характерга эга бўлиши мумкин.\n5. Илова маъмурияти қоидабузарлик аниқланган ҳисобларни блоклаш ёки ўчириш ҳуқуқини ўзида сақлаб қолади.';

  @override
  String get privacyPolicyBody =>
      'Сизнинг маълумотларингиз қандай ишлатилади:\n\n1. Исм, фамилия, телефон рақам ва маҳалла маълумотлари фақат маҳалла ичидаги мулоқот учун ишлатилади.\n2. Телефон рақамингиз созламаларда рухсат бермагунингизча бошқа аҳолига кўринмайди.\n3. Охирги фаоллик вақти созламаларда ўчирилиши мумкин.\n4. Маълумотларингиз учинчи томонларга сотилмайди ёки уларга узатилмайди.\n5. Ҳисобингизни ўчиришни сўрасангиз, маълумотларингиз Firestore базасидан олиб ташланади.';

  @override
  String get deleteAccountRequested =>
      'Сўровингиз юборилди. Администратор тез орада ҳисобингизни ўчиради.';

  @override
  String get deleteAccountAlreadyPending =>
      'Сизнинг ўчириш сўровингиз аллақачон кўриб чиқилмоқда.';

  @override
  String get retryButton => 'Қайта уриниш';

  @override
  String get cameraIntroTitle => 'Камерага рухсат керак';

  @override
  String get cameraIntroBody =>
      'Маҳаллангизга қўшилиш учун раис ёки ходим берган QR кодни сканерлаш керак. Камера фақат шу мақсадда ишлатилади — ҳеч қандай расм сақланмайди ва юборилмайди.';

  @override
  String get cameraIntroButton => 'Камерани очиш';

  @override
  String get cameraErrorPermission =>
      'Камерага рухсат берилмаган. Рухсатни телефон созламаларида (Иловалар → Mening Mahallam → Рухсатлар → Камера) ёқишингиз мумкин. Ёки маҳалла кодини қўлда киритинг.';

  @override
  String get cameraErrorUnsupported =>
      'Бу қурилмада QR сканерлаш қўллаб-қувватланмайди. Маҳалла кодини қўлда киритинг.';

  @override
  String get cameraErrorGeneric =>
      'Камера очилмади. Бошқа илова камерани ишлатаётган бўлиши мумкин — уни ёпинг ва қайта уриниб кўринг.';

  @override
  String get noAnnouncementsHint =>
      'Маҳалла раиси ёки ходимлари эълон жойлаганда, у шу ерда биринчи бўлиб пайдо бўлади.';

  @override
  String get noRequestsHint =>
      'Кўча ёритгичи, тозалик, сув ёки бошқа масала бўйича мурожаат юборинг — маҳалла ходимлари жавоб беради.';

  @override
  String get noNeighborsHint =>
      'Маҳалладошларингиз иловага қўшилган сари улар шу ерда кўринади. Қўшниларингизни таклиф қилинг!';

  @override
  String get noPollsHint =>
      'Маҳалла сўровномалари шу ерда чиқади — овоз бериб, қарор қабул қилишда иштирок этасиз.';

  @override
  String get noServicesHint =>
      'Маҳалладаги усталар, дўконлар ва хизматлар шу ерда тўпланади.';

  @override
  String get noConversationsHint =>
      'Қўшнилар бўлимидан бирор кишини танлаб, унга тўғридан-тўғри ёзишингиз мумкин.';

  @override
  String get noNotificationsHint =>
      'Янги эълон, тадбир ёки мурожаатингизга жавоб келганда шу ерда хабар берамиз.';

  @override
  String get currencySom => 'сўм';

  @override
  String get premiumConfigTitle => 'Тўлов реквизитлари';

  @override
  String get premiumConfigHint =>
      'Бу ерда ўзгартирилган қийматлар барча фойдаланувчиларга дарҳол кўринади — иловани янгилаш шарт эмас.';

  @override
  String get premiumConfigSaved => 'Реквизитлар сақланди';

  @override
  String get premiumCardNumberLabel => 'Карта рақами';

  @override
  String get premiumCardNumberInvalid =>
      'Карта рақами 16 та рақамдан иборат бўлиши керак';

  @override
  String get premiumCardHolderLabel => 'Карта эгасининг исми';

  @override
  String get premiumCardHolderInvalid => 'Карта эгасининг исмини киритинг';

  @override
  String get premiumPriceLabel => 'Ойлик нарх';

  @override
  String get premiumPriceInvalid => 'Тўғри нарх киритинг';

  @override
  String get premiumTelegramLabel => 'Telegram фойдаланувчи номи';

  @override
  String get premiumChoosePlan => 'Муддатни танланг';

  @override
  String premiumPlanMonths(int count) {
    return '$count ой';
  }

  @override
  String premiumPriceValue(String amount) {
    return '$amount сўм';
  }

  @override
  String get premiumBenefitAdDiscount =>
      'Хизмат рекламасини жойлаштириш 50% арзон';

  @override
  String get premiumBenefitSupport =>
      'Устувор қўллаб-қувватлаш — мурожаатингиз биринчи кўрилади';

  @override
  String get premiumBenefitAvatar => 'Профил суратида олтин премиум ҳалқа';

  @override
  String get premiumBenefitEarlyAccess =>
      'Янги имкониятлар биринчи бўлиб сизга очилади';

  @override
  String premiumPerMonthAmount(String amount) {
    return 'ойига $amount сўм';
  }

  @override
  String get advertiseTitle => 'Хизматингизни шу ерда реклама қилинг';

  @override
  String advertisePrice(String amount) {
    return 'Ҳафтасига атиги $amount сўм';
  }

  @override
  String advertisePremiumDiscount(String amount) {
    return 'Премиум чегирмангиз — оддий нарх $amount сўм';
  }

  @override
  String get advertiseHowTo =>
      'Реклама жойлаштириш учун маҳалла раиси ёки илова администратори билан боғланинг.';

  @override
  String get photoTooLarge => 'Файл жуда катта. 5 МБ дан кичик расм танланг';

  @override
  String get avatarSourceImage => 'Расм';

  @override
  String get avatarSourceVideo => 'Видео';

  @override
  String get avatarSourceVideoHint =>
      'Биринчи 4 сонияси жонли GIF аватарга айлантирилади';

  @override
  String get videoToGifError =>
      'Видеони GIF\'га айлантириб бўлмади. Бошқа видео билан уриниб кўринг';

  @override
  String get premiumBenefitAnimatedAvatar => 'Жонли (GIF) профил сурати';

  @override
  String get premiumGrantTitle => 'Премиумни қўлда бериш';

  @override
  String get premiumGrantSelfAction => 'Ўзимга бериш';

  @override
  String get premiumGrantPhoneLabel => 'Телефон рақами';

  @override
  String get premiumGrantAction => 'Шу рақамга бериш';

  @override
  String get premiumRevokeAction => 'Шу рақамдан бекор қилиш';

  @override
  String get premiumRevokeConfirmTitle => 'Премиумни бекор қилиш';

  @override
  String premiumRevokeConfirmMessage(String name) {
    return '$name учун премиум обунани муддатидан олдин бекор қилмоқчимисиз?';
  }

  @override
  String premiumRevokedFrom(String name) {
    return '$name учун премиум бекор қилинди';
  }

  @override
  String premiumGrantedSelf(int months) {
    return 'Сизга $months ойлик премиум берилди';
  }

  @override
  String premiumGrantedTo(String name, int months) {
    return '$name — $months ойлик премиум берилди';
  }

  @override
  String get premiumGrantUserNotFound =>
      'Бу рақам билан фойдаланувчи топилмади';

  @override
  String premiumUntilShort(String date) {
    return '$date гача';
  }

  @override
  String get personalInfoSection => 'Шахсий маълумотлар';

  @override
  String get addressSection => 'Манзил';

  @override
  String get mahallaCenterTitle => 'Маҳалла маркази';

  @override
  String get mahallaCenterHint =>
      'Харитага босиб марказни белгиланг ёки тепадаги нишон тугмаси орқали координатани киритинг.';

  @override
  String get mahallaCenterCoordsHint =>
      'Google Maps\'дан нусхалаган координатани қўйинг (кенглик, узунлик).';

  @override
  String get mahallaCenterSaved => 'Маҳалла маркази сақланди';

  @override
  String get boundaryModeLabel => 'Чегара';

  @override
  String get centerModeLabel => 'Марказ';

  @override
  String get saveCenterAction => 'Марказни сақлаш';

  @override
  String get appearanceSystemHint => 'Телефон созламасига эргашади';

  @override
  String get textSizePreviewTitle => 'Маҳалла йиғилиши';

  @override
  String get textSizePreviewBody =>
      'Асосий матн шундай кўринади. Сизга қулай ўлчамни танланг.';

  @override
  String get okButton => 'OK';

  @override
  String get reportAction => 'Шикоят қилиш';

  @override
  String get reportSheetTitle => 'Шикоят қилиш';

  @override
  String get reportReasonLabel => 'Сабаб';

  @override
  String get reportReasonSpam => 'Спам';

  @override
  String get reportReasonHaqoratOmuhandaslik => 'Ҳақорат ёки таҳдид';

  @override
  String get reportReasonAldash => 'Фирибгарлик / алдаш';

  @override
  String get reportReasonNomunosib => 'Номуносиб контент';

  @override
  String get reportReasonBoshqa => 'Бошқа';

  @override
  String get reportDetailsLabel => 'Қўшимча изоҳ';

  @override
  String get reportDetailsHint => 'Батафсил ёзинг (ихтиёрий)';

  @override
  String get reportSubmitAction => 'Юбориш';

  @override
  String get reportSubmittedMessage =>
      'Шикоятингиз қабул қилинди, кўриб чиқамиз';

  @override
  String get reportErrorMessage => 'Шикоят юборишда хатолик юз берди';

  @override
  String get reportChooseReasonError => 'Илтимос, сабабни танланг';

  @override
  String serviceRatingCount(int count) {
    return '$count баҳо';
  }

  @override
  String get serviceNoRatingsYet => 'Ҳали баҳо йўқ';

  @override
  String get yourRatingLabel => 'Сизнинг баҳойингиз';

  @override
  String get assignStaffTitle => 'Ходимга бириктириш';

  @override
  String get noStaffFoundLabel => 'Маҳаллада ходим топилмади';

  @override
  String get cancelAssignmentAction => 'Бириктиришни бекор қилиш';

  @override
  String get requestAssignedMessage => 'Мурожаат бириктирилди';

  @override
  String get dueDateSetMessage => 'Муддат белгиланди';

  @override
  String get assignAction => 'Бириктириш';

  @override
  String get setDueDateAction => 'Муддат белгилаш';

  @override
  String assignedToLabel(String fullName) {
    return 'Бириктирилган: $fullName';
  }

  @override
  String dueDateLabel(String date) {
    return 'Муддат: $date';
  }

  @override
  String get dueDateOverdueSuffix => ' — муддати ўтди';

  @override
  String get commentsTitle => 'Изоҳлар';

  @override
  String get noCommentsYet => 'Ҳозирча изоҳлар йўқ';

  @override
  String get commentHint => 'Изоҳ ёзинг...';

  @override
  String get similarRequestsTitle => 'Ўхшаш мурожаатлар';

  @override
  String get createGroupAction => 'Гуруҳ яратиш';

  @override
  String get groupNameLabel => 'Гуруҳ номи';

  @override
  String get groupNameHint => 'Масалан: Кўча фаоллари';

  @override
  String get selectMembersLabel => 'Аъзоларни танланг';

  @override
  String selectMembersLabelWithCount(int count) {
    return 'Аъзоларни танланг ($count)';
  }

  @override
  String get enterGroupNameError => 'Гуруҳ номини киритинг';

  @override
  String get selectAtLeastOneMemberError => 'Камида битта аъзо танланг';

  @override
  String get groupCreateError => 'Гуруҳ яратишда хатолик юз берди';

  @override
  String get groupsSectionTitle => 'Гуруҳлар';

  @override
  String get locationFieldLabel => 'Жойлашув';

  @override
  String get locationSetLabel => 'Жойлашув белгиланди';

  @override
  String get setLocationLabel => 'Жойлашувни белгилаш';

  @override
  String get locationDetectError =>
      'Жойлашувни аниқлаб бўлмади. Рухсат ёки GPS ҳолатини текширинг.';

  @override
  String get tapMapHint => 'Харитани босиб нуқта белгиланг';

  @override
  String get assistantScreenTitle => 'Mahal';

  @override
  String get assistantSubtitleLabel => 'AI ёрдамчи';

  @override
  String get assistantInputHint => 'Саволингизни ёзинг...';

  @override
  String get assistantGreetingTitle => 'Салом! Мен Mahalman';

  @override
  String get assistantGreetingSubtitle =>
      'Маҳалла ҳақида саволларингизга жавоб беришга, иловадан фойдаланишга ёрдам беришга тайёрман.';

  @override
  String get assistantSuggestion1 => 'Маҳалламда қандай хизматлар бор?';

  @override
  String get assistantSuggestion2 => 'Мурожаат қандай юборилади?';

  @override
  String get assistantSuggestion3 => 'Иловадан қандай фойдаланаман?';

  @override
  String get assistantLimitUpsellTitle => 'Кунлик лимит тугади';

  @override
  String get assistantLimitUpsellMessage =>
      'Premium билан ҳар куни анча кўпроқ хабар юборишингиз мумкин.';

  @override
  String get assistantLimitUpsellButton => 'Premium ҳақида';

  @override
  String get assistantActionOpenFeedback => 'Фикр билдириш';

  @override
  String get assistantActionOpenServices => 'Хизматларни кўриш';

  @override
  String get assistantActionOpenHelp => 'Ёрдам олиш';

  @override
  String get assistantActionOpenPremium => 'Premium ҳақида';

  @override
  String get assistantActionOpenNewRequest => 'Мурожаат экранини очиш';

  @override
  String get assistantActionEditProfile => 'Профил формасини тўлдириш';

  @override
  String get assistantNewChat => 'Янги суҳбат';

  @override
  String get assistantDeleteChatTitle => 'Суҳбатни ўчириш';

  @override
  String assistantDeleteChatMessage(String title) {
    return '\"$title\" суҳбатини бутунлай ўчирмоқчимисиз?';
  }

  @override
  String get notificationPreferencesTitle => 'Билдиришнома созламалари';

  @override
  String get notificationPreferencesSubtitle =>
      'Қайси турдаги хабарларни олишни танланг';

  @override
  String get notificationPreferencesSectionHeader => 'Қайси хабарларни оласиз';

  @override
  String get notificationTypeAnnouncementLabel => 'Янги эълонлар';

  @override
  String get notificationTypeEventLabel => 'Янги тадбирлар';

  @override
  String get notificationTypePollLabel => 'Янги сўровномалар';

  @override
  String get notificationTypeMessageLabel => 'Янги хабарлар';

  @override
  String get notificationTypeRequestStatusLabel => 'Мурожаат ҳолати';

  @override
  String get offlineBannerMessage => 'Офлайн — интернет йўқ';

  @override
  String get statusHistoryTitle => 'Ҳолат тарихи';

  @override
  String get remindMeAction => 'Эслатиб тур';

  @override
  String get reminderSetMessage => 'Эслатма қўйилди';

  @override
  String get reminderCancelledMessage => 'Эслатма бекор қилинди';

  @override
  String get eventReminderNotificationTitle => 'Тадбир эслатмаси';

  @override
  String get editMessageAction => 'Таҳрирлаш';

  @override
  String get messageDeletedPlaceholder => 'Хабар ўчирилди';

  @override
  String get editedLabel => '(таҳрирланган)';

  @override
  String get recentSearchesTitle => 'Сўнгги қидирувлар';

  @override
  String get clearRecentSearchesAction => 'Тозалаш';

  @override
  String get microphonePermissionDeniedMessage => 'Микрофонга рухсат берилмади';

  @override
  String get serviceAvailableLabel => 'Мавжуд';

  @override
  String get serviceBusyLabel => 'Банд';

  @override
  String get markBusyToggleLabel => 'Ҳозир банд эмасман';

  @override
  String get callAction => 'Қўнғироқ қилиш';

  @override
  String lastSeenLabel(String time) {
    return 'Охирги марта: $time';
  }
}
