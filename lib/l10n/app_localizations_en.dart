// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'My Mahalla';

  @override
  String get splashTagline => 'Your mahalla in one app';

  @override
  String get onboardingAnnouncementsTitle => 'Stay informed on announcements';

  @override
  String get onboardingAnnouncementsDescription =>
      'All the news and announcements from your mahalla in one place';

  @override
  String get onboardingEventsTitle => 'Stay informed on events';

  @override
  String get onboardingEventsDescription =>
      'Take part in mahalla meetings and initiatives';

  @override
  String get onboardingRequestsTitle => 'Send a request';

  @override
  String get onboardingRequestsDescription =>
      'Report a problem and track its response in real time';

  @override
  String get onboardingNeighborsTitle => 'Connect with neighbors';

  @override
  String get onboardingNeighborsDescription =>
      'Chat with mahalla residents and make decisions together';

  @override
  String get previewAnnouncements => 'Announcements';

  @override
  String get previewEvents => 'Events';

  @override
  String get previewRequests => 'Requests';

  @override
  String get previewNeighbors => 'Neighbors';

  @override
  String get continueButton => 'Continue';

  @override
  String get skipButton => 'Skip';

  @override
  String get loginButton => 'Log in';

  @override
  String get registerButton => 'Sign up';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Enter your details';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPassword => 'Forgot your password?';

  @override
  String get orDivider => 'or';

  @override
  String get noAccountQuestion => 'Don\'t have an account? ';

  @override
  String get phoneValidationError => 'Enter the full phone number';

  @override
  String get passwordValidationError =>
      'Password must be at least 6 characters';

  @override
  String get unexpectedError => 'An unexpected error occurred';

  @override
  String get registerTitle => 'Sign up';

  @override
  String get registerSubtitle => 'Create a new account';

  @override
  String get firstNameLabel => 'First name';

  @override
  String get lastNameLabel => 'Last name';

  @override
  String get firstNameValidationError => 'Enter your first name';

  @override
  String get lastNameValidationError => 'Enter your last name';

  @override
  String get haveAccountQuestion => 'Already have an account? ';

  @override
  String get welcomeGreeting => 'Welcome';

  @override
  String helloUser(String name) {
    return 'Hello, $name!';
  }

  @override
  String get helloGeneric => 'Hello!';

  @override
  String get guestName => 'guest';

  @override
  String get searchHint => 'Search...';

  @override
  String get categoryAnnouncements => 'Announcements';

  @override
  String get categoryEvents => 'Events';

  @override
  String get categoryRequests => 'Requests';

  @override
  String get categoryNeighbors => 'Neighbors';

  @override
  String get upcomingEventsTitle => 'Upcoming events';

  @override
  String get noUpcomingEvents => 'No upcoming events yet';

  @override
  String get eventsLoadError => 'Error loading events';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get profileTitle => 'Profile';

  @override
  String get defaultUserName => 'User';

  @override
  String get profileLoadError => 'Error loading data';

  @override
  String get chooseBannerTitle => 'Choose a banner';

  @override
  String get premiumBannerLockedMessage =>
      'This banner is premium — currently locked';

  @override
  String get premiumTitle => 'Premium';

  @override
  String get premiumSettingSubtitle => 'Unlimited requests, no ads, and more';

  @override
  String get premiumHeroTitle => 'Premium subscription';

  @override
  String get premiumHeroSubtitle =>
      'Be more active in your mahalla — without limits';

  @override
  String get premiumPerMonth => 'sum/month';

  @override
  String get premiumBenefitsTitle => 'WHAT YOU UNLOCK';

  @override
  String get premiumBenefitUnlimited => 'Unlimited requests — no daily limit';

  @override
  String get premiumBenefitNoAds => 'No ads shown at all';

  @override
  String get premiumBenefitPriority =>
      'Your request appears higher in the list';

  @override
  String get premiumBenefitImages => 'Up to 10 photos per request';

  @override
  String get premiumBenefitBanners => 'Exclusive profile banners';

  @override
  String get premiumBenefitBadge => 'Premium badge on your profile';

  @override
  String get premiumBuyAction => 'Get Premium';

  @override
  String get premiumActiveTitle => 'Premium active';

  @override
  String premiumActiveUntil(String date, int days) {
    return 'Until $date — $days days left';
  }

  @override
  String get premiumTransferHint =>
      'Transfer to the card below. Tap it to copy.';

  @override
  String get premiumCardNumber => 'Card number';

  @override
  String get premiumCardHolder => 'Card holder';

  @override
  String get premiumAmount => 'Payment amount';

  @override
  String get premiumCardCopied => 'Card number copied';

  @override
  String get premiumHolderCopied => 'Card holder name copied';

  @override
  String get premiumAmountCopied => 'Amount copied';

  @override
  String premiumPaymentTimeLeft(String time) {
    return '$time left to pay';
  }

  @override
  String get premiumPaymentExpired => 'Payment time expired — start again';

  @override
  String get premiumIPaidAction => 'I\'ve paid';

  @override
  String get premiumContactAdmin => 'Admin on Telegram';

  @override
  String get premiumTelegramHint =>
      'For faster confirmation, send the receipt on Telegram — optional.';

  @override
  String get premiumWaitingTitle => 'Awaiting confirmation';

  @override
  String get premiumWaitingSubtitle =>
      'Premium unlocks once the admin verifies the payment';

  @override
  String get premiumRequestsTitle => 'Premium requests';

  @override
  String get premiumRequestsEmpty => 'No pending requests';

  @override
  String premiumRequestMonths(int count) {
    return '$count-month subscription';
  }

  @override
  String get premiumApproveAction => 'Approve';

  @override
  String get premiumRejectAction => 'Reject';

  @override
  String get adLabel => 'Ad';

  @override
  String get adManagementTitle => 'Service ads';

  @override
  String get adAddAction => 'Add ad';

  @override
  String get adEmptyTitle => 'No ads yet';

  @override
  String get adTitleLabel => 'Service name';

  @override
  String get adDescriptionLabel => 'Short description';

  @override
  String get adOwnerLabel => 'Provider / organization name';

  @override
  String get adTitleRequired => 'Enter the service name';

  @override
  String get adSaveAction => 'Save';

  @override
  String get adStatusActive => 'Active';

  @override
  String get adStatusExpired => 'Expired';

  @override
  String adActiveUntil(String date) {
    return 'Active until $date';
  }

  @override
  String get adExtendAction => 'Extend by 7 days';

  @override
  String get adPromoteTitle => 'Advertise your service';

  @override
  String adPromoteSubtitle(String price) {
    return '$price per week — seen by your whole mahalla';
  }

  @override
  String get adPromoteAction => 'Order an ad';

  @override
  String get noMahallaTitle => 'Join your mahalla first';

  @override
  String get noMahallaSubtitle =>
      'Scan the QR code given by your mahalla chairman — after that, announcements, requests, and neighbors will appear here.';

  @override
  String get noMahallaAction => 'Scan QR code';

  @override
  String get emptyAnnouncementsSubtitle =>
      'Announcements from the mahalla chairman or staff will appear here.';

  @override
  String get emptyRequestsSubtitle =>
      'If there\'s a problem in the mahalla, you can send the first request.';

  @override
  String get emptyRequestsAction => 'Send a request';

  @override
  String get emptyNeighborsSubtitle =>
      'Your neighbors will appear here once they join the app. Invite them!';

  @override
  String get emptyServicesSubtitle =>
      'Providers and services from your mahalla are gathered here.';

  @override
  String get emptyEventsSubtitle => 'Scheduled events will appear here.';

  @override
  String get premiumBadgeLabel => 'Premium';

  @override
  String get chooseBadgeStyleTitle => 'Choose a badge style';

  @override
  String get premiumBadgeStyleGold => 'Gold';

  @override
  String get premiumBadgeStyleSapphire => 'Sapphire';

  @override
  String get premiumBadgeStyleEmerald => 'Emerald';

  @override
  String get premiumBadgeStyleRuby => 'Ruby';

  @override
  String get premiumBadgeStyleSilver => 'Silver';

  @override
  String dailyRequestLimitReached(Object count) {
    return 'You\'ve reached the daily request limit ($count). Try again tomorrow or get Premium to send unlimited requests.';
  }

  @override
  String get myInfoMenuItem => 'My information';

  @override
  String get notificationsMenuItem => 'Notifications';

  @override
  String get settingsMenuItem => 'Settings';

  @override
  String get helpMenuItem => 'Help';

  @override
  String get logoutMenuItem => 'Log out';

  @override
  String get logoutConfirmTitle => 'Confirm log out';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionMahalla => 'Mahalla';

  @override
  String get currentMahalla => 'Current mahalla';

  @override
  String get notConnected => 'Not connected';

  @override
  String get unknownValue => 'Unknown';

  @override
  String get changeButton => 'Change';

  @override
  String get changeMahallaTitle => 'Change mahalla';

  @override
  String get changeMahallaMessage =>
      'You\'ll connect to a new mahalla by scanning a QR code or entering the code manually. Continue?';

  @override
  String get sectionGeneral => 'General';

  @override
  String get sectionManagement => 'Management';

  @override
  String get membersManagementTitle => 'Manage members';

  @override
  String get noMembersYet => 'No members yet';

  @override
  String get roleUpdated => 'Role updated';

  @override
  String get selectRoleTitle => 'Select a role';

  @override
  String get languageSettingTitle => 'Language';

  @override
  String get languageUpdatedMessage => 'Language updated';

  @override
  String get appearanceSettingTitle => 'Appearance';

  @override
  String get textSizeSettingTitle => 'Text size';

  @override
  String get sectionAbout => 'About the app';

  @override
  String get versionLabel => 'Version';

  @override
  String get statActiveRequests => 'Active requests';

  @override
  String get statNewAnnouncements => 'New announcements';

  @override
  String get statUpcomingEvents => 'Upcoming events';

  @override
  String get myRequestsStat => 'My requests';

  @override
  String get myAnnouncementsStat => 'My announcements';

  @override
  String get myJoinedStat => 'Joined';

  @override
  String get myRequestsTitle => 'My requests';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get mahallaStatsTitle => 'Mahalla statistics';

  @override
  String get statsTotalMembers => 'Members';

  @override
  String get statsActiveRequests => 'Active requests';

  @override
  String get statsNewAnnouncements => 'New announcements';

  @override
  String get statsUpcomingEvents => 'Upcoming events';

  @override
  String get noRecentActivity => 'No activity yet';

  @override
  String get activityLoadError => 'Error loading activity';

  @override
  String activityNewAnnouncement(String title) {
    return 'New announcement: $title';
  }

  @override
  String activityNewRequest(String title) {
    return 'New request: $title';
  }

  @override
  String activityNewEvent(String title) {
    return 'New event: $title';
  }

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String daysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get sectionAccount => 'Account';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePhoneTitle => 'Change phone number';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete account';

  @override
  String get deleteAccountConfirmMessage =>
      'This action cannot be undone. All your data will be permanently deleted. Continue?';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get sectionDataStorage => 'Data & storage';

  @override
  String get clearCacheTitle => 'Clear cache';

  @override
  String get clearCacheSubtitle => 'Removes temporarily stored files';

  @override
  String get cacheClearedMessage => 'Cache cleared';

  @override
  String get sectionSupport => 'Support';

  @override
  String get rateAppTitle => 'Rate the app';

  @override
  String get feedbackTitle => 'Leave feedback';

  @override
  String get feedbackSubtitle =>
      'Your feedback about the app matters to us — it goes straight to the mahalla leadership.';

  @override
  String get feedbackRatingRequiredError => 'Please give a star rating';

  @override
  String get feedbackMessageLabel => 'Your feedback (optional)';

  @override
  String get feedbackMessageHint =>
      'What did you like, what needs improvement?';

  @override
  String get feedbackSubmitButton => 'Submit';

  @override
  String get feedbackSubmittedMessage =>
      'Thank you! Your feedback has been submitted';

  @override
  String get feedbackModeRatingTab => 'Rate the app';

  @override
  String get feedbackModeQuestionTab => 'Question / Contact';

  @override
  String get feedbackQuestionTitle => 'Question or request';

  @override
  String get feedbackQuestionSubtitle =>
      'Write your question or request — the superadmin will review it and get back to you if needed.';

  @override
  String get feedbackQuestionMessageHint =>
      'Write your question or request here...';

  @override
  String get feedbackQuestionBadge => 'Question';

  @override
  String get feedbackListTitle => 'User feedback';

  @override
  String get noFeedbackFound => 'No feedback yet';

  @override
  String get unknownUserLabel => 'Unknown user';

  @override
  String get requestAuthorLabel => 'Sent by';

  @override
  String get quickNewRequestTitle => 'Send a new request';

  @override
  String get quickNewRequestSubtitle =>
      'Have a problem? Send it in a few seconds';

  @override
  String get mahalCardTitle => 'Chat with Mahal';

  @override
  String get mahalCardSubtitle =>
      'Get answers to your questions, file a request, or ask about the mahalla';

  @override
  String get openLinkAction => 'Open link';

  @override
  String get linkOpenFailedMessage => 'Couldn\'t open the link';

  @override
  String get bannerManagementTitle => 'Banners';

  @override
  String get addBannerTitle => 'Add a new banner';

  @override
  String get bannerTitleLabel => 'Title';

  @override
  String get bannerDescriptionLabel => 'Description (optional)';

  @override
  String get bannerLinkLabel => 'Link (optional, https://...)';

  @override
  String get bannerAttributionLabel => 'Author/source (optional)';

  @override
  String get bannerImageRequiredError => 'Please select an image';

  @override
  String get bannerTitleRequiredError => 'Please enter a title';

  @override
  String get noBannersFound => 'No banners yet';

  @override
  String get mahallaOnMapTitle => 'Your mahalla on the map';

  @override
  String get developerTitle => 'Developer';

  @override
  String get developerSubtitle => 'Mahallam team';

  @override
  String get termsTitle => 'Terms of use';

  @override
  String get privacyPolicyTitle => 'Privacy policy';

  @override
  String get comingSoonMessage => 'This feature is coming soon';

  @override
  String get profileSaved => 'Data saved';

  @override
  String get saveButton => 'Save';

  @override
  String get faqTitle => 'Frequently asked questions';

  @override
  String get contactUsTitle => 'Contact us';

  @override
  String get callUs => 'By phone';

  @override
  String get telegramUs => 'Via Telegram';

  @override
  String get faqQ1 => 'How do I join a mahalla?';

  @override
  String get faqA1 =>
      'After registering, you\'ll connect to your mahalla by scanning the QR code given to you by the chairman or a responsible staff member.';

  @override
  String get faqQ2 => 'How do I send a request?';

  @override
  String get faqA2 =>
      'Go to the \"Requests\" section and create a new request. Your request\'s status will show as \"New\", \"In progress\", or \"Completed\".';

  @override
  String get faqQ3 => 'How do I view announcements?';

  @override
  String get faqA3 =>
      'The \"Announcements\" section on the home screen shows all official announcements for your mahalla, organized by category.';

  @override
  String get faqQ4 => 'I forgot my password, what do I do?';

  @override
  String get faqA4 =>
      'Tap \"Forgot your password?\" on the login screen. A reset link will be sent to your email. If it doesn\'t arrive, check your Spam folder.';

  @override
  String get faqQ5 => 'Is my data safe?';

  @override
  String get faqA5 =>
      'Yes, all data is visible only within your mahalla and is stored on a secure server.';

  @override
  String get callFailedMessage => 'Couldn\'t make the call';

  @override
  String get telegramFailedMessage => 'Couldn\'t open Telegram';

  @override
  String get announcementsTitle => 'Announcements';

  @override
  String get eventsTitle => 'Events';

  @override
  String get feedTitle => 'Feed';

  @override
  String get postsFilterLabel => 'Posts';

  @override
  String get noPostsYet => 'No posts yet';

  @override
  String get noPostsHint =>
      'When a neighbor makes the first post, it will appear here.';

  @override
  String get writePostHint => 'What\'s on your mind?';

  @override
  String get postCreatedMessage => 'Post published';

  @override
  String get writePostOrImageError => 'Write some text or add a photo';

  @override
  String get postUpdatedMessage => 'Post updated';

  @override
  String get editPostTitle => 'Edit post';

  @override
  String get postingTooFastError =>
      'You\'re posting too fast. Please wait a moment and try again.';

  @override
  String get inappropriateContentError =>
      'The text contains inappropriate words. Please edit it.';

  @override
  String get reactionsSheetTitle => 'Reactions';

  @override
  String get repostAction => 'Repost';

  @override
  String repostedByLabel(String name) {
    return '$name reposted';
  }

  @override
  String get repostSuccessMessage => 'Reposted';

  @override
  String get repostRemovedMessage => 'Repost removed';

  @override
  String get addStoryLabel => 'Add story';

  @override
  String get yourStoryLabel => 'Your story';

  @override
  String get newButton => 'New';

  @override
  String get noAnnouncementsYet => 'No announcements yet';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get announcementsLoadError => 'Error loading announcements';

  @override
  String participantsCount(int count) {
    return '$count participants';
  }

  @override
  String todayAt(String time) {
    return 'Today, $time';
  }

  @override
  String get categoryKommunal => 'Utilities';

  @override
  String get categoryXavfsizlik => 'Safety';

  @override
  String get categoryUmumiy => 'General';

  @override
  String get newAnnouncementTitle => 'New announcement';

  @override
  String get editAnnouncementTitle => 'Edit announcement';

  @override
  String get pollsTitle => 'Polls';

  @override
  String get newPollTitle => 'New poll';

  @override
  String get pollQuestionHint => 'Write your question...';

  @override
  String pollOptionHint(int number) {
    return 'Option $number';
  }

  @override
  String get addOptionButton => 'Add option';

  @override
  String get fillPollFields => 'Enter a question and at least 2 options';

  @override
  String get pollPostedMessage => 'Poll posted';

  @override
  String get noPollsYet => 'No polls yet';

  @override
  String pollVotesCount(int count) {
    return '$count votes';
  }

  @override
  String get conversationsTitle => 'Messages';

  @override
  String get conversationsMenuItem => 'Messages';

  @override
  String get noConversationsYet => 'No conversations yet';

  @override
  String get noMessagesYet => 'No messages yet. Be the first to write!';

  @override
  String get messageHint => 'Write a message...';

  @override
  String get sendMessageAction => 'Write a message';

  @override
  String get typingIndicator => 'typing...';

  @override
  String get attachImageAction => 'Attach image';

  @override
  String get imageUploadFailed => 'Image could not be sent. Please try again';

  @override
  String get yesterdayLabel => 'Yesterday';

  @override
  String get switchMahallaTitle => 'Choose mahalla';

  @override
  String get switchMahallaMenuItem => 'Switch mahalla (Super Admin)';

  @override
  String get switchMahallaMenuItemActive => 'You\'re managing another mahalla';

  @override
  String get exitMahallaModeAction => 'Return to my mahalla';

  @override
  String get noMahallasFound => 'No mahallas found';

  @override
  String get broadcastToAllMahallasLabel =>
      'Send to all mahallas (Super Admin)';

  @override
  String get servicesTitle => 'Local services';

  @override
  String get newServiceTitle => 'Add service';

  @override
  String get editServiceTitle => 'Edit service';

  @override
  String get serviceCategoryLabel => 'Category';

  @override
  String get serviceNameLabel => 'Name or organization name';

  @override
  String get serviceNameHint => 'e.g. Aziz aka (plumber)';

  @override
  String get servicePhoneLabel => 'Phone number';

  @override
  String get serviceDescriptionLabel => 'Description';

  @override
  String get serviceDescriptionHint => 'Working hours, price, etc...';

  @override
  String get fillServiceFields => 'Enter a name and phone number';

  @override
  String get servicePostedMessage => 'Service added';

  @override
  String get serviceUpdatedMessage => 'Service updated';

  @override
  String get noServicesYet => 'No services yet';

  @override
  String get serviceCategorySantexnik => 'Plumber';

  @override
  String get serviceCategoryElektrik => 'Electrician';

  @override
  String get serviceCategoryDuradgor => 'Carpenter';

  @override
  String get serviceCategoryTozalash => 'Cleaning';

  @override
  String get serviceCategoryQurilish => 'Construction';

  @override
  String get serviceCategoryBoshqa => 'Other';

  @override
  String get editPollTitle => 'Edit poll';

  @override
  String get pollUpdatedMessage => 'Poll updated';

  @override
  String get changeVoteConfirmTitle => 'Change vote';

  @override
  String get changeVoteConfirmMessage =>
      'You\'ve already voted for a different option. Do you want to change your vote?';

  @override
  String get changeVoteConfirmButton => 'Yes, change it';

  @override
  String get pollAllowMultipleLabel => 'Allow selecting multiple options';

  @override
  String get pollAnonymousLabel => 'Anonymous poll';

  @override
  String get pollClosesAtLabel => 'Closing date (optional)';

  @override
  String get pollClosesAtClearButton => 'Clear';

  @override
  String get pollClosedBadge => 'Closed';

  @override
  String get pollVoteClosedError =>
      'This poll is closed, voting is unavailable';

  @override
  String get pollSubmitVoteButton => 'Vote';

  @override
  String get categoryServices => 'Services';

  @override
  String get categoryPolls => 'Polls';

  @override
  String get categoryLabel => 'Category';

  @override
  String get titleLabel => 'Title';

  @override
  String get titleHint => 'e.g. About tomorrow\'s water outage';

  @override
  String get bodyLabel => 'Text';

  @override
  String get bodyHint => 'Describe the announcement in detail...';

  @override
  String get photoLabel => 'Photo';

  @override
  String get optionalLabel => '(optional)';

  @override
  String get postButton => 'Post';

  @override
  String get fillTitleAndBody => 'Fill in the title and text';

  @override
  String get announcementPosted => 'Announcement posted successfully';

  @override
  String get announcementUpdated => 'Announcement updated';

  @override
  String get requestsTitle => 'Requests';

  @override
  String get mustVerifyMahallaFirst => 'Please verify your mahalla first';

  @override
  String get managementPanelBanner => 'Management panel — all requests';

  @override
  String get requestsLoadError => 'Error loading requests';

  @override
  String joinedCount(int count) {
    return '$count joined';
  }

  @override
  String noRequestsWithStatus(String status) {
    return 'No requests: $status';
  }

  @override
  String get filterAll => 'All';

  @override
  String get noRequestsAtAll => 'No requests yet';

  @override
  String get statusYangi => 'New';

  @override
  String get statusJarayonda => 'In progress';

  @override
  String get statusYakunlandi => 'Completed';

  @override
  String get typeMaxfiy => 'Confidential';

  @override
  String get typeOmmaviy => 'Public';

  @override
  String get priorityPast => 'Low';

  @override
  String get priorityOrtacha => 'Medium';

  @override
  String get priorityYuqori => 'High';

  @override
  String get managementPanelTitle => 'Management panel';

  @override
  String get changeStatusTitle => 'Change status';

  @override
  String statusChangedMessage(String status) {
    return 'Status changed to \"$status\"';
  }

  @override
  String get statusChangeError => 'Error changing status';

  @override
  String get allFilter => 'All';

  @override
  String get noRequestsFound => 'No requests found';

  @override
  String get tapToChangeStatus => 'Tap to change status';

  @override
  String get stepType => 'Type';

  @override
  String get stepDetails => 'Details';

  @override
  String get stepLocation => 'Location';

  @override
  String get stepReview => 'Review';

  @override
  String get stepDone => 'Done';

  @override
  String get newRequestTitle => 'New request';

  @override
  String get fillTitleAndDescription => 'Fill in the title and description';

  @override
  String get sendButton => 'Send';

  @override
  String get chooseRequestType => 'Choose the request type';

  @override
  String get requestTypeExplain => 'This determines who can see your request';

  @override
  String get typeMaxfiyDescription =>
      'Only you and the mahalla chairman can see it';

  @override
  String get typeOmmaviyDescription =>
      'Everyone in the mahalla can see it and can join';

  @override
  String get titleFieldLabel => 'Title';

  @override
  String get titleFieldHint => 'e.g. Street lighting isn\'t working';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Describe the problem in detail...';

  @override
  String get attachPhotoLabel => 'Attach photo';

  @override
  String get priorityLevelLabel => 'Priority level';

  @override
  String get reviewDataTitle => 'Review the details';

  @override
  String get reviewType => 'Type';

  @override
  String get reviewPriority => 'Priority';

  @override
  String get reviewLocation => 'Location';

  @override
  String get reviewLocationSet => 'Set';

  @override
  String get reviewLocationNotSet => 'Not set';

  @override
  String reviewPhotos(int count) {
    return 'Photos ($count)';
  }

  @override
  String get requestSentTitle => 'Request sent!';

  @override
  String get requestSentMessage =>
      'Your request has been received and is being reviewed';

  @override
  String get backToListButton => 'Back to list';

  @override
  String get qrScanInstruction =>
      'Position the QR code at the mahalla entrance within the frame';

  @override
  String get checkingStatus => 'Checking...';

  @override
  String get scanningStatus => 'Scanning...';

  @override
  String get enterCodeManually => 'Enter code manually';

  @override
  String get enterMahallaCodeTitle => 'Enter mahalla code';

  @override
  String get mahallaCodeHint => 'e.g. MFY-00123';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get qrGenericError => 'An error occurred, please try again';

  @override
  String get confirmError => 'Error confirming, please try again';

  @override
  String get mahallaFoundLabel => 'Mahalla found';

  @override
  String get rescanButton => 'Scan again';

  @override
  String get changePhotoLabel => 'Change photo';

  @override
  String get birthDateLabel => 'Date of birth';

  @override
  String get addressLabel => 'Address';

  @override
  String get streetLabel => 'Street';

  @override
  String get streetHint => 'e.g. Bogbon Street';

  @override
  String get houseNumberLabel => 'House number';

  @override
  String get houseNumberHint => 'e.g. 15';

  @override
  String get genderLabel => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get notSpecified => 'Not specified';

  @override
  String get selectDate => 'Select date';

  @override
  String get photoUploadError => 'Error uploading photo';

  @override
  String get otpTitle => 'Verification code';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get otpInvalidCode => 'Incorrect code, please try again';

  @override
  String get otpResendCode => 'Resend code';

  @override
  String otpResendCooldown(int seconds) {
    return 'Resend (${seconds}s)';
  }

  @override
  String get forgotPasswordTitle => 'Password recovery';

  @override
  String get forgotPasswordSubtitle =>
      'Enter the phone number you registered with, and we\'ll send you a verification code';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get newPasswordTitle => 'Set a new password';

  @override
  String get newPasswordSubtitle =>
      'Come up with a new password for your account';

  @override
  String get savePasswordButton => 'Save password';

  @override
  String get passwordResetSuccess =>
      'Your password has been updated successfully';

  @override
  String get newEventTitle => 'New event';

  @override
  String get editEventTitle => 'Edit event';

  @override
  String get eventTitleHint => 'e.g. Mahalla meeting';

  @override
  String get eventDescriptionHint =>
      'Additional details about the event (optional)...';

  @override
  String get dateLabel => 'Date';

  @override
  String get selectTime => 'Select time';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationHint => 'Where the event will take place';

  @override
  String get fillEventFields => 'Enter the title and date';

  @override
  String get eventPosted => 'Event posted';

  @override
  String get eventUpdated => 'Event updated';

  @override
  String get neighborsTitle => 'Neighbors';

  @override
  String get mahalladoshlar => 'Mahalla residents';

  @override
  String get yozishmalarTitle => 'Chats';

  @override
  String get noNeighborsYet => 'No neighbors yet';

  @override
  String get onlineNow => 'Online';

  @override
  String get lastSeenUnknown => 'Last activity unknown';

  @override
  String get lastSeenJustNow => 'Active just now';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String lastSeenHoursAgo(int hours) {
    return '$hours h ago';
  }

  @override
  String lastSeenDaysAgo(int days) {
    return '$days d ago';
  }

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get showPhoneToNeighborsTitle => 'Show phone to neighbors';

  @override
  String get showPhoneToNeighborsSubtitle =>
      'If enabled, your number will be visible in the Neighbors list';

  @override
  String get privacySecurityTitle => 'Privacy and security';

  @override
  String get privacySecuritySubtitle => 'Visibility, blocked users, password';

  @override
  String get sectionVisibility => 'Visibility';

  @override
  String get showLastSeenTitle => 'Show last activity';

  @override
  String get showLastSeenSubtitle =>
      'If enabled, neighbors will see your online status';

  @override
  String get sectionBlockedUsers => 'Blocked users';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String blockedUsersCount(int count) {
    return '$count blocked';
  }

  @override
  String get blockUserAction => 'Block';

  @override
  String get blockUserConfirmTitle => 'Block user';

  @override
  String blockUserConfirmMessage(String name) {
    return '$name won\'t be able to message you and won\'t appear in your list. Continue?';
  }

  @override
  String userBlockedMessage(String name) {
    return '$name has been blocked';
  }

  @override
  String get unblockAction => 'Unblock';

  @override
  String userUnblockedMessage(String name) {
    return '$name has been unblocked';
  }

  @override
  String get phoneHiddenByUser => 'This user has hidden their phone number';

  @override
  String get markAllAsReadAction => 'Mark all as read';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get searchPromptText =>
      'Search for an announcement, event, or request';

  @override
  String get searchNoResults => 'Nothing found';

  @override
  String get requestDetailTitle => 'Request details';

  @override
  String get requestNotFound => 'Request not found';

  @override
  String get announcementDetailTitle => 'Announcement details';

  @override
  String get announcementNotFound => 'Announcement not found';

  @override
  String get eventDetailTitle => 'Event details';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get shareAction => 'Share';

  @override
  String get joinRequestAction => 'Join';

  @override
  String get leaveRequestAction => 'Leave';

  @override
  String get mahallaStaffTitle => 'Mahalla staff';

  @override
  String get mahallaMapTitle => 'Mahalla map';

  @override
  String get locationStepTitle => 'Set the location';

  @override
  String get locationStepSubtitle =>
      'Tap the map to place a pin, or use your current location (optional)';

  @override
  String get locationPermissionError => 'Location access not granted';

  @override
  String get clearLocationAction => 'Clear';

  @override
  String get boundaryEditorTitle => 'Mark the boundary';

  @override
  String get boundaryEditorHint =>
      'Tap the map to place points along the mahalla boundary (at least 3)';

  @override
  String get boundaryMinPointsError => 'Mark at least 3 points';

  @override
  String get boundarySavedMessage => 'Boundary saved';

  @override
  String get saveBoundaryAction => 'Save boundary';

  @override
  String get editBoundaryAction => 'Edit boundary';

  @override
  String get mapLayerSatellite => 'Satellite view';

  @override
  String get mapLayerStreets => 'Street map';

  @override
  String get deleteItemConfirmTitle => 'Delete';

  @override
  String deleteItemConfirmMessage(String title) {
    return '\"$title\" will be permanently deleted. This action cannot be undone.';
  }

  @override
  String get itemDeletedMessage => 'Deleted';

  @override
  String get searchNeighborHint => 'Search by name...';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordMismatchError => 'Passwords don\'t match';

  @override
  String get newPhoneLabel => 'New phone number';

  @override
  String get phoneChangedMessage => 'Phone number changed successfully';

  @override
  String get termsBody =>
      'By using this app, you agree to the following terms:\n\n1. The app is intended to facilitate communication between mahalla residents and staff.\n2. Users must provide accurate and truthful information in their profile.\n3. Posting abusive, unlawful, or false information about other users is prohibited.\n4. Announcements and events posted by the mahalla administration (staff/chairman) may be official in nature.\n5. The app administration reserves the right to block or delete accounts found in violation of the rules.';

  @override
  String get privacyPolicyBody =>
      'How your data is used:\n\n1. Your first name, last name, phone number, and mahalla data are used only for communication within the mahalla.\n2. Your phone number is not visible to other residents until you allow it in settings.\n3. Your last-seen time can be hidden in settings.\n4. Your data is not sold or transferred to third parties.\n5. If you request account deletion, your data is removed from the Firestore database.';

  @override
  String get deleteAccountRequested =>
      'Your request has been sent. An administrator will delete your account soon.';

  @override
  String get deleteAccountAlreadyPending =>
      'Your deletion request is already being reviewed.';

  @override
  String get retryButton => 'Retry';

  @override
  String get cameraIntroTitle => 'Camera access needed';

  @override
  String get cameraIntroBody =>
      'To join your mahalla, you need to scan the QR code given by the chairman or a staff member. The camera is used only for this — no images are saved or sent.';

  @override
  String get cameraIntroButton => 'Open camera';

  @override
  String get cameraErrorPermission =>
      'Camera access not granted. You can enable it in your phone settings (Apps → Mening Mahallam → Permissions → Camera). Or enter the mahalla code manually.';

  @override
  String get cameraErrorUnsupported =>
      'QR scanning isn\'t supported on this device. Enter the mahalla code manually.';

  @override
  String get cameraErrorGeneric =>
      'Couldn\'t open the camera. Another app may be using it — close it and try again.';

  @override
  String get noAnnouncementsHint =>
      'As soon as the mahalla chairman or staff post an announcement, it will appear here first.';

  @override
  String get noRequestsHint =>
      'Send a request about lighting, cleaning, water, or another issue — mahalla staff will respond.';

  @override
  String get noNeighborsHint =>
      'As mahalla residents join the app, they\'ll appear here. Invite your neighbors!';

  @override
  String get noPollsHint =>
      'Mahalla polls will appear here — vote and take part in decision-making.';

  @override
  String get noServicesHint =>
      'Providers, shops, and services from your mahalla are gathered here.';

  @override
  String get noConversationsHint =>
      'Choose someone in the Neighbors section to message them directly.';

  @override
  String get noNotificationsHint =>
      'We\'ll notify you here about new announcements, events, or replies to your requests.';

  @override
  String get currencySom => 'sum';

  @override
  String get premiumConfigTitle => 'Payment details';

  @override
  String get premiumConfigHint =>
      'Values changed here are visible to all users immediately — no app update needed.';

  @override
  String get premiumConfigSaved => 'Details saved';

  @override
  String get premiumCardNumberLabel => 'Card number';

  @override
  String get premiumCardNumberInvalid => 'Card number must be 16 digits';

  @override
  String get premiumCardHolderLabel => 'Card holder name';

  @override
  String get premiumCardHolderInvalid => 'Enter the card holder\'s name';

  @override
  String get premiumPriceLabel => 'Monthly price';

  @override
  String get premiumPriceInvalid => 'Enter a valid price';

  @override
  String get premiumTelegramLabel => 'Telegram username';

  @override
  String get premiumChoosePlan => 'Choose a duration';

  @override
  String premiumPlanMonths(int count) {
    return '$count mo.';
  }

  @override
  String premiumPriceValue(String amount) {
    return '$amount sum';
  }

  @override
  String get premiumBenefitAdDiscount => '50% off placing service ads';

  @override
  String get premiumBenefitSupport =>
      'Priority support — your request gets seen first';

  @override
  String get premiumBenefitAvatar => 'Gold premium ring on your profile photo';

  @override
  String get premiumBenefitEarlyAccess => 'New features unlock for you first';

  @override
  String premiumPerMonthAmount(String amount) {
    return '$amount sum/month';
  }

  @override
  String get advertiseTitle => 'Advertise your service here';

  @override
  String advertisePrice(String amount) {
    return 'Only $amount sum a week';
  }

  @override
  String advertisePremiumDiscount(String amount) {
    return 'Your premium discount — regular price $amount sum';
  }

  @override
  String get advertiseHowTo =>
      'To place an ad, contact the mahalla chairman or app administrator.';

  @override
  String get photoTooLarge => 'File is too large. Choose an image under 5 MB';

  @override
  String get premiumBenefitAnimatedAvatar => 'Animated (GIF) profile photo';

  @override
  String get premiumGrantTitle => 'Grant premium manually';

  @override
  String get premiumGrantSelfAction => 'Grant to myself';

  @override
  String get premiumGrantPhoneLabel => 'Phone number';

  @override
  String get premiumGrantAction => 'Grant to this number';

  @override
  String get premiumRevokeAction => 'Revoke from this number';

  @override
  String get premiumRevokeConfirmTitle => 'Revoke premium';

  @override
  String premiumRevokeConfirmMessage(String name) {
    return 'Revoke $name\'s premium subscription early?';
  }

  @override
  String premiumRevokedFrom(String name) {
    return 'Premium revoked for $name';
  }

  @override
  String premiumGrantedSelf(int months) {
    return 'You\'ve been granted $months months of premium';
  }

  @override
  String premiumGrantedTo(String name, int months) {
    return '$name — granted $months months of premium';
  }

  @override
  String get premiumGrantUserNotFound => 'No user found with this number';

  @override
  String premiumUntilShort(String date) {
    return 'until $date';
  }

  @override
  String get personalInfoSection => 'Personal information';

  @override
  String get addressSection => 'Address';

  @override
  String get mahallaCenterTitle => 'Mahalla center';

  @override
  String get mahallaCenterHint =>
      'Tap the map to mark the center, or enter coordinates via the button above.';

  @override
  String get mahallaCenterCoordsHint =>
      'Paste coordinates copied from Google Maps (latitude, longitude).';

  @override
  String get mahallaCenterSaved => 'Mahalla center saved';

  @override
  String get boundaryModeLabel => 'Boundary';

  @override
  String get centerModeLabel => 'Center';

  @override
  String get saveCenterAction => 'Save center';

  @override
  String get appearanceSystemHint => 'Follows your phone\'s setting';

  @override
  String get textSizePreviewTitle => 'Mahalla meeting';

  @override
  String get textSizePreviewBody =>
      'This is what the main text will look like. Choose the size that\'s comfortable for you.';

  @override
  String get okButton => 'OK';

  @override
  String get reportAction => 'Report';

  @override
  String get reportSheetTitle => 'Report';

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHaqoratOmuhandaslik => 'Abuse or threats';

  @override
  String get reportReasonAldash => 'Fraud / scam';

  @override
  String get reportReasonNomunosib => 'Inappropriate content';

  @override
  String get reportReasonBoshqa => 'Other';

  @override
  String get reportDetailsLabel => 'Additional comment';

  @override
  String get reportDetailsHint => 'Write more details (optional)';

  @override
  String get reportSubmitAction => 'Submit';

  @override
  String get reportSubmittedMessage =>
      'Your report has been received, we\'ll review it';

  @override
  String get reportErrorMessage => 'Error submitting the report';

  @override
  String get reportChooseReasonError => 'Please choose a reason';

  @override
  String serviceRatingCount(int count) {
    return '$count ratings';
  }

  @override
  String get serviceNoRatingsYet => 'No ratings yet';

  @override
  String get yourRatingLabel => 'Your rating';

  @override
  String get assignStaffTitle => 'Assign to staff';

  @override
  String get noStaffFoundLabel => 'No staff found in the mahalla';

  @override
  String get cancelAssignmentAction => 'Cancel assignment';

  @override
  String get requestAssignedMessage => 'Request assigned';

  @override
  String get dueDateSetMessage => 'Due date set';

  @override
  String get assignAction => 'Assign';

  @override
  String get setDueDateAction => 'Set due date';

  @override
  String assignedToLabel(String fullName) {
    return 'Assigned to: $fullName';
  }

  @override
  String dueDateLabel(String date) {
    return 'Due: $date';
  }

  @override
  String get dueDateOverdueSuffix => ' — overdue';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet';

  @override
  String get commentHint => 'Write a comment...';

  @override
  String get similarRequestsTitle => 'Similar requests';

  @override
  String get createGroupAction => 'Create group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNameHint => 'e.g. Street activists';

  @override
  String get selectMembersLabel => 'Select members';

  @override
  String selectMembersLabelWithCount(int count) {
    return 'Select members ($count)';
  }

  @override
  String get enterGroupNameError => 'Enter a group name';

  @override
  String get selectAtLeastOneMemberError => 'Select at least one member';

  @override
  String get groupCreateError => 'Error creating group';

  @override
  String get groupsSectionTitle => 'Groups';

  @override
  String get locationFieldLabel => 'Location';

  @override
  String get locationSetLabel => 'Location set';

  @override
  String get setLocationLabel => 'Set location';

  @override
  String get locationDetectError =>
      'Could not detect location. Check permissions or GPS status.';

  @override
  String get tapMapHint => 'Tap the map to set a point';

  @override
  String get assistantScreenTitle => 'Mahal';

  @override
  String get assistantSubtitleLabel => 'AI assistant';

  @override
  String get assistantInputHint => 'Type your question...';

  @override
  String get assistantGreetingTitle => 'Hi! I\'m Mahal';

  @override
  String get assistantGreetingSubtitle =>
      'Ready to answer your questions about the mahalla and help you use the app.';

  @override
  String get assistantSuggestion1 =>
      'What services are available in my mahalla?';

  @override
  String get assistantSuggestion2 => 'How do I submit a request?';

  @override
  String get assistantSuggestion3 => 'How do I use the app?';

  @override
  String get assistantLimitUpsellTitle => 'Daily limit reached';

  @override
  String get assistantLimitUpsellMessage =>
      'With Premium you can send far more messages every day.';

  @override
  String get assistantLimitUpsellButton => 'About Premium';

  @override
  String get assistantActionOpenFeedback => 'Leave feedback';

  @override
  String get assistantActionOpenServices => 'View services';

  @override
  String get assistantActionOpenHelp => 'Get help';

  @override
  String get assistantActionOpenPremium => 'About Premium';

  @override
  String get assistantNewChat => 'New chat';

  @override
  String get assistantDeleteChatTitle => 'Delete chat';

  @override
  String assistantDeleteChatMessage(String title) {
    return 'Delete the chat \"$title\" permanently?';
  }

  @override
  String get notificationPreferencesTitle => 'Notification preferences';

  @override
  String get notificationPreferencesSubtitle =>
      'Choose which types of messages you receive';

  @override
  String get notificationPreferencesSectionHeader =>
      'Which messages you receive';

  @override
  String get notificationTypeAnnouncementLabel => 'New announcements';

  @override
  String get notificationTypeEventLabel => 'New events';

  @override
  String get notificationTypePollLabel => 'New polls';

  @override
  String get notificationTypeMessageLabel => 'New messages';

  @override
  String get notificationTypeRequestStatusLabel => 'Request status';

  @override
  String get offlineBannerMessage => 'Offline — no internet';

  @override
  String get statusHistoryTitle => 'Status history';

  @override
  String get remindMeAction => 'Remind me';

  @override
  String get reminderSetMessage => 'Reminder set';

  @override
  String get reminderCancelledMessage => 'Reminder cancelled';

  @override
  String get eventReminderNotificationTitle => 'Event reminder';

  @override
  String get editMessageAction => 'Edit';

  @override
  String get messageDeletedPlaceholder => 'Message deleted';

  @override
  String get editedLabel => '(edited)';

  @override
  String get recentSearchesTitle => 'Recent searches';

  @override
  String get clearRecentSearchesAction => 'Clear';

  @override
  String get microphonePermissionDeniedMessage =>
      'Microphone permission denied';

  @override
  String get serviceAvailableLabel => 'Available';

  @override
  String get serviceBusyLabel => 'Busy';

  @override
  String get markBusyToggleLabel => 'I\'m available now';

  @override
  String get callAction => 'Call';

  @override
  String lastSeenLabel(String time) {
    return 'Last seen: $time';
  }
}
