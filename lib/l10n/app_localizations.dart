import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
    Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl')
  ];

  /// Ilova nomi, splash ekranida ko'rinadi
  ///
  /// In uz, this message translates to:
  /// **'Mening Mahallam'**
  String get appTitle;

  /// No description provided for @splashTagline.
  ///
  /// In uz, this message translates to:
  /// **'Sizning mahallangiz bitta ilovada'**
  String get splashTagline;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz!'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeDescription.
  ///
  /// In uz, this message translates to:
  /// **'Mening Mahallam — mahallangiz bitta ilovada. Keling, imkoniyatlar bilan tanishtiraman.'**
  String get onboardingWelcomeDescription;

  /// No description provided for @onboardingAnnouncementsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Har doim xabardor bo\'ling'**
  String get onboardingAnnouncementsTitle;

  /// No description provided for @onboardingAnnouncementsDescription.
  ///
  /// In uz, this message translates to:
  /// **'Mahallangizdagi yangiliklar va e\'lonlar to\'g\'ridan-to\'g\'ri qo\'lingizda'**
  String get onboardingAnnouncementsDescription;

  /// No description provided for @onboardingEventsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirlarni o\'tkazib yubormang'**
  String get onboardingEventsTitle;

  /// No description provided for @onboardingEventsDescription.
  ///
  /// In uz, this message translates to:
  /// **'Yig\'in, bayram yoki tadbir bo\'lsa — birinchilardan bo\'lib bilib olasiz'**
  String get onboardingEventsDescription;

  /// No description provided for @onboardingRequestsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Muammoni bir necha bosishda yeching'**
  String get onboardingRequestsTitle;

  /// No description provided for @onboardingRequestsDescription.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'chada nosozlik ko\'rdingizmi? Murojaat yuboring, rais va xodimlar darhol ko\'radi'**
  String get onboardingRequestsDescription;

  /// No description provided for @onboardingNeighborsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilaringiz bilan bog\'laning'**
  String get onboardingNeighborsTitle;

  /// No description provided for @onboardingNeighborsDescription.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'changizdagilarni toping, suhbatlashing, birga mahallani yaxshilang'**
  String get onboardingNeighborsDescription;

  /// No description provided for @previewAnnouncements.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlar'**
  String get previewAnnouncements;

  /// No description provided for @previewEvents.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirlar'**
  String get previewEvents;

  /// No description provided for @previewRequests.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlar'**
  String get previewRequests;

  /// No description provided for @previewNeighbors.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilar'**
  String get previewNeighbors;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueButton;

  /// No description provided for @skipButton.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazib yuborish'**
  String get skipButton;

  /// No description provided for @loginButton.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get registerButton;

  /// No description provided for @loginTitle.
  ///
  /// In uz, this message translates to:
  /// **'Kirish'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlaringizni kiriting'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam'**
  String get phoneLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In uz, this message translates to:
  /// **'Parol'**
  String get passwordLabel;

  /// No description provided for @forgotPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni unutdingizmi?'**
  String get forgotPassword;

  /// No description provided for @orDivider.
  ///
  /// In uz, this message translates to:
  /// **'yoki'**
  String get orDivider;

  /// No description provided for @noAccountQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz yo\'qmi? '**
  String get noAccountQuestion;

  /// No description provided for @phoneValidationError.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamni to\'liq kiriting'**
  String get phoneValidationError;

  /// No description provided for @passwordValidationError.
  ///
  /// In uz, this message translates to:
  /// **'Parol kamida 6 ta belgidan iborat bo\'lishi kerak'**
  String get passwordValidationError;

  /// No description provided for @unexpectedError.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmagan xatolik yuz berdi'**
  String get unexpectedError;

  /// No description provided for @registerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi hisob yaratish'**
  String get registerSubtitle;

  /// No description provided for @firstNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ism'**
  String get firstNameLabel;

  /// No description provided for @lastNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Familiya'**
  String get lastNameLabel;

  /// No description provided for @firstNameValidationError.
  ///
  /// In uz, this message translates to:
  /// **'Ismingizni kiriting'**
  String get firstNameValidationError;

  /// No description provided for @lastNameValidationError.
  ///
  /// In uz, this message translates to:
  /// **'Familiyangizni kiriting'**
  String get lastNameValidationError;

  /// No description provided for @haveAccountQuestion.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz bormi? '**
  String get haveAccountQuestion;

  /// No description provided for @welcomeGreeting.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz'**
  String get welcomeGreeting;

  /// No description provided for @helloUser.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum, {name}!'**
  String helloUser(String name);

  /// No description provided for @helloGeneric.
  ///
  /// In uz, this message translates to:
  /// **'Assalomu alaykum!'**
  String get helloGeneric;

  /// No description provided for @guestName.
  ///
  /// In uz, this message translates to:
  /// **'mehmon'**
  String get guestName;

  /// No description provided for @searchHint.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish...'**
  String get searchHint;

  /// No description provided for @categoryAnnouncements.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlar'**
  String get categoryAnnouncements;

  /// No description provided for @categoryEvents.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirlar'**
  String get categoryEvents;

  /// No description provided for @categoryRequests.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlar'**
  String get categoryRequests;

  /// No description provided for @categoryNeighbors.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilar'**
  String get categoryNeighbors;

  /// No description provided for @upcomingEventsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin tadbirlar'**
  String get upcomingEventsTitle;

  /// No description provided for @noUpcomingEvents.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha yaqin tadbirlar yo\'q'**
  String get noUpcomingEvents;

  /// No description provided for @eventsLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirlarni yuklashda xatolik yuz berdi'**
  String get eventsLoadError;

  /// No description provided for @today.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In uz, this message translates to:
  /// **'Ertaga'**
  String get tomorrow;

  /// No description provided for @profileTitle.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @defaultUserName.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi'**
  String get defaultUserName;

  /// No description provided for @profileLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni yuklashda xatolik'**
  String get profileLoadError;

  /// No description provided for @chooseBannerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Banner tanlang'**
  String get chooseBannerTitle;

  /// No description provided for @premiumBannerLockedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Bu banner premium — hozircha qulflangan'**
  String get premiumBannerLockedMessage;

  /// No description provided for @premiumTitle.
  ///
  /// In uz, this message translates to:
  /// **'Premium'**
  String get premiumTitle;

  /// No description provided for @premiumSettingSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Cheksiz murojaat, reklamasiz va boshqa imkoniyatlar'**
  String get premiumSettingSubtitle;

  /// No description provided for @premiumHeroTitle.
  ///
  /// In uz, this message translates to:
  /// **'Premium obuna'**
  String get premiumHeroTitle;

  /// No description provided for @premiumHeroSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahallangizda faolroq bo\'ling — cheklovlarsiz'**
  String get premiumHeroSubtitle;

  /// No description provided for @premiumPerMonth.
  ///
  /// In uz, this message translates to:
  /// **'so\'m/oy'**
  String get premiumPerMonth;

  /// No description provided for @premiumBenefitsTitle.
  ///
  /// In uz, this message translates to:
  /// **'NIMALAR OCHILADI'**
  String get premiumBenefitsTitle;

  /// No description provided for @premiumBenefitUnlimited.
  ///
  /// In uz, this message translates to:
  /// **'Cheksiz murojaat — kunlik limit yo\'q'**
  String get premiumBenefitUnlimited;

  /// No description provided for @premiumBenefitNoAds.
  ///
  /// In uz, this message translates to:
  /// **'Reklamalar umuman ko\'rinmaydi'**
  String get premiumBenefitNoAds;

  /// No description provided for @premiumBenefitPriority.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatingiz ro\'yxatda tepada turadi'**
  String get premiumBenefitPriority;

  /// No description provided for @premiumBenefitImages.
  ///
  /// In uz, this message translates to:
  /// **'Bitta murojaatga 10 tagacha rasm'**
  String get premiumBenefitImages;

  /// No description provided for @premiumBenefitBanners.
  ///
  /// In uz, this message translates to:
  /// **'Maxsus profil bannerlari'**
  String get premiumBenefitBanners;

  /// No description provided for @premiumBenefitBadge.
  ///
  /// In uz, this message translates to:
  /// **'Profilingizda premium nishoni'**
  String get premiumBenefitBadge;

  /// No description provided for @premiumBuyAction.
  ///
  /// In uz, this message translates to:
  /// **'Premium olish'**
  String get premiumBuyAction;

  /// No description provided for @premiumActiveTitle.
  ///
  /// In uz, this message translates to:
  /// **'Premium faol'**
  String get premiumActiveTitle;

  /// No description provided for @premiumActiveUntil.
  ///
  /// In uz, this message translates to:
  /// **'{date} gacha — {days} kun qoldi'**
  String premiumActiveUntil(String date, int days);

  /// No description provided for @premiumTransferHint.
  ///
  /// In uz, this message translates to:
  /// **'Quyidagi kartaga o\'tkazma qiling. Nusxa olish uchun ustiga bosing.'**
  String get premiumTransferHint;

  /// No description provided for @premiumCardNumber.
  ///
  /// In uz, this message translates to:
  /// **'Karta raqami'**
  String get premiumCardNumber;

  /// No description provided for @premiumCardHolder.
  ///
  /// In uz, this message translates to:
  /// **'Karta egasi'**
  String get premiumCardHolder;

  /// No description provided for @premiumAmount.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov summasi'**
  String get premiumAmount;

  /// No description provided for @premiumCardCopied.
  ///
  /// In uz, this message translates to:
  /// **'Karta raqami nusxalandi'**
  String get premiumCardCopied;

  /// No description provided for @premiumHolderCopied.
  ///
  /// In uz, this message translates to:
  /// **'Karta egasi nusxalandi'**
  String get premiumHolderCopied;

  /// No description provided for @premiumAmountCopied.
  ///
  /// In uz, this message translates to:
  /// **'Summa nusxalandi'**
  String get premiumAmountCopied;

  /// No description provided for @premiumPaymentTimeLeft.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov uchun {time} qoldi'**
  String premiumPaymentTimeLeft(String time);

  /// No description provided for @premiumPaymentExpired.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov vaqti tugadi — qaytadan boshlang'**
  String get premiumPaymentExpired;

  /// No description provided for @premiumIPaidAction.
  ///
  /// In uz, this message translates to:
  /// **'To\'ladim'**
  String get premiumIPaidAction;

  /// No description provided for @premiumContactAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Admin bilan Telegramda'**
  String get premiumContactAdmin;

  /// No description provided for @premiumTelegramHint.
  ///
  /// In uz, this message translates to:
  /// **'Tezroq tasdiqlash uchun chekni Telegramga yuboring — ixtiyoriy.'**
  String get premiumTelegramHint;

  /// No description provided for @premiumWaitingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kutilmoqda'**
  String get premiumWaitingTitle;

  /// No description provided for @premiumWaitingSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Admin to\'lovni tekshirgach premium ochiladi'**
  String get premiumWaitingSubtitle;

  /// No description provided for @premiumRequestsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Premium so\'rovlari'**
  String get premiumRequestsTitle;

  /// No description provided for @premiumRequestsEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Kutilayotgan so\'rov yo\'q'**
  String get premiumRequestsEmpty;

  /// No description provided for @premiumRequestMonths.
  ///
  /// In uz, this message translates to:
  /// **'{count} oylik obuna'**
  String premiumRequestMonths(int count);

  /// No description provided for @premiumApproveAction.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get premiumApproveAction;

  /// No description provided for @premiumRejectAction.
  ///
  /// In uz, this message translates to:
  /// **'Rad etish'**
  String get premiumRejectAction;

  /// No description provided for @adLabel.
  ///
  /// In uz, this message translates to:
  /// **'Reklama'**
  String get adLabel;

  /// No description provided for @adManagementTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat reklamalari'**
  String get adManagementTitle;

  /// No description provided for @adAddAction.
  ///
  /// In uz, this message translates to:
  /// **'Reklama qo\'shish'**
  String get adAddAction;

  /// No description provided for @adEmptyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha reklama yo\'q'**
  String get adEmptyTitle;

  /// No description provided for @adTitleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat nomi'**
  String get adTitleLabel;

  /// No description provided for @adDescriptionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qisqacha tavsif'**
  String get adDescriptionLabel;

  /// No description provided for @adOwnerLabel.
  ///
  /// In uz, this message translates to:
  /// **'Usta / tashkilot nomi'**
  String get adOwnerLabel;

  /// No description provided for @adTitleRequired.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat nomini kiriting'**
  String get adTitleRequired;

  /// No description provided for @adSaveAction.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get adSaveAction;

  /// No description provided for @adStatusActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get adStatusActive;

  /// No description provided for @adStatusExpired.
  ///
  /// In uz, this message translates to:
  /// **'Tugagan'**
  String get adStatusExpired;

  /// No description provided for @adActiveUntil.
  ///
  /// In uz, this message translates to:
  /// **'{date} gacha faol'**
  String adActiveUntil(String date);

  /// No description provided for @adExtendAction.
  ///
  /// In uz, this message translates to:
  /// **'7 kunga uzaytirish'**
  String get adExtendAction;

  /// No description provided for @adPromoteTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xizmatingizni reklama qiling'**
  String get adPromoteTitle;

  /// No description provided for @adPromoteSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Haftasiga {price} — mahallangiz ko\'radi'**
  String adPromoteSubtitle(String price);

  /// No description provided for @adPromoteAction.
  ///
  /// In uz, this message translates to:
  /// **'Reklama berish'**
  String get adPromoteAction;

  /// No description provided for @noMahallaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Avval mahallangizga qo\'shiling'**
  String get noMahallaTitle;

  /// No description provided for @noMahallaSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla raisi bergan QR kodni skanerlang — shundan keyin e\'lonlar, murojaatlar va qo\'shnilaringiz shu yerda ko\'rinadi.'**
  String get noMahallaSubtitle;

  /// No description provided for @noMahallaAction.
  ///
  /// In uz, this message translates to:
  /// **'QR kodni skanerlash'**
  String get noMahallaAction;

  /// No description provided for @emptyAnnouncementsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla raisi yoki xodimlari e\'lon joylaganda shu yerda ko\'rinadi.'**
  String get emptyAnnouncementsSubtitle;

  /// No description provided for @emptyRequestsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahallada muammo bo\'lsa, birinchi murojaatni siz yuborishingiz mumkin.'**
  String get emptyRequestsSubtitle;

  /// No description provided for @emptyRequestsAction.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat yuborish'**
  String get emptyRequestsAction;

  /// No description provided for @emptyNeighborsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilaringiz ilovaga qo\'shilgach shu yerda ko\'rinadi. Ularni taklif qiling!'**
  String get emptyNeighborsSubtitle;

  /// No description provided for @emptyServicesSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalladagi ustalar va xizmatlar shu yerda to\'planadi.'**
  String get emptyServicesSubtitle;

  /// No description provided for @emptyEventsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Rejalashtirilgan tadbirlar shu yerda ko\'rinadi.'**
  String get emptyEventsSubtitle;

  /// No description provided for @premiumBadgeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Premium'**
  String get premiumBadgeLabel;

  /// Premium foydalanuvchi o'z ismiga qo'yiladigan PremiumBadge ikonka/rang uslubini tanlaydigan pastdan chiquvchi varaq sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Belgi uslubini tanlang'**
  String get chooseBadgeStyleTitle;

  /// PremiumBadge uslublaridan biri nomi (tanlov varag'ida ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Oltin'**
  String get premiumBadgeStyleGold;

  /// PremiumBadge uslublaridan biri nomi (tanlov varag'ida ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Safir'**
  String get premiumBadgeStyleSapphire;

  /// PremiumBadge uslublaridan biri nomi (tanlov varag'ida ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Zumrad'**
  String get premiumBadgeStyleEmerald;

  /// PremiumBadge uslublaridan biri nomi (tanlov varag'ida ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Yoqut'**
  String get premiumBadgeStyleRuby;

  /// PremiumBadge uslublaridan biri nomi (tanlov varag'ida ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Kumush'**
  String get premiumBadgeStyleSilver;

  /// No description provided for @dailyRequestLimitReached.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik murojaat limitiga ({count} ta) yetdingiz. Ertaga qayta urinib ko\'ring yoki Premium bilan cheksiz yuboring.'**
  String dailyRequestLimitReached(Object count);

  /// No description provided for @myInfoMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Mening ma\'lumotlarim'**
  String get myInfoMenuItem;

  /// No description provided for @notificationsMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnomalar'**
  String get notificationsMenuItem;

  /// No description provided for @settingsMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsMenuItem;

  /// No description provided for @helpMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Yordam'**
  String get helpMenuItem;

  /// No description provided for @logoutMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get logoutMenuItem;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Chiqishni tasdiqlang'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'Haqiqatan ham tizimdan chiqmoqchimisiz?'**
  String get logoutConfirmMessage;

  /// No description provided for @cancelButton.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancelButton;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsTitle;

  /// No description provided for @sectionMahalla.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla'**
  String get sectionMahalla;

  /// No description provided for @currentMahalla.
  ///
  /// In uz, this message translates to:
  /// **'Joriy mahalla'**
  String get currentMahalla;

  /// No description provided for @notConnected.
  ///
  /// In uz, this message translates to:
  /// **'Bog\'lanmagan'**
  String get notConnected;

  /// No description provided for @unknownValue.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum'**
  String get unknownValue;

  /// No description provided for @changeButton.
  ///
  /// In uz, this message translates to:
  /// **'Almashtirish'**
  String get changeButton;

  /// No description provided for @changeMahallaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahallani almashtirish'**
  String get changeMahallaTitle;

  /// No description provided for @changeMahallaMessage.
  ///
  /// In uz, this message translates to:
  /// **'Yangi mahallaga QR kod skanerlash yoki kodni qo\'lda kiritish orqali bog\'lanasiz. Davom etasizmi?'**
  String get changeMahallaMessage;

  /// No description provided for @sectionGeneral.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy'**
  String get sectionGeneral;

  /// No description provided for @sectionManagement.
  ///
  /// In uz, this message translates to:
  /// **'Boshqaruv'**
  String get sectionManagement;

  /// No description provided for @membersManagementTitle.
  ///
  /// In uz, this message translates to:
  /// **'A\'zolarni boshqarish'**
  String get membersManagementTitle;

  /// No description provided for @noMembersYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha a\'zolar yo\'q'**
  String get noMembersYet;

  /// No description provided for @roleUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Rol yangilandi'**
  String get roleUpdated;

  /// No description provided for @selectRoleTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rolni tanlang'**
  String get selectRoleTitle;

  /// No description provided for @languageSettingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get languageSettingTitle;

  /// No description provided for @languageUpdatedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Til o\'zgartirildi'**
  String get languageUpdatedMessage;

  /// No description provided for @appearanceSettingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rinish'**
  String get appearanceSettingTitle;

  /// No description provided for @textSizeSettingTitle.
  ///
  /// In uz, this message translates to:
  /// **'Matn kattaligi'**
  String get textSizeSettingTitle;

  /// No description provided for @sectionAbout.
  ///
  /// In uz, this message translates to:
  /// **'Ilova haqida'**
  String get sectionAbout;

  /// No description provided for @versionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Versiya'**
  String get versionLabel;

  /// No description provided for @statActiveRequests.
  ///
  /// In uz, this message translates to:
  /// **'Faol murojaatlar'**
  String get statActiveRequests;

  /// No description provided for @statNewAnnouncements.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lonlar'**
  String get statNewAnnouncements;

  /// No description provided for @statUpcomingEvents.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin tadbirlar'**
  String get statUpcomingEvents;

  /// No description provided for @myRequestsStat.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlarim'**
  String get myRequestsStat;

  /// No description provided for @myAnnouncementsStat.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlarim'**
  String get myAnnouncementsStat;

  /// No description provided for @myJoinedStat.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shilganlarim'**
  String get myJoinedStat;

  /// No description provided for @myRequestsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mening murojaatlarim'**
  String get myRequestsTitle;

  /// No description provided for @recentActivityTitle.
  ///
  /// In uz, this message translates to:
  /// **'So\'nggi faoliyat'**
  String get recentActivityTitle;

  /// No description provided for @mahallaStatsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla statistikasi'**
  String get mahallaStatsTitle;

  /// No description provided for @statsTotalMembers.
  ///
  /// In uz, this message translates to:
  /// **'A\'zolar'**
  String get statsTotalMembers;

  /// No description provided for @statsActiveRequests.
  ///
  /// In uz, this message translates to:
  /// **'Faol murojaat'**
  String get statsActiveRequests;

  /// No description provided for @statsNewAnnouncements.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lon'**
  String get statsNewAnnouncements;

  /// No description provided for @statsUpcomingEvents.
  ///
  /// In uz, this message translates to:
  /// **'Yaqin tadbir'**
  String get statsUpcomingEvents;

  /// No description provided for @noRecentActivity.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha faoliyat yo\'q'**
  String get noRecentActivity;

  /// No description provided for @activityLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Faoliyatni yuklashda xatolik yuz berdi'**
  String get activityLoadError;

  /// No description provided for @activityNewAnnouncement.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lon: {title}'**
  String activityNewAnnouncement(String title);

  /// No description provided for @activityNewRequest.
  ///
  /// In uz, this message translates to:
  /// **'Yangi murojaat: {title}'**
  String activityNewRequest(String title);

  /// No description provided for @activityNewEvent.
  ///
  /// In uz, this message translates to:
  /// **'Yangi tadbir: {title}'**
  String activityNewEvent(String title);

  /// No description provided for @minutesAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} daqiqa oldin'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} soat oldin'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} kun oldin'**
  String daysAgo(int count);

  /// No description provided for @sectionAccount.
  ///
  /// In uz, this message translates to:
  /// **'Hisob'**
  String get sectionAccount;

  /// No description provided for @changePasswordTitle.
  ///
  /// In uz, this message translates to:
  /// **'Parolni o\'zgartirish'**
  String get changePasswordTitle;

  /// No description provided for @changePhoneTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamni o\'zgartirish'**
  String get changePhoneTitle;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni o\'chirish'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobni o\'chirish'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'Bu amalni ortga qaytarib bo\'lmaydi. Barcha ma\'lumotlaringiz butunlay o\'chiriladi. Davom etasizmi?'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteButton.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get deleteButton;

  /// No description provided for @editButton.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get editButton;

  /// No description provided for @sectionDataStorage.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar va xotira'**
  String get sectionDataStorage;

  /// No description provided for @clearCacheTitle.
  ///
  /// In uz, this message translates to:
  /// **'Keshni tozalash'**
  String get clearCacheTitle;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtinchalik saqlangan fayllarni o\'chiradi'**
  String get clearCacheSubtitle;

  /// No description provided for @cacheClearedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Kesh tozalandi'**
  String get cacheClearedMessage;

  /// No description provided for @sectionSupport.
  ///
  /// In uz, this message translates to:
  /// **'Yordam va qo\'llab-quvvatlash'**
  String get sectionSupport;

  /// No description provided for @rateAppTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilovani baholash'**
  String get rateAppTitle;

  /// No description provided for @feedbackTitle.
  ///
  /// In uz, this message translates to:
  /// **'Fikr bildirish'**
  String get feedbackTitle;

  /// No description provided for @feedbackSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ilova haqidagi fikringiz bizga muhim — mahalla rahbariyatiga to\'g\'ridan-to\'g\'ri yetadi.'**
  String get feedbackSubtitle;

  /// No description provided for @feedbackRatingRequiredError.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, yulduzcha bilan baho bering'**
  String get feedbackRatingRequiredError;

  /// No description provided for @feedbackMessageLabel.
  ///
  /// In uz, this message translates to:
  /// **'Fikringiz (ixtiyoriy)'**
  String get feedbackMessageLabel;

  /// No description provided for @feedbackMessageHint.
  ///
  /// In uz, this message translates to:
  /// **'Nima yoqdi, nimani yaxshilash kerak?'**
  String get feedbackMessageHint;

  /// No description provided for @feedbackSubmitButton.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get feedbackSubmitButton;

  /// No description provided for @feedbackSubmittedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Rahmat! Fikringiz yuborildi'**
  String get feedbackSubmittedMessage;

  /// Fikr-mulohaza ekranidagi rejim almashtirgichning 'baho qoldirish' segmenti
  ///
  /// In uz, this message translates to:
  /// **'Baho qoldirish'**
  String get feedbackModeRatingTab;

  /// Fikr-mulohaza ekranidagi rejim almashtirgichning 'savol/murojaat' segmenti
  ///
  /// In uz, this message translates to:
  /// **'Savol / Murojaat'**
  String get feedbackModeQuestionTab;

  /// Fikr-mulohaza ekrani 'savol/murojaat' rejimidagi sarlavha
  ///
  /// In uz, this message translates to:
  /// **'Savol yoki murojaat'**
  String get feedbackQuestionTitle;

  /// Fikr-mulohaza ekrani 'savol/murojaat' rejimidagi tavsif matni
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni yoki murojaatingizni yozing — superadmin ko\'rib chiqadi va zarur bo\'lsa aloqaga chiqadi.'**
  String get feedbackQuestionSubtitle;

  /// Fikr-mulohaza ekrani 'savol/murojaat' rejimidagi matn maydonining placeholder matni
  ///
  /// In uz, this message translates to:
  /// **'Savolingiz yoki murojaatingizni shu yerga yozing...'**
  String get feedbackQuestionMessageHint;

  /// Fikrlar ro'yxatida (super admin uchun) 'savol/murojaat' rejimida yuborilgan yozuvni ajratib ko'rsatuvchi kichik belgi matni
  ///
  /// In uz, this message translates to:
  /// **'Savol'**
  String get feedbackQuestionBadge;

  /// No description provided for @feedbackListTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi fikrlari'**
  String get feedbackListTitle;

  /// No description provided for @noFeedbackFound.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha fikrlar yo\'q'**
  String get noFeedbackFound;

  /// No description provided for @unknownUserLabel.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum foydalanuvchi'**
  String get unknownUserLabel;

  /// No description provided for @requestAuthorLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yuborgan'**
  String get requestAuthorLabel;

  /// No description provided for @quickNewRequestTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi murojaat yuborish'**
  String get quickNewRequestTitle;

  /// No description provided for @quickNewRequestSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Muammo bormi? Bir necha soniyada yuboring'**
  String get quickNewRequestSubtitle;

  /// No description provided for @mahalCardTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahal bilan suhbat'**
  String get mahalCardTitle;

  /// No description provided for @mahalCardSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Savollaringizga javob oling, murojaat yozib bering yoki mahalla haqida so\'rang'**
  String get mahalCardSubtitle;

  /// No description provided for @openLinkAction.
  ///
  /// In uz, this message translates to:
  /// **'Havolani ochish'**
  String get openLinkAction;

  /// No description provided for @linkOpenFailedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Havolani ochib bo\'lmadi'**
  String get linkOpenFailedMessage;

  /// No description provided for @bannerManagementTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bannerlar'**
  String get bannerManagementTitle;

  /// No description provided for @addBannerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi banner qo\'shish'**
  String get addBannerTitle;

  /// No description provided for @bannerTitleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha'**
  String get bannerTitleLabel;

  /// No description provided for @bannerDescriptionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif (ixtiyoriy)'**
  String get bannerDescriptionLabel;

  /// No description provided for @bannerLinkLabel.
  ///
  /// In uz, this message translates to:
  /// **'Havola (ixtiyoriy, https://...)'**
  String get bannerLinkLabel;

  /// No description provided for @bannerAttributionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Muallif/manba (ixtiyoriy)'**
  String get bannerAttributionLabel;

  /// No description provided for @bannerImageRequiredError.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, rasm tanlang'**
  String get bannerImageRequiredError;

  /// No description provided for @bannerTitleRequiredError.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, sarlavha kiriting'**
  String get bannerTitleRequiredError;

  /// No description provided for @noBannersFound.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bannerlar yo\'q'**
  String get noBannersFound;

  /// No description provided for @mahallaOnMapTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahallangiz xaritada'**
  String get mahallaOnMapTitle;

  /// No description provided for @developerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Rivojlantiruvchi'**
  String get developerTitle;

  /// No description provided for @developerSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahallam jamoasi'**
  String get developerSubtitle;

  /// No description provided for @termsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanish shartlari'**
  String get termsTitle;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik siyosati'**
  String get privacyPolicyTitle;

  /// No description provided for @comingSoonMessage.
  ///
  /// In uz, this message translates to:
  /// **'Bu funksiya tez orada qo\'shiladi'**
  String get comingSoonMessage;

  /// No description provided for @profileSaved.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar saqlandi'**
  String get profileSaved;

  /// No description provided for @saveButton.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get saveButton;

  /// No description provided for @faqTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'p beriladigan savollar'**
  String get faqTitle;

  /// No description provided for @contactUsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Biz bilan bog\'laning'**
  String get contactUsTitle;

  /// No description provided for @callUs.
  ///
  /// In uz, this message translates to:
  /// **'Telefon orqali'**
  String get callUs;

  /// No description provided for @telegramUs.
  ///
  /// In uz, this message translates to:
  /// **'Telegram orqali'**
  String get telegramUs;

  /// No description provided for @faqQ1.
  ///
  /// In uz, this message translates to:
  /// **'Mahallaga qanday qo\'shilaman?'**
  String get faqQ1;

  /// No description provided for @faqA1.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tgandan so\'ng, mahalla raisi yoki mas\'ul xodim tomonidan berilgan QR kodni skanerlash orqali mahallangizga bog\'lanasiz.'**
  String get faqA1;

  /// No description provided for @faqQ2.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat qanday yuboraman?'**
  String get faqQ2;

  /// No description provided for @faqA2.
  ///
  /// In uz, this message translates to:
  /// **'\"Murojaat\" bo\'limiga o\'ting va yangi murojaat yarating. Murojaatingiz holati \"Yangi\", \"Jarayonda\" yoki \"Yakunlandi\" sifatida ko\'rsatiladi.'**
  String get faqA2;

  /// No description provided for @faqQ3.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlarni qanday ko\'raman?'**
  String get faqQ3;

  /// No description provided for @faqA3.
  ///
  /// In uz, this message translates to:
  /// **'Bosh ekrandagi \"E\'lonlar\" bo\'limida mahallangizga oid barcha rasmiy e\'lonlar kategoriyalar bo\'yicha ko\'rsatiladi.'**
  String get faqA3;

  /// No description provided for @faqQ4.
  ///
  /// In uz, this message translates to:
  /// **'Parolimni unutdim, nima qilaman?'**
  String get faqQ4;

  /// No description provided for @faqA4.
  ///
  /// In uz, this message translates to:
  /// **'Kirish ekranidagi «Parolni unutdingizmi?» tugmasini bosing. Elektron pochtangizga tiklash havolasi yuboriladi. Xat kelmasa, «Spam» papkasini ham tekshiring.'**
  String get faqA4;

  /// No description provided for @faqQ5.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarim xavfsizmi?'**
  String get faqQ5;

  /// No description provided for @faqA5.
  ///
  /// In uz, this message translates to:
  /// **'Ha, barcha ma\'lumotlar faqat mahallangiz doirasida ko\'rinadi va himoyalangan serverda saqlanadi.'**
  String get faqA5;

  /// No description provided for @callFailedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroq qilib bo\'lmadi'**
  String get callFailedMessage;

  /// No description provided for @telegramFailedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Telegram ochib bo\'lmadi'**
  String get telegramFailedMessage;

  /// No description provided for @announcementsTitle.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlar'**
  String get announcementsTitle;

  /// No description provided for @eventsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirlar'**
  String get eventsTitle;

  /// No description provided for @feedTitle.
  ///
  /// In uz, this message translates to:
  /// **'Lenta'**
  String get feedTitle;

  /// No description provided for @postsFilterLabel.
  ///
  /// In uz, this message translates to:
  /// **'Postlar'**
  String get postsFilterLabel;

  /// No description provided for @noPostsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha postlar yo\'q'**
  String get noPostsYet;

  /// No description provided for @noPostsHint.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilar birinchi post qilganda, u shu yerda paydo bo\'ladi.'**
  String get noPostsHint;

  /// No description provided for @writePostHint.
  ///
  /// In uz, this message translates to:
  /// **'Nima gaplar?'**
  String get writePostHint;

  /// No description provided for @postCreatedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Post joylandi'**
  String get postCreatedMessage;

  /// No description provided for @writePostOrImageError.
  ///
  /// In uz, this message translates to:
  /// **'Matn yozing yoki rasm qo\'shing'**
  String get writePostOrImageError;

  /// No description provided for @postUpdatedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Post yangilandi'**
  String get postUpdatedMessage;

  /// No description provided for @editPostTitle.
  ///
  /// In uz, this message translates to:
  /// **'Postni tahrirlash'**
  String get editPostTitle;

  /// No description provided for @postingTooFastError.
  ///
  /// In uz, this message translates to:
  /// **'Juda tez-tez post joylayapsiz. Biroz kuting va qayta urinib ko\'ring.'**
  String get postingTooFastError;

  /// No description provided for @inappropriateContentError.
  ///
  /// In uz, this message translates to:
  /// **'Matnda nomaqbul so\'zlar bor. Iltimos, matnni tahrirlang.'**
  String get inappropriateContentError;

  /// No description provided for @reactionsSheetTitle.
  ///
  /// In uz, this message translates to:
  /// **'Reaksiyalar'**
  String get reactionsSheetTitle;

  /// No description provided for @addStoryLabel.
  ///
  /// In uz, this message translates to:
  /// **'Hikoya qo\'shish'**
  String get addStoryLabel;

  /// No description provided for @yourStoryLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sizning hikoyangiz'**
  String get yourStoryLabel;

  /// No description provided for @newButton.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get newButton;

  /// No description provided for @noAnnouncementsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha e\'lonlar yo\'q'**
  String get noAnnouncementsYet;

  /// No description provided for @noEventsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha tadbirlar yo\'q'**
  String get noEventsYet;

  /// No description provided for @announcementsLoadError.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonlarni yuklashda xatolik yuz berdi'**
  String get announcementsLoadError;

  /// No description provided for @participantsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} qatnashuvchi'**
  String participantsCount(int count);

  /// No description provided for @todayAt.
  ///
  /// In uz, this message translates to:
  /// **'Bugun, {time}'**
  String todayAt(String time);

  /// No description provided for @categoryKommunal.
  ///
  /// In uz, this message translates to:
  /// **'Kommunal'**
  String get categoryKommunal;

  /// No description provided for @categoryXavfsizlik.
  ///
  /// In uz, this message translates to:
  /// **'Xavfsizlik'**
  String get categoryXavfsizlik;

  /// No description provided for @categoryUmumiy.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy'**
  String get categoryUmumiy;

  /// No description provided for @newAnnouncementTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lon'**
  String get newAnnouncementTitle;

  /// No description provided for @editAnnouncementTitle.
  ///
  /// In uz, this message translates to:
  /// **'E\'lonni tahrirlash'**
  String get editAnnouncementTitle;

  /// No description provided for @pollsTitle.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnomalar'**
  String get pollsTitle;

  /// No description provided for @newPollTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi so\'rovnoma'**
  String get newPollTitle;

  /// No description provided for @pollQuestionHint.
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni yozing...'**
  String get pollQuestionHint;

  /// No description provided for @pollOptionHint.
  ///
  /// In uz, this message translates to:
  /// **'{number}-variant'**
  String pollOptionHint(int number);

  /// No description provided for @addOptionButton.
  ///
  /// In uz, this message translates to:
  /// **'Variant qo\'shish'**
  String get addOptionButton;

  /// No description provided for @fillPollFields.
  ///
  /// In uz, this message translates to:
  /// **'Savol va kamida 2 ta variant kiriting'**
  String get fillPollFields;

  /// No description provided for @pollPostedMessage.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnoma joylandi'**
  String get pollPostedMessage;

  /// No description provided for @noPollsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha so\'rovnomalar yo\'q'**
  String get noPollsYet;

  /// No description provided for @pollVotesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ovoz'**
  String pollVotesCount(int count);

  /// No description provided for @conversationsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xabarlar'**
  String get conversationsTitle;

  /// No description provided for @conversationsMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Xabarlar'**
  String get conversationsMenuItem;

  /// No description provided for @noConversationsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha suhbatlar yo\'q'**
  String get noConversationsYet;

  /// No description provided for @noMessagesYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xabarlar yo\'q. Birinchi bo\'lib yozing!'**
  String get noMessagesYet;

  /// No description provided for @messageHint.
  ///
  /// In uz, this message translates to:
  /// **'Xabar yozing...'**
  String get messageHint;

  /// No description provided for @sendMessageAction.
  ///
  /// In uz, this message translates to:
  /// **'Xabar yozish'**
  String get sendMessageAction;

  /// No description provided for @typingIndicator.
  ///
  /// In uz, this message translates to:
  /// **'yozmoqda...'**
  String get typingIndicator;

  /// No description provided for @attachImageAction.
  ///
  /// In uz, this message translates to:
  /// **'Rasm biriktirish'**
  String get attachImageAction;

  /// No description provided for @imageUploadFailed.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuborilmadi. Qayta urinib ko\'ring'**
  String get imageUploadFailed;

  /// No description provided for @yesterdayLabel.
  ///
  /// In uz, this message translates to:
  /// **'Kecha'**
  String get yesterdayLabel;

  /// No description provided for @switchMahallaTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla tanlash'**
  String get switchMahallaTitle;

  /// No description provided for @switchMahallaMenuItem.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla almashtirish (Super Admin)'**
  String get switchMahallaMenuItem;

  /// No description provided for @switchMahallaMenuItemActive.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa mahallani boshqaryapsiz'**
  String get switchMahallaMenuItemActive;

  /// No description provided for @exitMahallaModeAction.
  ///
  /// In uz, this message translates to:
  /// **'O\'z mahallamga qaytish'**
  String get exitMahallaModeAction;

  /// No description provided for @noMahallasFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahallalar topilmadi'**
  String get noMahallasFound;

  /// No description provided for @broadcastToAllMahallasLabel.
  ///
  /// In uz, this message translates to:
  /// **'Barcha mahallalarga yuborish (Super Admin)'**
  String get broadcastToAllMahallasLabel;

  /// No description provided for @servicesTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalliy xizmatlar'**
  String get servicesTitle;

  /// No description provided for @newServiceTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat qo\'shish'**
  String get newServiceTitle;

  /// No description provided for @editServiceTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xizmatni tahrirlash'**
  String get editServiceTitle;

  /// No description provided for @serviceCategoryLabel.
  ///
  /// In uz, this message translates to:
  /// **'Toifa'**
  String get serviceCategoryLabel;

  /// No description provided for @serviceNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ism yoki tashkilot nomi'**
  String get serviceNameLabel;

  /// No description provided for @serviceNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Aziz aka (santexnik)'**
  String get serviceNameHint;

  /// No description provided for @servicePhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get servicePhoneLabel;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif'**
  String get serviceDescriptionLabel;

  /// No description provided for @serviceDescriptionHint.
  ///
  /// In uz, this message translates to:
  /// **'Ish vaqti, narxi va h.k...'**
  String get serviceDescriptionHint;

  /// No description provided for @fillServiceFields.
  ///
  /// In uz, this message translates to:
  /// **'Ism va telefon raqamini kiriting'**
  String get fillServiceFields;

  /// No description provided for @servicePostedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat qo\'shildi'**
  String get servicePostedMessage;

  /// No description provided for @serviceUpdatedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Xizmat yangilandi'**
  String get serviceUpdatedMessage;

  /// No description provided for @noServicesYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha xizmatlar yo\'q'**
  String get noServicesYet;

  /// No description provided for @serviceCategorySantexnik.
  ///
  /// In uz, this message translates to:
  /// **'Santexnik'**
  String get serviceCategorySantexnik;

  /// No description provided for @serviceCategoryElektrik.
  ///
  /// In uz, this message translates to:
  /// **'Elektrik'**
  String get serviceCategoryElektrik;

  /// No description provided for @serviceCategoryDuradgor.
  ///
  /// In uz, this message translates to:
  /// **'Duradgor'**
  String get serviceCategoryDuradgor;

  /// No description provided for @serviceCategoryTozalash.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get serviceCategoryTozalash;

  /// No description provided for @serviceCategoryQurilish.
  ///
  /// In uz, this message translates to:
  /// **'Qurilish'**
  String get serviceCategoryQurilish;

  /// No description provided for @serviceCategoryBoshqa.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa'**
  String get serviceCategoryBoshqa;

  /// No description provided for @editPollTitle.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnomani tahrirlash'**
  String get editPollTitle;

  /// No description provided for @pollUpdatedMessage.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnoma yangilandi'**
  String get pollUpdatedMessage;

  /// No description provided for @changeVoteConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ovozni almashtirish'**
  String get changeVoteConfirmTitle;

  /// No description provided for @changeVoteConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'Siz allaqachon boshqa variantga ovoz bergansiz. Ovozingizni almashtirmoqchimisiz?'**
  String get changeVoteConfirmMessage;

  /// No description provided for @changeVoteConfirmButton.
  ///
  /// In uz, this message translates to:
  /// **'Ha, almashtirish'**
  String get changeVoteConfirmButton;

  /// No description provided for @pollAllowMultipleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Bir nechta variant tanlashga ruxsat berish'**
  String get pollAllowMultipleLabel;

  /// No description provided for @pollAnonymousLabel.
  ///
  /// In uz, this message translates to:
  /// **'Anonim so\'rovnoma'**
  String get pollAnonymousLabel;

  /// No description provided for @pollClosesAtLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yopilish sanasi (ixtiyoriy)'**
  String get pollClosesAtLabel;

  /// No description provided for @pollClosesAtClearButton.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get pollClosesAtClearButton;

  /// No description provided for @pollClosedBadge.
  ///
  /// In uz, this message translates to:
  /// **'Yopilgan'**
  String get pollClosedBadge;

  /// No description provided for @pollVoteClosedError.
  ///
  /// In uz, this message translates to:
  /// **'Bu so\'rovnoma yopilgan, ovoz berish mumkin emas'**
  String get pollVoteClosedError;

  /// No description provided for @pollSubmitVoteButton.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz berish'**
  String get pollSubmitVoteButton;

  /// No description provided for @categoryServices.
  ///
  /// In uz, this message translates to:
  /// **'Xizmatlar'**
  String get categoryServices;

  /// No description provided for @categoryPolls.
  ///
  /// In uz, this message translates to:
  /// **'So\'rovnomalar'**
  String get categoryPolls;

  /// No description provided for @categoryLabel.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya'**
  String get categoryLabel;

  /// No description provided for @titleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha'**
  String get titleLabel;

  /// No description provided for @titleHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Ertaga suv o\'chirilishi haqida'**
  String get titleHint;

  /// No description provided for @bodyLabel.
  ///
  /// In uz, this message translates to:
  /// **'Matn'**
  String get bodyLabel;

  /// No description provided for @bodyHint.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon matnini batafsil yozing...'**
  String get bodyHint;

  /// No description provided for @photoLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rasm'**
  String get photoLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In uz, this message translates to:
  /// **'(ixtiyoriy)'**
  String get optionalLabel;

  /// No description provided for @postButton.
  ///
  /// In uz, this message translates to:
  /// **'Joylash'**
  String get postButton;

  /// No description provided for @fillTitleAndBody.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha va matnni to\'ldiring'**
  String get fillTitleAndBody;

  /// No description provided for @announcementPosted.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon muvaffaqiyatli joylandi'**
  String get announcementPosted;

  /// No description provided for @announcementUpdated.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon yangilandi'**
  String get announcementUpdated;

  /// No description provided for @requestsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlar'**
  String get requestsTitle;

  /// No description provided for @mustVerifyMahallaFirst.
  ///
  /// In uz, this message translates to:
  /// **'Avval mahallangizni tasdiqlashingiz kerak'**
  String get mustVerifyMahallaFirst;

  /// No description provided for @managementPanelBanner.
  ///
  /// In uz, this message translates to:
  /// **'Boshqaruv paneli — barcha murojaatlar'**
  String get managementPanelBanner;

  /// No description provided for @requestsLoadError.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlarni yuklashda xatolik yuz berdi'**
  String get requestsLoadError;

  /// No description provided for @joinedCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} kishi qo\'shildi'**
  String joinedCount(int count);

  /// No description provided for @noRequestsWithStatus.
  ///
  /// In uz, this message translates to:
  /// **'{status} murojaatlar yo\'q'**
  String noRequestsWithStatus(String status);

  /// No description provided for @filterAll.
  ///
  /// In uz, this message translates to:
  /// **'Hammasi'**
  String get filterAll;

  /// No description provided for @noRequestsAtAll.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha murojaatlar yo\'q'**
  String get noRequestsAtAll;

  /// No description provided for @statusYangi.
  ///
  /// In uz, this message translates to:
  /// **'Yangi'**
  String get statusYangi;

  /// No description provided for @statusJarayonda.
  ///
  /// In uz, this message translates to:
  /// **'Jarayonda'**
  String get statusJarayonda;

  /// No description provided for @statusYakunlandi.
  ///
  /// In uz, this message translates to:
  /// **'Yakunlandi'**
  String get statusYakunlandi;

  /// No description provided for @typeMaxfiy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiy'**
  String get typeMaxfiy;

  /// No description provided for @typeOmmaviy.
  ///
  /// In uz, this message translates to:
  /// **'Ommaviy'**
  String get typeOmmaviy;

  /// No description provided for @priorityPast.
  ///
  /// In uz, this message translates to:
  /// **'Past'**
  String get priorityPast;

  /// No description provided for @priorityOrtacha.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha'**
  String get priorityOrtacha;

  /// No description provided for @priorityYuqori.
  ///
  /// In uz, this message translates to:
  /// **'Yuqori'**
  String get priorityYuqori;

  /// No description provided for @managementPanelTitle.
  ///
  /// In uz, this message translates to:
  /// **'Boshqaruv paneli'**
  String get managementPanelTitle;

  /// No description provided for @changeStatusTitle.
  ///
  /// In uz, this message translates to:
  /// **'Holatni o\'zgartirish'**
  String get changeStatusTitle;

  /// No description provided for @statusChangedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Holat \"{status}\" ga o\'zgartirildi'**
  String statusChangedMessage(String status);

  /// No description provided for @statusChangeError.
  ///
  /// In uz, this message translates to:
  /// **'Holatni o\'zgartirishda xatolik yuz berdi'**
  String get statusChangeError;

  /// No description provided for @allFilter.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get allFilter;

  /// No description provided for @noRequestsFound.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatlar topilmadi'**
  String get noRequestsFound;

  /// No description provided for @tapToChangeStatus.
  ///
  /// In uz, this message translates to:
  /// **'Holatni o\'zgartirish uchun bosing'**
  String get tapToChangeStatus;

  /// No description provided for @stepType.
  ///
  /// In uz, this message translates to:
  /// **'Turi'**
  String get stepType;

  /// No description provided for @stepDetails.
  ///
  /// In uz, this message translates to:
  /// **'Tafsilotlar'**
  String get stepDetails;

  /// No description provided for @stepLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get stepLocation;

  /// No description provided for @stepReview.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rib chiqish'**
  String get stepReview;

  /// No description provided for @stepDone.
  ///
  /// In uz, this message translates to:
  /// **'Tayyor'**
  String get stepDone;

  /// No description provided for @newRequestTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi murojaat'**
  String get newRequestTitle;

  /// No description provided for @fillTitleAndDescription.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha va tavsifni to\'ldiring'**
  String get fillTitleAndDescription;

  /// No description provided for @sendButton.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get sendButton;

  /// No description provided for @chooseRequestType.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat turini tanlang'**
  String get chooseRequestType;

  /// No description provided for @requestTypeExplain.
  ///
  /// In uz, this message translates to:
  /// **'Bu murojaatingizni kim ko\'ra olishini belgilaydi'**
  String get requestTypeExplain;

  /// No description provided for @typeMaxfiyDescription.
  ///
  /// In uz, this message translates to:
  /// **'Faqat siz va mahalla raisi ko\'radi'**
  String get typeMaxfiyDescription;

  /// No description provided for @typeOmmaviyDescription.
  ///
  /// In uz, this message translates to:
  /// **'Mahalladagi hamma ko\'radi va qo\'shilishi mumkin'**
  String get typeOmmaviyDescription;

  /// No description provided for @titleFieldLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha'**
  String get titleFieldLabel;

  /// No description provided for @titleFieldHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Ko\'cha yoritilishi ishlamayapti'**
  String get titleFieldHint;

  /// No description provided for @descriptionLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In uz, this message translates to:
  /// **'Muammoni batafsil tasvirlab bering...'**
  String get descriptionHint;

  /// No description provided for @attachPhotoLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rasm biriktirish'**
  String get attachPhotoLabel;

  /// No description provided for @priorityLevelLabel.
  ///
  /// In uz, this message translates to:
  /// **'Muhimlik darajasi'**
  String get priorityLevelLabel;

  /// No description provided for @reviewDataTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni tekshiring'**
  String get reviewDataTitle;

  /// No description provided for @reviewType.
  ///
  /// In uz, this message translates to:
  /// **'Turi'**
  String get reviewType;

  /// No description provided for @reviewPriority.
  ///
  /// In uz, this message translates to:
  /// **'Muhimlik'**
  String get reviewPriority;

  /// No description provided for @reviewLocation.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get reviewLocation;

  /// No description provided for @reviewLocationSet.
  ///
  /// In uz, this message translates to:
  /// **'Belgilangan'**
  String get reviewLocationSet;

  /// No description provided for @reviewLocationNotSet.
  ///
  /// In uz, this message translates to:
  /// **'Belgilanmagan'**
  String get reviewLocationNotSet;

  /// No description provided for @reviewPhotos.
  ///
  /// In uz, this message translates to:
  /// **'Rasmlar ({count})'**
  String reviewPhotos(int count);

  /// No description provided for @requestSentTitle.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat yuborildi!'**
  String get requestSentTitle;

  /// No description provided for @requestSentMessage.
  ///
  /// In uz, this message translates to:
  /// **'Murojaatingiz qabul qilindi va ko\'rib chiqilmoqda'**
  String get requestSentMessage;

  /// No description provided for @backToListButton.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatga qaytish'**
  String get backToListButton;

  /// No description provided for @qrScanInstruction.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla eshigidagi QR kodni ramka ichiga joylashtiring'**
  String get qrScanInstruction;

  /// No description provided for @checkingStatus.
  ///
  /// In uz, this message translates to:
  /// **'Tekshirilmoqda...'**
  String get checkingStatus;

  /// No description provided for @scanningStatus.
  ///
  /// In uz, this message translates to:
  /// **'Skanerlanmoqda...'**
  String get scanningStatus;

  /// No description provided for @enterCodeManually.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qo\'lda kiritish'**
  String get enterCodeManually;

  /// No description provided for @enterMahallaCodeTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla kodini kiriting'**
  String get enterMahallaCodeTitle;

  /// No description provided for @mahallaCodeHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Y234-5678'**
  String get mahallaCodeHint;

  /// No description provided for @confirmButton.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get confirmButton;

  /// No description provided for @qrGenericError.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi, qayta urinib ko\'ring'**
  String get qrGenericError;

  /// No description provided for @confirmError.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlashda xatolik yuz berdi, qayta urinib ko\'ring'**
  String get confirmError;

  /// No description provided for @mahallaFoundLabel.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla topildi'**
  String get mahallaFoundLabel;

  /// No description provided for @rescanButton.
  ///
  /// In uz, this message translates to:
  /// **'Qayta skanerlash'**
  String get rescanButton;

  /// No description provided for @changePhotoLabel.
  ///
  /// In uz, this message translates to:
  /// **'Rasmni o\'zgartirish'**
  String get changePhotoLabel;

  /// No description provided for @birthDateLabel.
  ///
  /// In uz, this message translates to:
  /// **'Tug\'ilgan sana'**
  String get birthDateLabel;

  /// No description provided for @addressLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get addressLabel;

  /// No description provided for @streetLabel.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'cha'**
  String get streetLabel;

  /// No description provided for @streetHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Bog\'bon ko\'chasi'**
  String get streetHint;

  /// No description provided for @houseNumberLabel.
  ///
  /// In uz, this message translates to:
  /// **'Uy raqami'**
  String get houseNumberLabel;

  /// No description provided for @houseNumberHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: 15'**
  String get houseNumberHint;

  /// No description provided for @genderLabel.
  ///
  /// In uz, this message translates to:
  /// **'Jinsi'**
  String get genderLabel;

  /// No description provided for @genderMale.
  ///
  /// In uz, this message translates to:
  /// **'Erkak'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In uz, this message translates to:
  /// **'Ayol'**
  String get genderFemale;

  /// No description provided for @notSpecified.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rsatilmagan'**
  String get notSpecified;

  /// No description provided for @selectDate.
  ///
  /// In uz, this message translates to:
  /// **'Sanani tanlang'**
  String get selectDate;

  /// No description provided for @photoUploadError.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuklashda xatolik yuz berdi'**
  String get photoUploadError;

  /// No description provided for @otpTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash kodi'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{phone} raqamiga yuborilgan 6 xonali kodni kiriting'**
  String otpSubtitle(String phone);

  /// No description provided for @otpInvalidCode.
  ///
  /// In uz, this message translates to:
  /// **'Kod noto\'g\'ri, qaytadan kiriting'**
  String get otpInvalidCode;

  /// No description provided for @otpResendCode.
  ///
  /// In uz, this message translates to:
  /// **'Kodni qayta yuborish'**
  String get otpResendCode;

  /// No description provided for @otpResendCooldown.
  ///
  /// In uz, this message translates to:
  /// **'Qayta yuborish ({seconds}s)'**
  String otpResendCooldown(int seconds);

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tiklash'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tgan telefon raqamingizni kiriting, unga tasdiqlash kodi yuboramiz'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendCodeButton.
  ///
  /// In uz, this message translates to:
  /// **'Kod yuborish'**
  String get sendCodeButton;

  /// No description provided for @newPasswordLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol'**
  String get newPasswordLabel;

  /// No description provided for @newPasswordTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol o\'rnating'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Hisobingiz uchun yangi parol o\'ylab toping'**
  String get newPasswordSubtitle;

  /// No description provided for @savePasswordButton.
  ///
  /// In uz, this message translates to:
  /// **'Parolni saqlash'**
  String get savePasswordButton;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Parolingiz muvaffaqiyatli yangilandi'**
  String get passwordResetSuccess;

  /// No description provided for @newEventTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yangi tadbir'**
  String get newEventTitle;

  /// No description provided for @editEventTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tadbirni tahrirlash'**
  String get editEventTitle;

  /// No description provided for @eventTitleHint.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Mahalla yig\'ilishi'**
  String get eventTitleHint;

  /// No description provided for @eventDescriptionHint.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir haqida qo\'shimcha ma\'lumot (ixtiyoriy)...'**
  String get eventDescriptionHint;

  /// No description provided for @pinAnnouncementAction.
  ///
  /// In uz, this message translates to:
  /// **'Yuqoriga mahkamlash'**
  String get pinAnnouncementAction;

  /// No description provided for @unpinAnnouncementAction.
  ///
  /// In uz, this message translates to:
  /// **'Mahkamlashni yechish'**
  String get unpinAnnouncementAction;

  /// No description provided for @cannotMessageBlockedUser.
  ///
  /// In uz, this message translates to:
  /// **'Bu foydalanuvchiga xabar yubora olmaysiz.'**
  String get cannotMessageBlockedUser;

  /// No description provided for @rsvpToggleLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qatnashish belgisi'**
  String get rsvpToggleLabel;

  /// No description provided for @rsvpToggleHint.
  ///
  /// In uz, this message translates to:
  /// **'Yoqilsa, foydalanuvchilar \"Boraman\" deb belgilay oladi.'**
  String get rsvpToggleHint;

  /// No description provided for @rsvpJoinAction.
  ///
  /// In uz, this message translates to:
  /// **'Boraman'**
  String get rsvpJoinAction;

  /// No description provided for @rsvpJoinedLabel.
  ///
  /// In uz, this message translates to:
  /// **'Boraman'**
  String get rsvpJoinedLabel;

  /// No description provided for @dateLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get dateLabel;

  /// No description provided for @selectTime.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtni tanlang'**
  String get selectTime;

  /// No description provided for @locationLabel.
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get locationLabel;

  /// No description provided for @locationHint.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir o\'tkaziladigan joy'**
  String get locationHint;

  /// No description provided for @fillEventFields.
  ///
  /// In uz, this message translates to:
  /// **'Sarlavha va sanani kiriting'**
  String get fillEventFields;

  /// No description provided for @eventPosted.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir joylandi'**
  String get eventPosted;

  /// No description provided for @eventUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir yangilandi'**
  String get eventUpdated;

  /// No description provided for @neighborsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilar'**
  String get neighborsTitle;

  /// No description provided for @mahalladoshlar.
  ///
  /// In uz, this message translates to:
  /// **'Mahalladoshlar'**
  String get mahalladoshlar;

  /// No description provided for @yozishmalarTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yozishmalar'**
  String get yozishmalarTitle;

  /// No description provided for @noNeighborsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha qo\'shnilar yo\'q'**
  String get noNeighborsYet;

  /// No description provided for @onlineNow.
  ///
  /// In uz, this message translates to:
  /// **'Onlayn'**
  String get onlineNow;

  /// No description provided for @lastSeenUnknown.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi faollik noma\'lum'**
  String get lastSeenUnknown;

  /// No description provided for @lastSeenJustNow.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgina faol edi'**
  String get lastSeenJustNow;

  /// No description provided for @lastSeenMinutesAgo.
  ///
  /// In uz, this message translates to:
  /// **'{minutes} daqiqa oldin'**
  String lastSeenMinutesAgo(int minutes);

  /// No description provided for @lastSeenHoursAgo.
  ///
  /// In uz, this message translates to:
  /// **'{hours} soat oldin'**
  String lastSeenHoursAgo(int hours);

  /// No description provided for @lastSeenDaysAgo.
  ///
  /// In uz, this message translates to:
  /// **'{days} kun oldin'**
  String lastSeenDaysAgo(int days);

  /// No description provided for @sectionPrivacy.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik'**
  String get sectionPrivacy;

  /// No description provided for @showPhoneToNeighborsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Telefonni qo\'shnilarga ko\'rsatish'**
  String get showPhoneToNeighborsTitle;

  /// No description provided for @showPhoneToNeighborsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yoqilsa, Qo\'shnilar ro\'yxatida raqamingiz ko\'rinadi'**
  String get showPhoneToNeighborsSubtitle;

  /// No description provided for @privacySecurityTitle.
  ///
  /// In uz, this message translates to:
  /// **'Maxfiylik va xavfsizlik'**
  String get privacySecurityTitle;

  /// No description provided for @privacySecuritySubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rinish, bloklangan foydalanuvchilar, parol'**
  String get privacySecuritySubtitle;

  /// No description provided for @sectionVisibility.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'rinish'**
  String get sectionVisibility;

  /// No description provided for @showLastSeenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi faollikni ko\'rsatish'**
  String get showLastSeenTitle;

  /// No description provided for @showLastSeenSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Yoqilsa, qo\'shnilar online holatingizni ko\'radi'**
  String get showLastSeenSubtitle;

  /// No description provided for @sectionBlockedUsers.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan foydalanuvchilar'**
  String get sectionBlockedUsers;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan foydalanuvchilar'**
  String get blockedUsersTitle;

  /// No description provided for @noBlockedUsers.
  ///
  /// In uz, this message translates to:
  /// **'Bloklangan foydalanuvchilar yo\'q'**
  String get noBlockedUsers;

  /// No description provided for @blockedUsersCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta bloklangan'**
  String blockedUsersCount(int count);

  /// No description provided for @blockUserAction.
  ///
  /// In uz, this message translates to:
  /// **'Bloklash'**
  String get blockUserAction;

  /// No description provided for @blockUserConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchini bloklash'**
  String get blockUserConfirmTitle;

  /// No description provided for @blockUserConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'{name} sizga xabar yoza olmaydi va ro\'yxatingizda ko\'rinmaydi. Rozimisiz?'**
  String blockUserConfirmMessage(String name);

  /// No description provided for @userBlockedMessage.
  ///
  /// In uz, this message translates to:
  /// **'{name} bloklandi'**
  String userBlockedMessage(String name);

  /// No description provided for @unblockAction.
  ///
  /// In uz, this message translates to:
  /// **'Blokdan chiqarish'**
  String get unblockAction;

  /// No description provided for @userUnblockedMessage.
  ///
  /// In uz, this message translates to:
  /// **'{name} blokdan chiqarildi'**
  String userUnblockedMessage(String name);

  /// No description provided for @phoneHiddenByUser.
  ///
  /// In uz, this message translates to:
  /// **'Bu foydalanuvchi telefonini yashirgan'**
  String get phoneHiddenByUser;

  /// No description provided for @markAllAsReadAction.
  ///
  /// In uz, this message translates to:
  /// **'Barchasini o\'qilgan deb belgilash'**
  String get markAllAsReadAction;

  /// No description provided for @noNotificationsYet.
  ///
  /// In uz, this message translates to:
  /// **'Hozircha bildirishnomalar yo\'q'**
  String get noNotificationsYet;

  /// No description provided for @searchPromptText.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon, tadbir yoki murojaat qidiring'**
  String get searchPromptText;

  /// No description provided for @searchNoResults.
  ///
  /// In uz, this message translates to:
  /// **'Hech narsa topilmadi'**
  String get searchNoResults;

  /// No description provided for @requestDetailTitle.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat tafsilotlari'**
  String get requestDetailTitle;

  /// No description provided for @requestNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Murojaat topilmadi'**
  String get requestNotFound;

  /// No description provided for @announcementDetailTitle.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon tafsilotlari'**
  String get announcementDetailTitle;

  /// No description provided for @announcementNotFound.
  ///
  /// In uz, this message translates to:
  /// **'E\'lon topilmadi'**
  String get announcementNotFound;

  /// No description provided for @eventDetailTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir tafsilotlari'**
  String get eventDetailTitle;

  /// No description provided for @eventNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Tadbir topilmadi'**
  String get eventNotFound;

  /// No description provided for @shareAction.
  ///
  /// In uz, this message translates to:
  /// **'Ulashish'**
  String get shareAction;

  /// No description provided for @joinRequestAction.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shilish'**
  String get joinRequestAction;

  /// No description provided for @leaveRequestAction.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get leaveRequestAction;

  /// No description provided for @mahallaStaffTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla xodimlari'**
  String get mahallaStaffTitle;

  /// No description provided for @mahallaMapTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mahalla xaritasi'**
  String get mahallaMapTitle;

  /// No description provided for @locationStepTitle.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni belgilang'**
  String get locationStepTitle;

  /// No description provided for @locationStepSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Xaritani bosib nuqta qo\'ying yoki joriy joylashuvingizni ishlating (ixtiyoriy)'**
  String get locationStepSubtitle;

  /// No description provided for @locationPermissionError.
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvga ruxsat berilmadi'**
  String get locationPermissionError;

  /// No description provided for @clearLocationAction.
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get clearLocationAction;

  /// No description provided for @boundaryEditorTitle.
  ///
  /// In uz, this message translates to:
  /// **'Chegarani belgilash'**
  String get boundaryEditorTitle;

  /// No description provided for @boundaryEditorHint.
  ///
  /// In uz, this message translates to:
  /// **'Xaritani bosib mahalla chegarasi bo\'ylab nuqtalar qo\'ying (kamida 3 ta)'**
  String get boundaryEditorHint;

  /// No description provided for @boundaryMinPointsError.
  ///
  /// In uz, this message translates to:
  /// **'Kamida 3 ta nuqta belgilang'**
  String get boundaryMinPointsError;

  /// No description provided for @boundarySavedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Chegara saqlandi'**
  String get boundarySavedMessage;

  /// No description provided for @saveBoundaryAction.
  ///
  /// In uz, this message translates to:
  /// **'Chegarani saqlash'**
  String get saveBoundaryAction;

  /// No description provided for @editBoundaryAction.
  ///
  /// In uz, this message translates to:
  /// **'Chegarani tahrirlash'**
  String get editBoundaryAction;

  /// No description provided for @mapLayerSatellite.
  ///
  /// In uz, this message translates to:
  /// **'Sputnik ko\'rinishi'**
  String get mapLayerSatellite;

  /// No description provided for @mapLayerStreets.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'cha xaritasi'**
  String get mapLayerStreets;

  /// No description provided for @deleteItemConfirmTitle.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get deleteItemConfirmTitle;

  /// No description provided for @deleteItemConfirmMessage.
  ///
  /// In uz, this message translates to:
  /// **'\"{title}\" butunlay o\'chiriladi. Bu amalni ortga qaytarib bo\'lmaydi.'**
  String deleteItemConfirmMessage(String title);

  /// No description provided for @itemDeletedMessage.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirildi'**
  String get itemDeletedMessage;

  /// No description provided for @searchNeighborHint.
  ///
  /// In uz, this message translates to:
  /// **'Ism bo\'yicha qidirish...'**
  String get searchNeighborHint;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In uz, this message translates to:
  /// **'Joriy parol'**
  String get currentPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlang'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordMismatchError.
  ///
  /// In uz, this message translates to:
  /// **'Parollar mos kelmadi'**
  String get passwordMismatchError;

  /// No description provided for @newPhoneLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yangi telefon raqam'**
  String get newPhoneLabel;

  /// No description provided for @phoneChangedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam muvaffaqiyatli o\'zgartirildi'**
  String get phoneChangedMessage;

  /// No description provided for @termsBody.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu ilovadan foydalanish orqali siz quyidagi shartlarga rozilik bildirasiz:\n\n1. Ilova mahalla aholisi va xodimlari o\'rtasida muloqotni osonlashtirish uchun mo\'ljallangan.\n2. Foydalanuvchi o\'z profilida to\'g\'ri va haqiqiy ma\'lumot kiritishi shart.\n3. Boshqa foydalanuvchilarga nisbatan haqoratli, noqonuniy yoki yolg\'on ma\'lumot tarqatish taqiqlanadi.\n4. Mahalla ma\'muriyati (xodim/rais) tomonidan joylashtirilgan e\'lon va tadbirlar rasmiy xarakterga ega bo\'lishi mumkin.\n5. Ilova ma\'muriyati qoidabuzarlik aniqlangan hisoblarni bloklash yoki o\'chirish huquqini o\'zida saqlab qoladi.'**
  String get termsBody;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In uz, this message translates to:
  /// **'Sizning ma\'lumotlaringiz qanday ishlatiladi:\n\n1. Ism, familiya, telefon raqam va mahalla ma\'lumotlari faqat mahalla ichidagi muloqot uchun ishlatiladi.\n2. Telefon raqamingiz sozlamalarda ruxsat bermaguningizcha boshqa aholiga ko\'rinmaydi.\n3. Oxirgi faollik vaqti sozlamalarda o\'chirilishi mumkin.\n4. Ma\'lumotlaringiz uchinchi tomonlarga sotilmaydi yoki ularga uzatilmaydi.\n5. Hisobingizni o\'chirishni so\'rasangiz, ma\'lumotlaringiz Firestore bazasidan olib tashlanadi.'**
  String get privacyPolicyBody;

  /// Hisobni o'chirish so'rovi natijasi
  ///
  /// In uz, this message translates to:
  /// **'So\'rovingiz yuborildi. Administrator tez orada hisobingizni o\'chiradi.'**
  String get deleteAccountRequested;

  /// Hisobni o'chirish so'rovi natijasi
  ///
  /// In uz, this message translates to:
  /// **'Sizning o\'chirish so\'rovingiz allaqachon ko\'rib chiqilmoqda.'**
  String get deleteAccountAlreadyPending;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retryButton;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ruxsat kerak'**
  String get cameraIntroTitle;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Mahallangizga qo\'shilish uchun rais yoki xodim bergan QR kodni skanerlash kerak. Kamera faqat shu maqsadda ishlatiladi — hech qanday rasm saqlanmaydi va yuborilmaydi.'**
  String get cameraIntroBody;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Kamerani ochish'**
  String get cameraIntroButton;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Kameraga ruxsat berilmagan. Ruxsatni telefon sozlamalarida (Ilovalar → Mening Mahallam → Ruxsatlar → Kamera) yoqishingiz mumkin. Yoki mahalla kodini qo\'lda kiriting.'**
  String get cameraErrorPermission;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Bu qurilmada QR skanerlash qo\'llab-quvvatlanmaydi. Mahalla kodini qo\'lda kiriting.'**
  String get cameraErrorUnsupported;

  /// QR skaner / kamera
  ///
  /// In uz, this message translates to:
  /// **'Kamera ochilmadi. Boshqa ilova kamerani ishlatayotgan bo\'lishi mumkin — uni yoping va qayta urinib ko\'ring.'**
  String get cameraErrorGeneric;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Mahalla raisi yoki xodimlari e\'lon joylaganda, u shu yerda birinchi bo\'lib paydo bo\'ladi.'**
  String get noAnnouncementsHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Ko\'cha yoritgichi, tozalik, suv yoki boshqa masala bo\'yicha murojaat yuboring — mahalla xodimlari javob beradi.'**
  String get noRequestsHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Mahalladoshlaringiz ilovaga qo\'shilgan sari ular shu yerda ko\'rinadi. Qo\'shnilaringizni taklif qiling!'**
  String get noNeighborsHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Mahalla so\'rovnomalari shu yerda chiqadi — ovoz berib, qaror qabul qilishda ishtirok etasiz.'**
  String get noPollsHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Mahalladagi ustalar, do\'konlar va xizmatlar shu yerda to\'planadi.'**
  String get noServicesHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shnilar bo\'limidan biror kishini tanlab, unga to\'g\'ridan-to\'g\'ri yozishingiz mumkin.'**
  String get noConversationsHint;

  /// Bo'sh holat uchun tushuntirish
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lon, tadbir yoki murojaatingizga javob kelganda shu yerda xabar beramiz.'**
  String get noNotificationsHint;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'so\'m'**
  String get currencySom;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'To\'lov rekvizitlari'**
  String get premiumConfigTitle;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Bu yerda o\'zgartirilgan qiymatlar barcha foydalanuvchilarga darhol ko\'rinadi — ilovani yangilash shart emas.'**
  String get premiumConfigHint;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Rekvizitlar saqlandi'**
  String get premiumConfigSaved;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Karta raqami'**
  String get premiumCardNumberLabel;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Karta raqami 16 ta raqamdan iborat bo\'lishi kerak'**
  String get premiumCardNumberInvalid;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Karta egasining ismi'**
  String get premiumCardHolderLabel;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Karta egasining ismini kiriting'**
  String get premiumCardHolderInvalid;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Oylik narx'**
  String get premiumPriceLabel;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri narx kiriting'**
  String get premiumPriceInvalid;

  /// Premium to'lov rekvizitlari (super admin)
  ///
  /// In uz, this message translates to:
  /// **'Telegram foydalanuvchi nomi'**
  String get premiumTelegramLabel;

  /// Premium
  ///
  /// In uz, this message translates to:
  /// **'Muddatni tanlang'**
  String get premiumChoosePlan;

  /// No description provided for @premiumPlanMonths.
  ///
  /// In uz, this message translates to:
  /// **'{count} oy'**
  String premiumPlanMonths(int count);

  /// No description provided for @premiumPriceValue.
  ///
  /// In uz, this message translates to:
  /// **'{amount} so\'m'**
  String premiumPriceValue(String amount);

  /// Premium
  ///
  /// In uz, this message translates to:
  /// **'Xizmat reklamasini joylashtirish 50% arzon'**
  String get premiumBenefitAdDiscount;

  /// Premium
  ///
  /// In uz, this message translates to:
  /// **'Ustuvor qo\'llab-quvvatlash — murojaatingiz birinchi ko\'riladi'**
  String get premiumBenefitSupport;

  /// Premium
  ///
  /// In uz, this message translates to:
  /// **'Profil suratida oltin premium halqa'**
  String get premiumBenefitAvatar;

  /// Premium
  ///
  /// In uz, this message translates to:
  /// **'Yangi imkoniyatlar birinchi bo\'lib sizga ochiladi'**
  String get premiumBenefitEarlyAccess;

  /// No description provided for @premiumPerMonthAmount.
  ///
  /// In uz, this message translates to:
  /// **'oyiga {amount} so\'m'**
  String premiumPerMonthAmount(String amount);

  /// Xizmat reklamasi
  ///
  /// In uz, this message translates to:
  /// **'Xizmatingizni shu yerda reklama qiling'**
  String get advertiseTitle;

  /// No description provided for @advertisePrice.
  ///
  /// In uz, this message translates to:
  /// **'Haftasiga atigi {amount} so\'m'**
  String advertisePrice(String amount);

  /// No description provided for @advertisePremiumDiscount.
  ///
  /// In uz, this message translates to:
  /// **'Premium chegirmangiz — oddiy narx {amount} so\'m'**
  String advertisePremiumDiscount(String amount);

  /// Xizmat reklamasi
  ///
  /// In uz, this message translates to:
  /// **'Reklama joylashtirish uchun mahalla raisi yoki ilova administratori bilan bog\'laning.'**
  String get advertiseHowTo;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Fayl juda katta. 5 MB dan kichik rasm tanlang'**
  String get photoTooLarge;

  /// No description provided for @avatarSourceImage.
  ///
  /// In uz, this message translates to:
  /// **'Rasm'**
  String get avatarSourceImage;

  /// No description provided for @avatarSourceVideo.
  ///
  /// In uz, this message translates to:
  /// **'Video'**
  String get avatarSourceVideo;

  /// No description provided for @avatarSourceVideoHint.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi 4 soniyasi jonli GIF avatarga aylantiriladi'**
  String get avatarSourceVideoHint;

  /// No description provided for @videoToGifError.
  ///
  /// In uz, this message translates to:
  /// **'Videoni GIF\'ga aylantirib bo\'lmadi. Boshqa video bilan urinib ko\'ring'**
  String get videoToGifError;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Jonli (GIF) profil surati'**
  String get premiumBenefitAnimatedAvatar;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Premiumni qo\'lda berish'**
  String get premiumGrantTitle;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'O\'zimga berish'**
  String get premiumGrantSelfAction;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get premiumGrantPhoneLabel;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Shu raqamga berish'**
  String get premiumGrantAction;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Shu raqamdan bekor qilish'**
  String get premiumRevokeAction;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Premiumni bekor qilish'**
  String get premiumRevokeConfirmTitle;

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'{name} uchun premium obunani muddatidan oldin bekor qilmoqchimisiz?'**
  String premiumRevokeConfirmMessage(String name);

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'{name} uchun premium bekor qilindi'**
  String premiumRevokedFrom(String name);

  /// No description provided for @premiumGrantedSelf.
  ///
  /// In uz, this message translates to:
  /// **'Sizga {months} oylik premium berildi'**
  String premiumGrantedSelf(int months);

  /// No description provided for @premiumGrantedTo.
  ///
  /// In uz, this message translates to:
  /// **'{name} — {months} oylik premium berildi'**
  String premiumGrantedTo(String name, int months);

  /// Premium / profil
  ///
  /// In uz, this message translates to:
  /// **'Bu raqam bilan foydalanuvchi topilmadi'**
  String get premiumGrantUserNotFound;

  /// No description provided for @premiumUntilShort.
  ///
  /// In uz, this message translates to:
  /// **'{date} gacha'**
  String premiumUntilShort(String date);

  /// Profil formasi bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Shaxsiy ma\'lumotlar'**
  String get personalInfoSection;

  /// Profil formasi bo'limi
  ///
  /// In uz, this message translates to:
  /// **'Manzil'**
  String get addressSection;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Mahalla markazi'**
  String get mahallaCenterTitle;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Xaritaga bosib markazni belgilang yoki tepadagi nishon tugmasi orqali koordinatani kiriting.'**
  String get mahallaCenterHint;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Google Maps\'dan nusxalagan koordinatani qo\'ying (kenglik, uzunlik).'**
  String get mahallaCenterCoordsHint;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Mahalla markazi saqlandi'**
  String get mahallaCenterSaved;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Chegara'**
  String get boundaryModeLabel;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Markaz'**
  String get centerModeLabel;

  /// Mahalla markazi / chegara muharriri
  ///
  /// In uz, this message translates to:
  /// **'Markazni saqlash'**
  String get saveCenterAction;

  /// Sozlamalar: ko'rinish / matn kattaligi
  ///
  /// In uz, this message translates to:
  /// **'Telefon sozlamasiga ergashadi'**
  String get appearanceSystemHint;

  /// Sozlamalar: ko'rinish / matn kattaligi
  ///
  /// In uz, this message translates to:
  /// **'Mahalla yig\'ilishi'**
  String get textSizePreviewTitle;

  /// Sozlamalar: ko'rinish / matn kattaligi
  ///
  /// In uz, this message translates to:
  /// **'Asosiy matn shunday ko\'rinadi. Sizga qulay o\'lchamni tanlang.'**
  String get textSizePreviewBody;

  /// Xabar oynasidagi tasdiqlash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @reportAction.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat qilish'**
  String get reportAction;

  /// No description provided for @reportSheetTitle.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat qilish'**
  String get reportSheetTitle;

  /// No description provided for @reportReasonLabel.
  ///
  /// In uz, this message translates to:
  /// **'Sabab'**
  String get reportReasonLabel;

  /// No description provided for @reportReasonSpam.
  ///
  /// In uz, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonHaqoratOmuhandaslik.
  ///
  /// In uz, this message translates to:
  /// **'Haqorat yoki tahdid'**
  String get reportReasonHaqoratOmuhandaslik;

  /// No description provided for @reportReasonAldash.
  ///
  /// In uz, this message translates to:
  /// **'Firibgarlik / aldash'**
  String get reportReasonAldash;

  /// No description provided for @reportReasonNomunosib.
  ///
  /// In uz, this message translates to:
  /// **'Nomunosib kontent'**
  String get reportReasonNomunosib;

  /// No description provided for @reportReasonBoshqa.
  ///
  /// In uz, this message translates to:
  /// **'Boshqa'**
  String get reportReasonBoshqa;

  /// No description provided for @reportDetailsLabel.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shimcha izoh'**
  String get reportDetailsLabel;

  /// No description provided for @reportDetailsHint.
  ///
  /// In uz, this message translates to:
  /// **'Batafsil yozing (ixtiyoriy)'**
  String get reportDetailsHint;

  /// No description provided for @reportSubmitAction.
  ///
  /// In uz, this message translates to:
  /// **'Yuborish'**
  String get reportSubmitAction;

  /// No description provided for @reportSubmittedMessage.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyatingiz qabul qilindi, ko\'rib chiqamiz'**
  String get reportSubmittedMessage;

  /// No description provided for @reportErrorMessage.
  ///
  /// In uz, this message translates to:
  /// **'Shikoyat yuborishda xatolik yuz berdi'**
  String get reportErrorMessage;

  /// No description provided for @reportChooseReasonError.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, sababni tanlang'**
  String get reportChooseReasonError;

  /// Xizmat kartochkasidagi reyting soni
  ///
  /// In uz, this message translates to:
  /// **'{count} baho'**
  String serviceRatingCount(int count);

  /// Xizmat kartochkasida hech kim baho bermagan bo'lsa
  ///
  /// In uz, this message translates to:
  /// **'Hali baho yo\'q'**
  String get serviceNoRatingsYet;

  /// Xizmatga yulduzcha baho berish qatorining sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Sizning bahoyingiz'**
  String get yourRatingLabel;

  /// Murojaatni xodimga biriktirish varag'ining sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Xodimga biriktirish'**
  String get assignStaffTitle;

  /// Biriktirish varag'ida mahallada xodim bo'lmaganda ko'rsatiladi
  ///
  /// In uz, this message translates to:
  /// **'Mahallada xodim topilmadi'**
  String get noStaffFoundLabel;

  /// Murojaatga biriktirilgan xodimni bekor qilish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Biriktirishni bekor qilish'**
  String get cancelAssignmentAction;

  /// Murojaat xodimga muvaffaqiyatli biriktirilganda chiqadigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Murojaat biriktirildi'**
  String get requestAssignedMessage;

  /// Murojaat bajarish muddati belgilanganda chiqadigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Muddat belgilandi'**
  String get dueDateSetMessage;

  /// Murojaatni xodimga biriktirish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Biriktirish'**
  String get assignAction;

  /// Murojaat bajarish muddatini belgilash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Muddat belgilash'**
  String get setDueDateAction;

  /// Murojaat biriktirilgan xodimning ismi ko'rsatiladigan yorliq
  ///
  /// In uz, this message translates to:
  /// **'Biriktirilgan: {fullName}'**
  String assignedToLabel(String fullName);

  /// Murojaat bajarish muddati sanasi ko'rsatiladigan yorliq
  ///
  /// In uz, this message translates to:
  /// **'Muddat: {date}'**
  String dueDateLabel(String date);

  /// Muddati o'tgan murojaatlar uchun sana yorlig'iga qo'shiladigan qo'shimcha
  ///
  /// In uz, this message translates to:
  /// **' — muddati o\'tdi'**
  String get dueDateOverdueSuffix;

  /// Murojaat tafsilotlari ekranidagi izohlar bo'limi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Izohlar'**
  String get commentsTitle;

  /// Murojaat ostida hali izoh yozilmagan bo'lsa ko'rsatiladi
  ///
  /// In uz, this message translates to:
  /// **'Hozircha izohlar yo\'q'**
  String get noCommentsYet;

  /// Izoh yozish maydonining placeholder matni
  ///
  /// In uz, this message translates to:
  /// **'Izoh yozing...'**
  String get commentHint;

  /// Murojaat tafsilotlari ekranida bir xil turdagi boshqa murojaatlar ro'yxati sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'O\'xshash murojaatlar'**
  String get similarRequestsTitle;

  /// Yangi guruh chati yaratish ekrani sarlavhasi/tugmasi/FAB yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Guruh yaratish'**
  String get createGroupAction;

  /// Yangi guruh yaratish formasidagi guruh nomi maydoni yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Guruh nomi'**
  String get groupNameLabel;

  /// Guruh nomi maydonining placeholder matni
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Ko\'cha faollari'**
  String get groupNameHint;

  /// Guruhga a'zolarni tanlash bo'limining sarlavhasi (hech kim tanlanmagan holat)
  ///
  /// In uz, this message translates to:
  /// **'A\'zolarni tanlang'**
  String get selectMembersLabel;

  /// Guruhga a'zolarni tanlash bo'limining sarlavhasi, tanlangan a'zolar soni bilan
  ///
  /// In uz, this message translates to:
  /// **'A\'zolarni tanlang ({count})'**
  String selectMembersLabelWithCount(int count);

  /// Guruh nomi kiritilmasdan yaratishga urinilganda chiqadigan xatolik
  ///
  /// In uz, this message translates to:
  /// **'Guruh nomini kiriting'**
  String get enterGroupNameError;

  /// Hech qanday a'zo tanlanmasdan guruh yaratishga urinilganda chiqadigan xatolik
  ///
  /// In uz, this message translates to:
  /// **'Kamida bitta a\'zo tanlang'**
  String get selectAtLeastOneMemberError;

  /// Guruh yaratishda server xatoligi yuz berganda chiqadigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Guruh yaratishda xatolik yuz berdi'**
  String get groupCreateError;

  /// Suhbatlar ekranidagi guruh chatlari bo'limining sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Guruhlar'**
  String get groupsSectionTitle;

  /// Yangi xizmat formasidagi ixtiyoriy joylashuv maydoni yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv'**
  String get locationFieldLabel;

  /// Joylashuv tanlanganda ko'rsatiladigan matn
  ///
  /// In uz, this message translates to:
  /// **'Joylashuv belgilandi'**
  String get locationSetLabel;

  /// Joylashuv tanlanmagan holatda ko'rsatiladigan matn va joylashuv tanlash ekrani sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni belgilash'**
  String get setLocationLabel;

  /// GPS orqali joriy joylashuvni aniqlab bo'lmaganda chiqadigan xatolik
  ///
  /// In uz, this message translates to:
  /// **'Joylashuvni aniqlab bo\'lmadi. Ruxsat yoki GPS holatini tekshiring.'**
  String get locationDetectError;

  /// Joylashuv tanlash xaritasi ustidagi ko'rsatma matni
  ///
  /// In uz, this message translates to:
  /// **'Xaritani bosib nuqta belgilang'**
  String get tapMapHint;

  /// AI Yordamchi ekrani sarlavhasi; shu matn Sozlamalar ekranidagi menyu bandida ham ishlatiladi. "Mahal" — yordamchining brend nomi, "Mening Mahallam" kabi barcha tillarda tarjima qilinmasdan aynan shu holicha qoladi
  ///
  /// In uz, this message translates to:
  /// **'Mahal'**
  String get assistantScreenTitle;

  /// AI Yordamchi ekrani sarlavhasi ("Mahal") ostidagi kichik tavsif yozuvi — brend nomidan farqli, bu oddiy tavsif so'zi bo'lgani uchun har bir tilda tarjima qilinadi
  ///
  /// In uz, this message translates to:
  /// **'AI yordamchi'**
  String get assistantSubtitleLabel;

  /// AI Yordamchi ekranidagi xabar kiritish maydonining placeholder matni
  ///
  /// In uz, this message translates to:
  /// **'Savolingizni yozing...'**
  String get assistantInputHint;

  /// AI Yordamchi ekrani hali xabar yo'q holatidagi salomlashuv sarlavhasi — yordamchi nomi ("Mahal")ni tilga oladi
  ///
  /// In uz, this message translates to:
  /// **'Salom! Men Mahalman'**
  String get assistantGreetingTitle;

  /// AI Yordamchi ekrani hali xabar yo'q holatidagi salomlashuv tavsifi
  ///
  /// In uz, this message translates to:
  /// **'Mahalla haqida savollaringizga javob berishga, ilovadan foydalanishga yordam berishga tayyorman.'**
  String get assistantGreetingSubtitle;

  /// AI Yordamchi ekranidagi tezkor savol taklifi (1-chi)
  ///
  /// In uz, this message translates to:
  /// **'Mahallamda qanday xizmatlar bor?'**
  String get assistantSuggestion1;

  /// AI Yordamchi ekranidagi tezkor savol taklifi (2-chi)
  ///
  /// In uz, this message translates to:
  /// **'Murojaat qanday yuboriladi?'**
  String get assistantSuggestion2;

  /// AI Yordamchi ekranidagi tezkor savol taklifi (3-chi)
  ///
  /// In uz, this message translates to:
  /// **'Ilovadan qanday foydalanaman?'**
  String get assistantSuggestion3;

  /// AI Yordamchi kunlik xabar limitiga yetgan, PREMIUM BO'LMAGAN foydalanuvchiga ko'rsatiladigan taklif kartochkasi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Kunlik limit tugadi'**
  String get assistantLimitUpsellTitle;

  /// AI Yordamchi kunlik xabar limitiga yetgan, premium bo'lmagan foydalanuvchiga ko'rsatiladigan taklif kartochkasi matni
  ///
  /// In uz, this message translates to:
  /// **'Premium bilan har kuni ancha ko\'proq xabar yuborishingiz mumkin.'**
  String get assistantLimitUpsellMessage;

  /// AI Yordamchi limit taklif kartochkasidagi, Premium ekraniga o'tuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Premium haqida'**
  String get assistantLimitUpsellButton;

  /// AI Yordamchi javobi ostida ko'rinadigan, Fikr-mulohaza ekraniga o'tuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Fikr bildirish'**
  String get assistantActionOpenFeedback;

  /// AI Yordamchi javobi ostida ko'rinadigan, Xizmatlar ekraniga o'tuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Xizmatlarni ko\'rish'**
  String get assistantActionOpenServices;

  /// AI Yordamchi javobi ostida ko'rinadigan, Yordam ekraniga o'tuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Yordam olish'**
  String get assistantActionOpenHelp;

  /// AI Yordamchi javobi ostida ko'rinadigan, Premium ekraniga o'tuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Premium haqida'**
  String get assistantActionOpenPremium;

  /// AI Yordamchi javobi ostida ko'rinadigan, bo'sh "Yangi murojaat" formasini ochuvchi tugma matni
  ///
  /// In uz, this message translates to:
  /// **'Murojaat ekranini ochish'**
  String get assistantActionOpenNewRequest;

  /// AI Yordamchi javobi ostida ko'rinadigan, AI aniqlagan qiymatlar bilan oldindan to'ldirilgan profil tahrirlash formasini ochuvchi tugma matni (premium)
  ///
  /// In uz, this message translates to:
  /// **'Profil formasini to\'ldirish'**
  String get assistantActionEditProfile;

  /// AI Yordamchi sidebar'idagi yangi (bo'sh) suhbat boshlash tugmasi matni
  ///
  /// In uz, this message translates to:
  /// **'Yangi suhbat'**
  String get assistantNewChat;

  /// AI Yordamchi sidebar'idagi suhbatni o'chirish tasdiqlash dialogining sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Suhbatni o\'chirish'**
  String get assistantDeleteChatTitle;

  /// AI Yordamchi sidebar'idagi suhbatni o'chirish tasdiqlash dialogining matni
  ///
  /// In uz, this message translates to:
  /// **'\"{title}\" suhbatini butunlay o\'chirmoqchimisiz?'**
  String assistantDeleteChatMessage(String title);

  /// Bildirishnoma turlari sozlash ekrani sarlavhasi; Sozlamalar ekranidagi shu ekranga o'tish bandining sarlavhasi sifatida ham ishlatiladi
  ///
  /// In uz, this message translates to:
  /// **'Bildirishnoma sozlamalari'**
  String get notificationPreferencesTitle;

  /// Sozlamalar ekranidagi 'Bildirishnoma sozlamalari' bandining tavsif matni
  ///
  /// In uz, this message translates to:
  /// **'Qaysi turdagi xabarlarni olishni tanlang'**
  String get notificationPreferencesSubtitle;

  /// Bildirishnoma turlari sozlash ekranidagi bo'lim sarlavhasi (ekranda katta harflar bilan ko'rsatiladi)
  ///
  /// In uz, this message translates to:
  /// **'Qaysi xabarlarni olasiz'**
  String get notificationPreferencesSectionHeader;

  /// Bildirishnoma turlari sozlash ekranidagi 'yangi e'lon' turi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Yangi e\'lonlar'**
  String get notificationTypeAnnouncementLabel;

  /// Bildirishnoma turlari sozlash ekranidagi 'yangi tadbir' turi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Yangi tadbirlar'**
  String get notificationTypeEventLabel;

  /// Bildirishnoma turlari sozlash ekranidagi 'yangi so'rovnoma' turi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Yangi so\'rovnomalar'**
  String get notificationTypePollLabel;

  /// Bildirishnoma turlari sozlash ekranidagi 'yangi xabar' turi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Yangi xabarlar'**
  String get notificationTypeMessageLabel;

  /// Bildirishnoma turlari sozlash ekranidagi 'murojaat holati o'zgarishi' turi yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Murojaat holati'**
  String get notificationTypeRequestStatusLabel;

  /// Internet aloqasi yo'qligida ilova bo'ylab ko'rinadigan banner matni
  ///
  /// In uz, this message translates to:
  /// **'Oflayn — internet yo\'q'**
  String get offlineBannerMessage;

  /// Murojaat tafsilotlari ekranidagi holat o'zgarishlari tarixi bo'limi sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Holat tarixi'**
  String get statusHistoryTitle;

  /// Tadbir tafsiloti ekranidagi eslatma qo'yish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Eslatib tur'**
  String get remindMeAction;

  /// Tadbir eslatmasi muvaffaqiyatli qo'yilganda ko'rsatiladigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Eslatma qo\'yildi'**
  String get reminderSetMessage;

  /// Tadbir eslatmasi bekor qilinganda ko'rsatiladigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Eslatma bekor qilindi'**
  String get reminderCancelledMessage;

  /// Rejalashtirilgan mahalliy bildirishnomaning sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'Tadbir eslatmasi'**
  String get eventReminderNotificationTitle;

  /// Chatdagi o'z xabarini tahrirlash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get editMessageAction;

  /// O'chirilgan chat xabari o'rniga ko'rsatiladigan matn
  ///
  /// In uz, this message translates to:
  /// **'Xabar o\'chirildi'**
  String get messageDeletedPlaceholder;

  /// Tahrirlangan chat xabari yoniga qo'shiladigan belgi
  ///
  /// In uz, this message translates to:
  /// **'(tahrirlangan)'**
  String get editedLabel;

  /// Qidiruv ekranida hali so'rov kiritilmaganda ko'rsatiladigan so'nggi qidiruvlar ro'yxati sarlavhasi
  ///
  /// In uz, this message translates to:
  /// **'So\'nggi qidiruvlar'**
  String get recentSearchesTitle;

  /// So'nggi qidiruvlar ro'yxatini tozalash tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Tozalash'**
  String get clearRecentSearchesAction;

  /// Foydalanuvchi mikrofon ruxsatini rad etganda ko'rsatiladigan xabar
  ///
  /// In uz, this message translates to:
  /// **'Mikrofonga ruxsat berilmadi'**
  String get microphonePermissionDeniedMessage;

  /// Xizmat ko'rsatuvchi hozir mavjud/band emasligini ko'rsatuvchi belgi
  ///
  /// In uz, this message translates to:
  /// **'Mavjud'**
  String get serviceAvailableLabel;

  /// Xizmat ko'rsatuvchi hozir band ekanini ko'rsatuvchi belgi
  ///
  /// In uz, this message translates to:
  /// **'Band'**
  String get serviceBusyLabel;

  /// Xizmat qo'shish/tahrirlash formasidagi mavjudlik toggle yorlig'i
  ///
  /// In uz, this message translates to:
  /// **'Hozir band emasman'**
  String get markBusyToggleLabel;

  /// Xizmat ko'rsatuvchiga telefon orqali qo'ng'iroq qilish tugmasi
  ///
  /// In uz, this message translates to:
  /// **'Qo\'ng\'iroq qilish'**
  String get callAction;

  /// Foydalanuvchining oxirgi faollik vaqtini ko'rsatuvchi yorliq
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi marta: {time}'**
  String lastSeenLabel(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'uz':
      {
        switch (locale.scriptCode) {
          case 'Cyrl':
            return AppLocalizationsUzCyrl();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
