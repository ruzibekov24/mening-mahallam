// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Моя махалля';

  @override
  String get splashTagline => 'Ваша махалля в одном приложении';

  @override
  String get onboardingAnnouncementsTitle => 'Будьте в курсе объявлений';

  @override
  String get onboardingAnnouncementsDescription =>
      'Все новости и объявления вашей махалли в одном месте';

  @override
  String get onboardingEventsTitle => 'Будьте в курсе мероприятий';

  @override
  String get onboardingEventsDescription =>
      'Участвуйте в собраниях и инициативах махалли';

  @override
  String get onboardingRequestsTitle => 'Отправьте обращение';

  @override
  String get onboardingRequestsDescription =>
      'Сообщите о проблеме и следите за ответом в реальном времени';

  @override
  String get onboardingNeighborsTitle => 'Свяжитесь с соседями';

  @override
  String get onboardingNeighborsDescription =>
      'Общайтесь с жителями махалли, принимайте решения вместе';

  @override
  String get previewAnnouncements => 'Объявления';

  @override
  String get previewEvents => 'Мероприятия';

  @override
  String get previewRequests => 'Обращения';

  @override
  String get previewNeighbors => 'Соседи';

  @override
  String get continueButton => 'Продолжить';

  @override
  String get skipButton => 'Пропустить';

  @override
  String get loginButton => 'Войти';

  @override
  String get registerButton => 'Зарегистрироваться';

  @override
  String get loginTitle => 'Вход';

  @override
  String get loginSubtitle => 'Введите свои данные';

  @override
  String get phoneLabel => 'Номер телефона';

  @override
  String get passwordLabel => 'Пароль';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get orDivider => 'или';

  @override
  String get noAccountQuestion => 'Нет аккаунта? ';

  @override
  String get phoneValidationError => 'Введите номер телефона полностью';

  @override
  String get passwordValidationError =>
      'Пароль должен содержать не менее 6 символов';

  @override
  String get unexpectedError => 'Произошла непредвиденная ошибка';

  @override
  String get registerTitle => 'Регистрация';

  @override
  String get registerSubtitle => 'Создать новый аккаунт';

  @override
  String get firstNameLabel => 'Имя';

  @override
  String get lastNameLabel => 'Фамилия';

  @override
  String get firstNameValidationError => 'Введите ваше имя';

  @override
  String get lastNameValidationError => 'Введите вашу фамилию';

  @override
  String get haveAccountQuestion => 'Уже есть аккаунт? ';

  @override
  String get welcomeGreeting => 'Добро пожаловать';

  @override
  String helloUser(String name) {
    return 'Здравствуйте, $name!';
  }

  @override
  String get helloGeneric => 'Здравствуйте!';

  @override
  String get guestName => 'гость';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get categoryAnnouncements => 'Объявления';

  @override
  String get categoryEvents => 'Мероприятия';

  @override
  String get categoryRequests => 'Обращения';

  @override
  String get categoryNeighbors => 'Соседи';

  @override
  String get upcomingEventsTitle => 'Ближайшие мероприятия';

  @override
  String get noUpcomingEvents => 'Пока нет ближайших мероприятий';

  @override
  String get eventsLoadError => 'Ошибка при загрузке мероприятий';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get defaultUserName => 'Пользователь';

  @override
  String get profileLoadError => 'Ошибка загрузки данных';

  @override
  String get chooseBannerTitle => 'Выберите баннер';

  @override
  String get premiumBannerLockedMessage =>
      'Этот баннер премиум — пока заблокирован';

  @override
  String get premiumTitle => 'Премиум';

  @override
  String get premiumSettingSubtitle =>
      'Безлимитные обращения, без рекламы и другое';

  @override
  String get premiumHeroTitle => 'Премиум-подписка';

  @override
  String get premiumHeroSubtitle =>
      'Будьте активнее в махалле — без ограничений';

  @override
  String get premiumPerMonth => 'сум/мес.';

  @override
  String get premiumBenefitsTitle => 'ЧТО ОТКРЫВАЕТСЯ';

  @override
  String get premiumBenefitUnlimited =>
      'Безлимитные обращения — без дневного лимита';

  @override
  String get premiumBenefitNoAds => 'Реклама не показывается вовсе';

  @override
  String get premiumBenefitPriority => 'Ваше обращение выше в списке';

  @override
  String get premiumBenefitImages => 'До 10 фото в одном обращении';

  @override
  String get premiumBenefitBanners => 'Особые баннеры профиля';

  @override
  String get premiumBenefitBadge => 'Премиум-значок в профиле';

  @override
  String get premiumBuyAction => 'Получить премиум';

  @override
  String get premiumActiveTitle => 'Премиум активен';

  @override
  String premiumActiveUntil(String date, int days) {
    return 'До $date — осталось $days дн.';
  }

  @override
  String get premiumTransferHint =>
      'Переведите на карту ниже. Нажмите, чтобы скопировать.';

  @override
  String get premiumCardNumber => 'Номер карты';

  @override
  String get premiumCardHolder => 'Владелец карты';

  @override
  String get premiumAmount => 'Сумма оплаты';

  @override
  String get premiumCardCopied => 'Номер карты скопирован';

  @override
  String get premiumHolderCopied => 'Имя владельца скопировано';

  @override
  String get premiumAmountCopied => 'Сумма скопирована';

  @override
  String premiumPaymentTimeLeft(String time) {
    return 'На оплату осталось $time';
  }

  @override
  String get premiumPaymentExpired => 'Время оплаты истекло — начните заново';

  @override
  String get premiumIPaidAction => 'Я оплатил';

  @override
  String get premiumContactAdmin => 'Админ в Telegram';

  @override
  String get premiumTelegramHint =>
      'Для более быстрого подтверждения отправьте чек в Telegram — по желанию.';

  @override
  String get premiumWaitingTitle => 'Ожидает подтверждения';

  @override
  String get premiumWaitingSubtitle =>
      'Премиум откроется после проверки оплаты';

  @override
  String get premiumRequestsTitle => 'Премиум-заявки';

  @override
  String get premiumRequestsEmpty => 'Нет ожидающих заявок';

  @override
  String premiumRequestMonths(int count) {
    return 'Подписка на $count мес.';
  }

  @override
  String get premiumApproveAction => 'Подтвердить';

  @override
  String get premiumRejectAction => 'Отклонить';

  @override
  String get adLabel => 'Реклама';

  @override
  String get adManagementTitle => 'Реклама услуг';

  @override
  String get adAddAction => 'Добавить рекламу';

  @override
  String get adEmptyTitle => 'Пока нет рекламы';

  @override
  String get adTitleLabel => 'Название услуги';

  @override
  String get adDescriptionLabel => 'Краткое описание';

  @override
  String get adOwnerLabel => 'Мастер / организация';

  @override
  String get adTitleRequired => 'Введите название услуги';

  @override
  String get adSaveAction => 'Сохранить';

  @override
  String get adStatusActive => 'Активна';

  @override
  String get adStatusExpired => 'Истекла';

  @override
  String adActiveUntil(String date) {
    return 'Активна до $date';
  }

  @override
  String get adExtendAction => 'Продлить на 7 дней';

  @override
  String get adPromoteTitle => 'Прорекламируйте свою услугу';

  @override
  String adPromoteSubtitle(String price) {
    return '$price в неделю — увидит вся махалля';
  }

  @override
  String get adPromoteAction => 'Заказать рекламу';

  @override
  String get noMahallaTitle => 'Сначала присоединитесь к махалле';

  @override
  String get noMahallaSubtitle =>
      'Отсканируйте QR-код, который даёт раис махалли — после этого здесь появятся объявления, обращения и соседи.';

  @override
  String get noMahallaAction => 'Сканировать QR-код';

  @override
  String get emptyAnnouncementsSubtitle =>
      'Здесь появятся объявления от раиса и сотрудников махалли.';

  @override
  String get emptyRequestsSubtitle =>
      'Если в махалле есть проблема, вы можете отправить первое обращение.';

  @override
  String get emptyRequestsAction => 'Отправить обращение';

  @override
  String get emptyNeighborsSubtitle =>
      'Соседи появятся здесь, когда присоединятся к приложению. Пригласите их!';

  @override
  String get emptyServicesSubtitle =>
      'Здесь собираются мастера и услуги вашей махалли.';

  @override
  String get emptyEventsSubtitle =>
      'Здесь появятся запланированные мероприятия.';

  @override
  String get premiumBadgeLabel => 'Премиум';

  @override
  String get chooseBadgeStyleTitle => 'Выберите стиль значка';

  @override
  String get premiumBadgeStyleGold => 'Золотой';

  @override
  String get premiumBadgeStyleSapphire => 'Сапфировый';

  @override
  String get premiumBadgeStyleEmerald => 'Изумрудный';

  @override
  String get premiumBadgeStyleRuby => 'Рубиновый';

  @override
  String get premiumBadgeStyleSilver => 'Серебряный';

  @override
  String dailyRequestLimitReached(Object count) {
    return 'Вы достигли дневного лимита обращений ($count). Попробуйте завтра или оформите Premium для безлимитной отправки.';
  }

  @override
  String get myInfoMenuItem => 'Мои данные';

  @override
  String get notificationsMenuItem => 'Уведомления';

  @override
  String get settingsMenuItem => 'Настройки';

  @override
  String get helpMenuItem => 'Помощь';

  @override
  String get logoutMenuItem => 'Выйти';

  @override
  String get logoutConfirmTitle => 'Подтвердите выход';

  @override
  String get logoutConfirmMessage =>
      'Вы действительно хотите выйти из системы?';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get sectionMahalla => 'Махалля';

  @override
  String get currentMahalla => 'Текущая махалля';

  @override
  String get notConnected => 'Не подключено';

  @override
  String get unknownValue => 'Неизвестно';

  @override
  String get changeButton => 'Изменить';

  @override
  String get changeMahallaTitle => 'Смена махалли';

  @override
  String get changeMahallaMessage =>
      'Вы подключитесь к новой махалле через сканирование QR-кода или ввод кода вручную. Продолжить?';

  @override
  String get sectionGeneral => 'Общие';

  @override
  String get sectionManagement => 'Управление';

  @override
  String get membersManagementTitle => 'Управление участниками';

  @override
  String get noMembersYet => 'Пока нет участников';

  @override
  String get roleUpdated => 'Роль обновлена';

  @override
  String get selectRoleTitle => 'Выберите роль';

  @override
  String get languageSettingTitle => 'Язык';

  @override
  String get languageUpdatedMessage => 'Язык изменён';

  @override
  String get appearanceSettingTitle => 'Вид';

  @override
  String get textSizeSettingTitle => 'Размер текста';

  @override
  String get sectionAbout => 'О приложении';

  @override
  String get versionLabel => 'Версия';

  @override
  String get statActiveRequests => 'Активные обращения';

  @override
  String get statNewAnnouncements => 'Новые объявления';

  @override
  String get statUpcomingEvents => 'Ближайшие мероприятия';

  @override
  String get myRequestsStat => 'Мои обращения';

  @override
  String get myAnnouncementsStat => 'Мои объявления';

  @override
  String get myJoinedStat => 'Присоединился(-ась)';

  @override
  String get myRequestsTitle => 'Мои обращения';

  @override
  String get recentActivityTitle => 'Последние действия';

  @override
  String get mahallaStatsTitle => 'Статистика махалли';

  @override
  String get statsTotalMembers => 'Участники';

  @override
  String get statsActiveRequests => 'Активные обращения';

  @override
  String get statsNewAnnouncements => 'Новые объявления';

  @override
  String get statsUpcomingEvents => 'Ближайшие события';

  @override
  String get noRecentActivity => 'Пока нет активности';

  @override
  String get activityLoadError => 'Ошибка при загрузке активности';

  @override
  String activityNewAnnouncement(String title) {
    return 'Новое объявление: $title';
  }

  @override
  String activityNewRequest(String title) {
    return 'Новое обращение: $title';
  }

  @override
  String activityNewEvent(String title) {
    return 'Новое мероприятие: $title';
  }

  @override
  String minutesAgo(int count) {
    return '$count мин. назад';
  }

  @override
  String hoursAgo(int count) {
    return '$count ч. назад';
  }

  @override
  String daysAgo(int count) {
    return '$count дн. назад';
  }

  @override
  String get sectionAccount => 'Аккаунт';

  @override
  String get changePasswordTitle => 'Изменить пароль';

  @override
  String get changePhoneTitle => 'Изменить номер телефона';

  @override
  String get deleteAccountTitle => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirmTitle => 'Удаление аккаунта';

  @override
  String get deleteAccountConfirmMessage =>
      'Это действие необратимо. Все ваши данные будут полностью удалены. Продолжить?';

  @override
  String get deleteButton => 'Удалить';

  @override
  String get editButton => 'Редактировать';

  @override
  String get sectionDataStorage => 'Данные и хранилище';

  @override
  String get clearCacheTitle => 'Очистить кеш';

  @override
  String get clearCacheSubtitle => 'Удаляет временно сохранённые файлы';

  @override
  String get cacheClearedMessage => 'Кеш очищен';

  @override
  String get sectionSupport => 'Поддержка';

  @override
  String get rateAppTitle => 'Оценить приложение';

  @override
  String get feedbackTitle => 'Оставить отзыв';

  @override
  String get feedbackSubtitle =>
      'Ваше мнение о приложении важно для нас — оно напрямую попадает к руководству махалли.';

  @override
  String get feedbackRatingRequiredError =>
      'Пожалуйста, поставьте оценку звёздами';

  @override
  String get feedbackMessageLabel => 'Ваш отзыв (необязательно)';

  @override
  String get feedbackMessageHint => 'Что понравилось, что нужно улучшить?';

  @override
  String get feedbackSubmitButton => 'Отправить';

  @override
  String get feedbackSubmittedMessage => 'Спасибо! Ваш отзыв отправлен';

  @override
  String get feedbackModeRatingTab => 'Оценить приложение';

  @override
  String get feedbackModeQuestionTab => 'Вопрос / Обращение';

  @override
  String get feedbackQuestionTitle => 'Вопрос или обращение';

  @override
  String get feedbackQuestionSubtitle =>
      'Напишите свой вопрос или обращение — суперадмин рассмотрит его и при необходимости свяжется с вами.';

  @override
  String get feedbackQuestionMessageHint =>
      'Напишите здесь свой вопрос или обращение...';

  @override
  String get feedbackQuestionBadge => 'Вопрос';

  @override
  String get feedbackListTitle => 'Отзывы пользователей';

  @override
  String get noFeedbackFound => 'Пока нет отзывов';

  @override
  String get unknownUserLabel => 'Неизвестный пользователь';

  @override
  String get requestAuthorLabel => 'Отправитель';

  @override
  String get quickNewRequestTitle => 'Отправить новое обращение';

  @override
  String get quickNewRequestSubtitle =>
      'Есть проблема? Отправьте за несколько секунд';

  @override
  String get mahalCardTitle => 'Чат с Махал';

  @override
  String get mahalCardSubtitle =>
      'Получите ответы на вопросы, отправьте обращение или спросите о махалле';

  @override
  String get openLinkAction => 'Открыть ссылку';

  @override
  String get linkOpenFailedMessage => 'Не удалось открыть ссылку';

  @override
  String get bannerManagementTitle => 'Баннеры';

  @override
  String get addBannerTitle => 'Добавить баннер';

  @override
  String get bannerTitleLabel => 'Заголовок';

  @override
  String get bannerDescriptionLabel => 'Описание (необязательно)';

  @override
  String get bannerLinkLabel => 'Ссылка (необязательно, https://...)';

  @override
  String get bannerAttributionLabel => 'Автор/источник (необязательно)';

  @override
  String get bannerImageRequiredError => 'Пожалуйста, выберите изображение';

  @override
  String get bannerTitleRequiredError => 'Пожалуйста, введите заголовок';

  @override
  String get noBannersFound => 'Пока нет баннеров';

  @override
  String get mahallaOnMapTitle => 'Ваша махалля на карте';

  @override
  String get developerTitle => 'Разработчик';

  @override
  String get developerSubtitle => 'Команда Mahallam';

  @override
  String get termsTitle => 'Условия использования';

  @override
  String get privacyPolicyTitle => 'Политика конфиденциальности';

  @override
  String get comingSoonMessage => 'Эта функция скоро появится';

  @override
  String get profileSaved => 'Данные сохранены';

  @override
  String get saveButton => 'Сохранить';

  @override
  String get faqTitle => 'Часто задаваемые вопросы';

  @override
  String get contactUsTitle => 'Связаться с нами';

  @override
  String get callUs => 'По телефону';

  @override
  String get telegramUs => 'Через Telegram';

  @override
  String get faqQ1 => 'Как присоединиться к махалле?';

  @override
  String get faqA1 =>
      'После регистрации вы подключитесь к своей махалле, отсканировав QR-код, выданный председателем или ответственным сотрудником.';

  @override
  String get faqQ2 => 'Как отправить обращение?';

  @override
  String get faqA2 =>
      'Перейдите в раздел \"Обращения\" и создайте новое обращение. Статус будет отображаться как \"Новое\", \"В процессе\" или \"Завершено\".';

  @override
  String get faqQ3 => 'Как посмотреть объявления?';

  @override
  String get faqA3 =>
      'В разделе \"Объявления\" на главном экране показаны все официальные объявления вашей махалли по категориям.';

  @override
  String get faqQ4 => 'Я забыл пароль, что делать?';

  @override
  String get faqA4 =>
      'Нажмите «Забыли пароль?» на экране входа. На вашу почту придёт ссылка для восстановления. Если письма нет, проверьте папку «Спам».';

  @override
  String get faqQ5 => 'Безопасны ли мои данные?';

  @override
  String get faqA5 =>
      'Да, все данные видны только в пределах вашей махалли и хранятся на защищённом сервере.';

  @override
  String get callFailedMessage => 'Не удалось совершить звонок';

  @override
  String get telegramFailedMessage => 'Не удалось открыть Telegram';

  @override
  String get announcementsTitle => 'Объявления';

  @override
  String get eventsTitle => 'Мероприятия';

  @override
  String get feedTitle => 'Лента';

  @override
  String get postsFilterLabel => 'Посты';

  @override
  String get noPostsYet => 'Пока нет постов';

  @override
  String get noPostsHint =>
      'Когда сосед опубликует первый пост, он появится здесь.';

  @override
  String get writePostHint => 'Что у вас нового?';

  @override
  String get postCreatedMessage => 'Пост опубликован';

  @override
  String get writePostOrImageError => 'Напишите текст или добавьте фото';

  @override
  String get postUpdatedMessage => 'Пост обновлён';

  @override
  String get editPostTitle => 'Редактировать пост';

  @override
  String get postingTooFastError =>
      'Вы публикуете слишком часто. Подождите немного и попробуйте снова.';

  @override
  String get inappropriateContentError =>
      'Текст содержит недопустимые слова. Пожалуйста, отредактируйте текст.';

  @override
  String get reactionsSheetTitle => 'Реакции';

  @override
  String get repostAction => 'Репост';

  @override
  String repostedByLabel(String name) {
    return '$name сделал(а) репост';
  }

  @override
  String get repostSuccessMessage => 'Репост сделан';

  @override
  String get repostRemovedMessage => 'Репост отменён';

  @override
  String get addStoryLabel => 'Добавить историю';

  @override
  String get yourStoryLabel => 'Ваша история';

  @override
  String get newButton => 'Новое';

  @override
  String get noAnnouncementsYet => 'Пока нет объявлений';

  @override
  String get noEventsYet => 'Пока нет мероприятий';

  @override
  String get announcementsLoadError => 'Ошибка при загрузке объявлений';

  @override
  String participantsCount(int count) {
    return '$count участников';
  }

  @override
  String todayAt(String time) {
    return 'Сегодня, $time';
  }

  @override
  String get categoryKommunal => 'Коммунальные';

  @override
  String get categoryXavfsizlik => 'Безопасность';

  @override
  String get categoryUmumiy => 'Общее';

  @override
  String get newAnnouncementTitle => 'Новое объявление';

  @override
  String get editAnnouncementTitle => 'Редактировать объявление';

  @override
  String get pollsTitle => 'Опросы';

  @override
  String get newPollTitle => 'Новый опрос';

  @override
  String get pollQuestionHint => 'Напишите ваш вопрос...';

  @override
  String pollOptionHint(int number) {
    return 'Вариант $number';
  }

  @override
  String get addOptionButton => 'Добавить вариант';

  @override
  String get fillPollFields => 'Введите вопрос и минимум 2 варианта';

  @override
  String get pollPostedMessage => 'Опрос опубликован';

  @override
  String get noPollsYet => 'Пока нет опросов';

  @override
  String pollVotesCount(int count) {
    return '$count голосов';
  }

  @override
  String get conversationsTitle => 'Сообщения';

  @override
  String get conversationsMenuItem => 'Сообщения';

  @override
  String get noConversationsYet => 'Пока нет диалогов';

  @override
  String get noMessagesYet => 'Пока нет сообщений. Напишите первым!';

  @override
  String get messageHint => 'Напишите сообщение...';

  @override
  String get sendMessageAction => 'Написать сообщение';

  @override
  String get typingIndicator => 'печатает...';

  @override
  String get attachImageAction => 'Прикрепить фото';

  @override
  String get imageUploadFailed =>
      'Не удалось отправить фото. Попробуйте ещё раз';

  @override
  String get yesterdayLabel => 'Вчера';

  @override
  String get switchMahallaTitle => 'Выбор махалли';

  @override
  String get switchMahallaMenuItem => 'Переключить махаллю (Супер админ)';

  @override
  String get switchMahallaMenuItemActive => 'Вы управляете другой махаллёй';

  @override
  String get exitMahallaModeAction => 'Вернуться в свою махаллю';

  @override
  String get noMahallasFound => 'Махалли не найдены';

  @override
  String get broadcastToAllMahallasLabel =>
      'Отправить во все махалли (Супер админ)';

  @override
  String get servicesTitle => 'Местные услуги';

  @override
  String get newServiceTitle => 'Добавить услугу';

  @override
  String get editServiceTitle => 'Редактировать услугу';

  @override
  String get serviceCategoryLabel => 'Категория';

  @override
  String get serviceNameLabel => 'Имя или название организации';

  @override
  String get serviceNameHint => 'Например: Азиз ака (сантехник)';

  @override
  String get servicePhoneLabel => 'Номер телефона';

  @override
  String get serviceDescriptionLabel => 'Описание';

  @override
  String get serviceDescriptionHint => 'Часы работы, цена и т.д...';

  @override
  String get fillServiceFields => 'Введите имя и номер телефона';

  @override
  String get servicePostedMessage => 'Услуга добавлена';

  @override
  String get serviceUpdatedMessage => 'Услуга обновлена';

  @override
  String get noServicesYet => 'Пока нет услуг';

  @override
  String get serviceCategorySantexnik => 'Сантехник';

  @override
  String get serviceCategoryElektrik => 'Электрик';

  @override
  String get serviceCategoryDuradgor => 'Плотник';

  @override
  String get serviceCategoryTozalash => 'Уборка';

  @override
  String get serviceCategoryQurilish => 'Строительство';

  @override
  String get serviceCategoryBoshqa => 'Другое';

  @override
  String get editPollTitle => 'Редактировать опрос';

  @override
  String get pollUpdatedMessage => 'Опрос обновлён';

  @override
  String get changeVoteConfirmTitle => 'Изменить голос';

  @override
  String get changeVoteConfirmMessage =>
      'Вы уже проголосовали за другой вариант. Хотите изменить свой голос?';

  @override
  String get changeVoteConfirmButton => 'Да, изменить';

  @override
  String get pollAllowMultipleLabel => 'Разрешить выбор нескольких вариантов';

  @override
  String get pollAnonymousLabel => 'Анонимный опрос';

  @override
  String get pollClosesAtLabel => 'Дата закрытия (необязательно)';

  @override
  String get pollClosesAtClearButton => 'Очистить';

  @override
  String get pollClosedBadge => 'Закрыт';

  @override
  String get pollVoteClosedError => 'Этот опрос закрыт, голосование недоступно';

  @override
  String get pollSubmitVoteButton => 'Проголосовать';

  @override
  String get categoryServices => 'Услуги';

  @override
  String get categoryPolls => 'Опросы';

  @override
  String get categoryLabel => 'Категория';

  @override
  String get titleLabel => 'Заголовок';

  @override
  String get titleHint => 'Например: Об отключении воды завтра';

  @override
  String get bodyLabel => 'Текст';

  @override
  String get bodyHint => 'Подробно опишите объявление...';

  @override
  String get photoLabel => 'Фото';

  @override
  String get optionalLabel => '(необязательно)';

  @override
  String get postButton => 'Опубликовать';

  @override
  String get fillTitleAndBody => 'Заполните заголовок и текст';

  @override
  String get announcementPosted => 'Объявление успешно опубликовано';

  @override
  String get announcementUpdated => 'Объявление обновлено';

  @override
  String get requestsTitle => 'Обращения';

  @override
  String get mustVerifyMahallaFirst => 'Сначала подтвердите вашу махаллю';

  @override
  String get managementPanelBanner => 'Панель управления — все обращения';

  @override
  String get requestsLoadError => 'Ошибка при загрузке обращений';

  @override
  String joinedCount(int count) {
    return '$count присоединились';
  }

  @override
  String noRequestsWithStatus(String status) {
    return 'Нет обращений: $status';
  }

  @override
  String get filterAll => 'Все';

  @override
  String get noRequestsAtAll => 'Пока нет обращений';

  @override
  String get statusYangi => 'Новое';

  @override
  String get statusJarayonda => 'В процессе';

  @override
  String get statusYakunlandi => 'Завершено';

  @override
  String get typeMaxfiy => 'Конфиденциальное';

  @override
  String get typeOmmaviy => 'Публичное';

  @override
  String get priorityPast => 'Низкий';

  @override
  String get priorityOrtacha => 'Средний';

  @override
  String get priorityYuqori => 'Высокий';

  @override
  String get managementPanelTitle => 'Панель управления';

  @override
  String get changeStatusTitle => 'Изменить статус';

  @override
  String statusChangedMessage(String status) {
    return 'Статус изменён на \"$status\"';
  }

  @override
  String get statusChangeError => 'Ошибка при изменении статуса';

  @override
  String get allFilter => 'Все';

  @override
  String get noRequestsFound => 'Обращения не найдены';

  @override
  String get tapToChangeStatus => 'Нажмите, чтобы изменить статус';

  @override
  String get stepType => 'Тип';

  @override
  String get stepDetails => 'Детали';

  @override
  String get stepLocation => 'Местоположение';

  @override
  String get stepReview => 'Проверка';

  @override
  String get stepDone => 'Готово';

  @override
  String get newRequestTitle => 'Новое обращение';

  @override
  String get fillTitleAndDescription => 'Заполните заголовок и описание';

  @override
  String get sendButton => 'Отправить';

  @override
  String get chooseRequestType => 'Выберите тип обращения';

  @override
  String get requestTypeExplain =>
      'Это определяет, кто сможет видеть ваше обращение';

  @override
  String get typeMaxfiyDescription => 'Видят только вы и председатель махалли';

  @override
  String get typeOmmaviyDescription =>
      'Видят все в махалле, можно присоединиться';

  @override
  String get titleFieldLabel => 'Заголовок';

  @override
  String get titleFieldHint => 'Например: Не работает уличное освещение';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get descriptionHint => 'Подробно опишите проблему...';

  @override
  String get attachPhotoLabel => 'Прикрепить фото';

  @override
  String get priorityLevelLabel => 'Уровень важности';

  @override
  String get reviewDataTitle => 'Проверьте данные';

  @override
  String get reviewType => 'Тип';

  @override
  String get reviewPriority => 'Важность';

  @override
  String get reviewLocation => 'Местоположение';

  @override
  String get reviewLocationSet => 'Указано';

  @override
  String get reviewLocationNotSet => 'Не указано';

  @override
  String reviewPhotos(int count) {
    return 'Фото ($count)';
  }

  @override
  String get requestSentTitle => 'Обращение отправлено!';

  @override
  String get requestSentMessage => 'Ваше обращение принято и рассматривается';

  @override
  String get backToListButton => 'Вернуться к списку';

  @override
  String get qrScanInstruction => 'Наведите рамку на QR-код у двери махалли';

  @override
  String get checkingStatus => 'Проверка...';

  @override
  String get scanningStatus => 'Сканирование...';

  @override
  String get enterCodeManually => 'Ввести код вручную';

  @override
  String get enterMahallaCodeTitle => 'Введите код махалли';

  @override
  String get mahallaCodeHint => 'Например: MFY-00123';

  @override
  String get confirmButton => 'Подтвердить';

  @override
  String get qrGenericError => 'Произошла ошибка, попробуйте снова';

  @override
  String get confirmError => 'Ошибка при подтверждении, попробуйте снова';

  @override
  String get mahallaFoundLabel => 'Махалля найдена';

  @override
  String get rescanButton => 'Сканировать снова';

  @override
  String get changePhotoLabel => 'Изменить фото';

  @override
  String get birthDateLabel => 'Дата рождения';

  @override
  String get addressLabel => 'Адрес';

  @override
  String get streetLabel => 'Улица';

  @override
  String get streetHint => 'Например: улица Богбон';

  @override
  String get houseNumberLabel => 'Номер дома';

  @override
  String get houseNumberHint => 'Например: 15';

  @override
  String get genderLabel => 'Пол';

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get notSpecified => 'Не указано';

  @override
  String get selectDate => 'Выберите дату';

  @override
  String get photoUploadError => 'Ошибка при загрузке фото';

  @override
  String get otpTitle => 'Код подтверждения';

  @override
  String otpSubtitle(String phone) {
    return 'Введите 6-значный код, отправленный на $phone';
  }

  @override
  String get otpInvalidCode => 'Неверный код, попробуйте снова';

  @override
  String get otpResendCode => 'Отправить код повторно';

  @override
  String otpResendCooldown(int seconds) {
    return 'Повторно ($secondsс)';
  }

  @override
  String get forgotPasswordTitle => 'Восстановление пароля';

  @override
  String get forgotPasswordSubtitle =>
      'Введите номер телефона, указанный при регистрации, мы отправим код подтверждения';

  @override
  String get sendCodeButton => 'Отправить код';

  @override
  String get newPasswordLabel => 'Новый пароль';

  @override
  String get newPasswordTitle => 'Установите новый пароль';

  @override
  String get newPasswordSubtitle =>
      'Придумайте новый пароль для своего аккаунта';

  @override
  String get savePasswordButton => 'Сохранить пароль';

  @override
  String get passwordResetSuccess => 'Пароль успешно обновлён';

  @override
  String get newEventTitle => 'Новое мероприятие';

  @override
  String get editEventTitle => 'Редактировать мероприятие';

  @override
  String get eventTitleHint => 'Например: Собрание махалли';

  @override
  String get eventDescriptionHint =>
      'Дополнительная информация о событии (необязательно)...';

  @override
  String get dateLabel => 'Дата';

  @override
  String get selectTime => 'Выберите время';

  @override
  String get locationLabel => 'Место';

  @override
  String get locationHint => 'Место проведения мероприятия';

  @override
  String get fillEventFields => 'Введите название и дату';

  @override
  String get eventPosted => 'Мероприятие опубликовано';

  @override
  String get eventUpdated => 'Мероприятие обновлено';

  @override
  String get neighborsTitle => 'Соседи';

  @override
  String get mahalladoshlar => 'Жители махалли';

  @override
  String get yozishmalarTitle => 'Переписки';

  @override
  String get noNeighborsYet => 'Пока нет соседей';

  @override
  String get onlineNow => 'В сети';

  @override
  String get lastSeenUnknown => 'Последняя активность неизвестна';

  @override
  String get lastSeenJustNow => 'Только что был(а) активен(на)';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return '$minutes мин. назад';
  }

  @override
  String lastSeenHoursAgo(int hours) {
    return '$hours ч. назад';
  }

  @override
  String lastSeenDaysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String get sectionPrivacy => 'Приватность';

  @override
  String get showPhoneToNeighborsTitle => 'Показывать телефон соседям';

  @override
  String get showPhoneToNeighborsSubtitle =>
      'Если включено, ваш номер будет виден в списке соседей';

  @override
  String get privacySecurityTitle => 'Приватность и безопасность';

  @override
  String get privacySecuritySubtitle => 'Видимость, заблокированные, пароль';

  @override
  String get sectionVisibility => 'Видимость';

  @override
  String get showLastSeenTitle => 'Показывать последнюю активность';

  @override
  String get showLastSeenSubtitle =>
      'Если включено, соседи увидят ваш онлайн статус';

  @override
  String get sectionBlockedUsers => 'Заблокированные пользователи';

  @override
  String get blockedUsersTitle => 'Заблокированные пользователи';

  @override
  String get noBlockedUsers => 'Нет заблокированных пользователей';

  @override
  String blockedUsersCount(int count) {
    return 'Заблокировано: $count';
  }

  @override
  String get blockUserAction => 'Заблокировать';

  @override
  String get blockUserConfirmTitle => 'Заблокировать пользователя';

  @override
  String blockUserConfirmMessage(String name) {
    return '$name не сможет писать вам и не будет виден в вашем списке. Продолжить?';
  }

  @override
  String userBlockedMessage(String name) {
    return '$name заблокирован(а)';
  }

  @override
  String get unblockAction => 'Разблокировать';

  @override
  String userUnblockedMessage(String name) {
    return '$name разблокирован(а)';
  }

  @override
  String get phoneHiddenByUser => 'Этот пользователь скрыл номер телефона';

  @override
  String get markAllAsReadAction => 'Отметить все как прочитанные';

  @override
  String get noNotificationsYet => 'Пока нет уведомлений';

  @override
  String get searchPromptText =>
      'Найдите объявление, мероприятие или обращение';

  @override
  String get searchNoResults => 'Ничего не найдено';

  @override
  String get requestDetailTitle => 'Детали обращения';

  @override
  String get requestNotFound => 'Обращение не найдено';

  @override
  String get announcementDetailTitle => 'Детали объявления';

  @override
  String get announcementNotFound => 'Объявление не найдено';

  @override
  String get eventDetailTitle => 'Детали события';

  @override
  String get eventNotFound => 'Событие не найдено';

  @override
  String get shareAction => 'Поделиться';

  @override
  String get joinRequestAction => 'Присоединиться';

  @override
  String get leaveRequestAction => 'Выйти';

  @override
  String get mahallaStaffTitle => 'Сотрудники махалли';

  @override
  String get mahallaMapTitle => 'Карта махалли';

  @override
  String get locationStepTitle => 'Укажите местоположение';

  @override
  String get locationStepSubtitle =>
      'Нажмите на карту, чтобы поставить точку, или используйте текущее местоположение (необязательно)';

  @override
  String get locationPermissionError =>
      'Доступ к местоположению не предоставлен';

  @override
  String get clearLocationAction => 'Очистить';

  @override
  String get boundaryEditorTitle => 'Обозначить границу';

  @override
  String get boundaryEditorHint =>
      'Нажмите на карту, чтобы поставить точки вдоль границы махалли (минимум 3)';

  @override
  String get boundaryMinPointsError => 'Отметьте минимум 3 точки';

  @override
  String get boundarySavedMessage => 'Граница сохранена';

  @override
  String get saveBoundaryAction => 'Сохранить границу';

  @override
  String get editBoundaryAction => 'Редактировать границу';

  @override
  String get mapLayerSatellite => 'Спутниковый вид';

  @override
  String get mapLayerStreets => 'Карта улиц';

  @override
  String get deleteItemConfirmTitle => 'Удалить';

  @override
  String deleteItemConfirmMessage(String title) {
    return '«$title» будет удалено навсегда. Это действие нельзя отменить.';
  }

  @override
  String get itemDeletedMessage => 'Удалено';

  @override
  String get searchNeighborHint => 'Поиск по имени...';

  @override
  String get currentPasswordLabel => 'Текущий пароль';

  @override
  String get confirmPasswordLabel => 'Подтвердите пароль';

  @override
  String get passwordMismatchError => 'Пароли не совпадают';

  @override
  String get newPhoneLabel => 'Новый номер телефона';

  @override
  String get phoneChangedMessage => 'Номер телефона успешно изменён';

  @override
  String get termsBody =>
      'Используя это приложение, вы соглашаетесь со следующими условиями:\n\n1. Приложение предназначено для облегчения общения между жителями и сотрудниками махалли.\n2. Пользователь обязан указывать достоверную информацию в своём профиле.\n3. Запрещено распространение оскорбительной, незаконной или ложной информации о других пользователях.\n4. Объявления и мероприятия, размещённые администрацией махалли (сотрудник/раис), могут носить официальный характер.\n5. Администрация приложения оставляет за собой право блокировать или удалять аккаунты при нарушении правил.';

  @override
  String get privacyPolicyBody =>
      'Как используются ваши данные:\n\n1. Имя, фамилия, номер телефона и данные о махалле используются только для общения внутри махалли.\n2. Ваш номер телефона не виден другим жителям, пока вы не разрешите это в настройках.\n3. Время последней активности можно скрыть в настройках.\n4. Ваши данные не продаются и не передаются третьим лицам.\n5. При запросе удаления аккаунта ваши данные удаляются из базы Firestore.';

  @override
  String get deleteAccountRequested =>
      'Запрос отправлен. Администратор скоро удалит вашу учётную запись.';

  @override
  String get deleteAccountAlreadyPending =>
      'Ваш запрос на удаление уже рассматривается.';

  @override
  String get retryButton => 'Повторить';

  @override
  String get cameraIntroTitle => 'Нужен доступ к камере';

  @override
  String get cameraIntroBody =>
      'Чтобы присоединиться к махалле, нужно отсканировать QR-код, выданный председателем или сотрудником. Камера используется только для этого — снимки не сохраняются и не отправляются.';

  @override
  String get cameraIntroButton => 'Открыть камеру';

  @override
  String get cameraErrorPermission =>
      'Доступ к камере не разрешён. Включите его в настройках телефона (Приложения → Mening Mahallam → Разрешения → Камера). Или введите код махалли вручную.';

  @override
  String get cameraErrorUnsupported =>
      'На этом устройстве сканирование QR не поддерживается. Введите код махалли вручную.';

  @override
  String get cameraErrorGeneric =>
      'Не удалось открыть камеру. Возможно, её использует другое приложение — закройте его и попробуйте снова.';

  @override
  String get noAnnouncementsHint =>
      'Как только председатель или сотрудник махалли опубликует объявление, оно появится здесь.';

  @override
  String get noRequestsHint =>
      'Отправьте обращение по освещению, уборке, воде или другому вопросу — сотрудники махалли ответят.';

  @override
  String get noNeighborsHint =>
      'По мере того как жители махалли присоединяются к приложению, они появятся здесь. Пригласите соседей!';

  @override
  String get noPollsHint =>
      'Опросы махалли появятся здесь — голосуйте и участвуйте в принятии решений.';

  @override
  String get noServicesHint =>
      'Здесь собираются мастера, магазины и услуги вашей махалли.';

  @override
  String get noConversationsHint =>
      'Выберите человека в разделе «Соседи», чтобы написать ему напрямую.';

  @override
  String get noNotificationsHint =>
      'Мы сообщим здесь о новых объявлениях, событиях и ответах на ваши обращения.';

  @override
  String get currencySom => 'сум';

  @override
  String get premiumConfigTitle => 'Реквизиты оплаты';

  @override
  String get premiumConfigHint =>
      'Изменённые здесь значения сразу видны всем пользователям — обновлять приложение не нужно.';

  @override
  String get premiumConfigSaved => 'Реквизиты сохранены';

  @override
  String get premiumCardNumberLabel => 'Номер карты';

  @override
  String get premiumCardNumberInvalid =>
      'Номер карты должен состоять из 16 цифр';

  @override
  String get premiumCardHolderLabel => 'Имя владельца карты';

  @override
  String get premiumCardHolderInvalid => 'Введите имя владельца карты';

  @override
  String get premiumPriceLabel => 'Цена в месяц';

  @override
  String get premiumPriceInvalid => 'Введите корректную цену';

  @override
  String get premiumTelegramLabel => 'Имя пользователя в Telegram';

  @override
  String get premiumChoosePlan => 'Выберите срок';

  @override
  String premiumPlanMonths(int count) {
    return '$count мес.';
  }

  @override
  String premiumPriceValue(String amount) {
    return '$amount сум';
  }

  @override
  String get premiumBenefitAdDiscount =>
      'Размещение рекламы услуг на 50% дешевле';

  @override
  String get premiumBenefitSupport =>
      'Приоритетная поддержка — ваше обращение смотрят первым';

  @override
  String get premiumBenefitAvatar => 'Золотое премиум-кольцо на фото профиля';

  @override
  String get premiumBenefitEarlyAccess =>
      'Новые возможности открываются вам первым';

  @override
  String premiumPerMonthAmount(String amount) {
    return '$amount сум в месяц';
  }

  @override
  String get advertiseTitle => 'Разместите здесь рекламу своей услуги';

  @override
  String advertisePrice(String amount) {
    return 'Всего $amount сум в неделю';
  }

  @override
  String advertisePremiumDiscount(String amount) {
    return 'Ваша премиум-скидка — обычная цена $amount сум';
  }

  @override
  String get advertiseHowTo =>
      'Для размещения рекламы свяжитесь с председателем махалли или администратором приложения.';

  @override
  String get photoTooLarge =>
      'Файл слишком большой. Выберите изображение меньше 5 МБ';

  @override
  String get premiumBenefitAnimatedAvatar => 'Живое (GIF) фото профиля';

  @override
  String get premiumGrantTitle => 'Выдать премиум вручную';

  @override
  String get premiumGrantSelfAction => 'Выдать себе';

  @override
  String get premiumGrantPhoneLabel => 'Номер телефона';

  @override
  String get premiumGrantAction => 'Выдать на этот номер';

  @override
  String get premiumRevokeAction => 'Отозвать с этого номера';

  @override
  String get premiumRevokeConfirmTitle => 'Отменить премиум';

  @override
  String premiumRevokeConfirmMessage(String name) {
    return 'Досрочно отменить премиум-подписку для $name?';
  }

  @override
  String premiumRevokedFrom(String name) {
    return 'Премиум для $name отменён';
  }

  @override
  String premiumGrantedSelf(int months) {
    return 'Вам выдан премиум на $months мес.';
  }

  @override
  String premiumGrantedTo(String name, int months) {
    return '$name — выдан премиум на $months мес.';
  }

  @override
  String get premiumGrantUserNotFound =>
      'Пользователь с этим номером не найден';

  @override
  String premiumUntilShort(String date) {
    return 'до $date';
  }

  @override
  String get personalInfoSection => 'Личные данные';

  @override
  String get addressSection => 'Адрес';

  @override
  String get mahallaCenterTitle => 'Центр махалли';

  @override
  String get mahallaCenterHint =>
      'Нажмите на карту, чтобы отметить центр, или введите координаты через кнопку сверху.';

  @override
  String get mahallaCenterCoordsHint =>
      'Вставьте координаты, скопированные из Google Maps (широта, долгота).';

  @override
  String get mahallaCenterSaved => 'Центр махалли сохранён';

  @override
  String get boundaryModeLabel => 'Граница';

  @override
  String get centerModeLabel => 'Центр';

  @override
  String get saveCenterAction => 'Сохранить центр';

  @override
  String get appearanceSystemHint => 'Следовать настройке телефона';

  @override
  String get textSizePreviewTitle => 'Собрание махалли';

  @override
  String get textSizePreviewBody =>
      'Основной текст будет выглядеть так. Выберите удобный размер.';

  @override
  String get okButton => 'OK';

  @override
  String get reportAction => 'Пожаловаться';

  @override
  String get reportSheetTitle => 'Пожаловаться';

  @override
  String get reportReasonLabel => 'Причина';

  @override
  String get reportReasonSpam => 'Спам';

  @override
  String get reportReasonHaqoratOmuhandaslik => 'Оскорбление или угроза';

  @override
  String get reportReasonAldash => 'Мошенничество / обман';

  @override
  String get reportReasonNomunosib => 'Неприемлемый контент';

  @override
  String get reportReasonBoshqa => 'Другое';

  @override
  String get reportDetailsLabel => 'Дополнительный комментарий';

  @override
  String get reportDetailsHint => 'Опишите подробнее (необязательно)';

  @override
  String get reportSubmitAction => 'Отправить';

  @override
  String get reportSubmittedMessage => 'Ваша жалоба принята, мы её рассмотрим';

  @override
  String get reportErrorMessage => 'Ошибка при отправке жалобы';

  @override
  String get reportChooseReasonError => 'Пожалуйста, выберите причину';

  @override
  String serviceRatingCount(int count) {
    return '$count оценок';
  }

  @override
  String get serviceNoRatingsYet => 'Пока нет оценок';

  @override
  String get yourRatingLabel => 'Ваша оценка';

  @override
  String get assignStaffTitle => 'Назначить сотруднику';

  @override
  String get noStaffFoundLabel => 'В махалле не найдено сотрудников';

  @override
  String get cancelAssignmentAction => 'Отменить назначение';

  @override
  String get requestAssignedMessage => 'Обращение назначено';

  @override
  String get dueDateSetMessage => 'Срок установлен';

  @override
  String get assignAction => 'Назначить';

  @override
  String get setDueDateAction => 'Установить срок';

  @override
  String assignedToLabel(String fullName) {
    return 'Назначено: $fullName';
  }

  @override
  String dueDateLabel(String date) {
    return 'Срок: $date';
  }

  @override
  String get dueDateOverdueSuffix => ' — просрочено';

  @override
  String get commentsTitle => 'Комментарии';

  @override
  String get noCommentsYet => 'Пока нет комментариев';

  @override
  String get commentHint => 'Напишите комментарий...';

  @override
  String get similarRequestsTitle => 'Похожие обращения';

  @override
  String get createGroupAction => 'Создать группу';

  @override
  String get groupNameLabel => 'Название группы';

  @override
  String get groupNameHint => 'Например: Активисты улицы';

  @override
  String get selectMembersLabel => 'Выберите участников';

  @override
  String selectMembersLabelWithCount(int count) {
    return 'Выберите участников ($count)';
  }

  @override
  String get enterGroupNameError => 'Введите название группы';

  @override
  String get selectAtLeastOneMemberError => 'Выберите хотя бы одного участника';

  @override
  String get groupCreateError => 'Ошибка при создании группы';

  @override
  String get groupsSectionTitle => 'Группы';

  @override
  String get locationFieldLabel => 'Местоположение';

  @override
  String get locationSetLabel => 'Местоположение указано';

  @override
  String get setLocationLabel => 'Указать местоположение';

  @override
  String get locationDetectError =>
      'Не удалось определить местоположение. Проверьте разрешения или состояние GPS.';

  @override
  String get tapMapHint => 'Нажмите на карту, чтобы указать точку';

  @override
  String get assistantScreenTitle => 'Mahal';

  @override
  String get assistantSubtitleLabel => 'ИИ-помощник';

  @override
  String get assistantInputHint => 'Напишите ваш вопрос...';

  @override
  String get assistantGreetingTitle => 'Привет! Я Mahal';

  @override
  String get assistantGreetingSubtitle =>
      'Готов ответить на ваши вопросы о махалле и помочь с использованием приложения.';

  @override
  String get assistantSuggestion1 => 'Какие услуги есть в моей махалле?';

  @override
  String get assistantSuggestion2 => 'Как отправить обращение?';

  @override
  String get assistantSuggestion3 => 'Как пользоваться приложением?';

  @override
  String get assistantLimitUpsellTitle => 'Дневной лимит исчерпан';

  @override
  String get assistantLimitUpsellMessage =>
      'С Premium вы сможете отправлять гораздо больше сообщений каждый день.';

  @override
  String get assistantLimitUpsellButton => 'О Premium';

  @override
  String get assistantActionOpenFeedback => 'Оставить отзыв';

  @override
  String get assistantActionOpenServices => 'Посмотреть услуги';

  @override
  String get assistantActionOpenHelp => 'Получить помощь';

  @override
  String get assistantActionOpenPremium => 'О Premium';

  @override
  String get assistantNewChat => 'Новый чат';

  @override
  String get assistantDeleteChatTitle => 'Удалить чат';

  @override
  String assistantDeleteChatMessage(String title) {
    return 'Удалить чат «$title» без возможности восстановления?';
  }

  @override
  String get notificationPreferencesTitle => 'Настройки уведомлений';

  @override
  String get notificationPreferencesSubtitle =>
      'Выберите, какие уведомления получать';

  @override
  String get notificationPreferencesSectionHeader =>
      'Какие уведомления вы получаете';

  @override
  String get notificationTypeAnnouncementLabel => 'Новые объявления';

  @override
  String get notificationTypeEventLabel => 'Новые мероприятия';

  @override
  String get notificationTypePollLabel => 'Новые опросы';

  @override
  String get notificationTypeMessageLabel => 'Новые сообщения';

  @override
  String get notificationTypeRequestStatusLabel => 'Статус обращения';

  @override
  String get offlineBannerMessage => 'Офлайн — нет интернета';

  @override
  String get statusHistoryTitle => 'История статуса';

  @override
  String get remindMeAction => 'Напомнить';

  @override
  String get reminderSetMessage => 'Напоминание установлено';

  @override
  String get reminderCancelledMessage => 'Напоминание отменено';

  @override
  String get eventReminderNotificationTitle => 'Напоминание о мероприятии';

  @override
  String get editMessageAction => 'Редактировать';

  @override
  String get messageDeletedPlaceholder => 'Сообщение удалено';

  @override
  String get editedLabel => '(изменено)';

  @override
  String get recentSearchesTitle => 'Недавние запросы';

  @override
  String get clearRecentSearchesAction => 'Очистить';

  @override
  String get microphonePermissionDeniedMessage => 'Нет доступа к микрофону';

  @override
  String get serviceAvailableLabel => 'Доступен';

  @override
  String get serviceBusyLabel => 'Занят';

  @override
  String get markBusyToggleLabel => 'Я сейчас свободен';

  @override
  String get callAction => 'Позвонить';

  @override
  String lastSeenLabel(String time) {
    return 'Был(а) в сети: $time';
  }
}
